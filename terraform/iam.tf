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

# Allows ECS task to pull images, write logs, etc.
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
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        # Limit access strictly to the one secret created by Terraform
        Resource = [
          aws_secretsmanager_secret.api_secret.arn
        ]
      }
    ]
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

  # GitHub OIDC provider thumbprint
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
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

    # Limit GitHub repos that can assume this role
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:*/*" # You can replace with your actual repo: "repo:Nachiket/project:*"
      ]
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

      #################################################
      # ECR Permissions (build & push Docker images)
      #################################################
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

      #################################################
      # ECS Permissions (deploy updates)
      #################################################
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
