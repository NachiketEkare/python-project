############################################
# ECS TASK EXECUTION ROLE
############################################

resource "aws_iam_role" "task_execution_role" {
  name = "${var.project}-ecs-execution-role"

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
# ECS TASK ROLE (Application permissions)
############################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-ecs-task-role"

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

############################################
# OPTIONAL: Allow ECS Task to Read Secrets
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
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

############################################
# GITHUB OIDC PROVIDER
############################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list   = ["sts.amazonaws.com"]
  thumbprint_list  = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

############################################
# GITHUB TRUST POLICY (OIDC)
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
# GITHUB DEPLOY ROLE
############################################

resource "aws_iam_role" "github_deploy_role" {
  name               = "${var.project}-github-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

############################################
# GITHUB DEPLOY POLICY
############################################

resource "aws_iam_policy" "github_deploy_policy" {
  name = "${var.project}-github-deploy-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # ECR Permissions
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

      # ECS Permissions
      {
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Resource = "*"
      },

      # CRITICAL → Allow CI/CD to pass BOTH roles
      {
        Effect = "Allow",
        Action = ["iam:PassRole"],
        Resource = [
          aws_iam_role.task_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
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

output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}
