resource "aws_secretsmanager_secret" "api_secret" {
  name = "${var.project}-api-pysecret"
}

resource "aws_secretsmanager_secret_version" "api_secret_value" {
  secret_id = aws_secretsmanager_secret.api_secret.id
  secret_string = jsonencode({
    api_key = "super-secret-value"
  })
}
