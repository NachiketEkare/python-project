############################################
# ECS TASK EXECUTION ROLE
############################################

resource "aws_iam_role" "task_execution_role" {
  name = "${var.project}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################################
# ALLOW ECS TASK TO READ SECRETS
############################################

resource "aws_iam_policy" "secrets_policy" {
  name = "${var.project}-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "secretsmanager:GetSecretValue",
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      Resource = [
        aws_secretsmanager_secret.api_secret.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secret_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

############################################
# GITHUB OIDC PROVIDER (NEEDED FOR CI/CD)
############################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

############################################
# GITHUB ASSUME ROLE POLICY (OIDC TRUST)
############################################

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:*/*"]
    }
  }
}

############################################
# GITHUB DEPLOY ROLE (ASSUMED BY CI/CD)
############################################

resource "aws_iam_role" "github_deploy_role" {
  name               = "GitHubDeployRole"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

############################################
# MINIMUM PERMISSIONS FOR ECS DEPLOY VIA CI/CD
############################################

resource "aws_iam_policy" "github_deploy_policy" {
  name = "GitHubDeployPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # ECR 
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*"
      },

      # ECS
      {
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeClusters",
          "ecs:ListTaskDefinitions"
        ],
        Resource = "*"
      },

      # REQUIRED - PassRole for ECS Task Execution
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          aws_iam_role.task_execution_role.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_deploy_attach" {
  role       = aws_iam_role.github_deploy_role.name
  policy_arn = aws_iam_policy.github_deploy_policy.arn
}

############################################
# OUTPUTS
############################################

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy_role.arn
}

output "task_execution_role_arn" {
  value = aws_iam_role.task_execution_role.arn
}
