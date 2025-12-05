resource "aws_ecr_repository" "predict_api" {
  name = "health-api"

  image_scanning_configuration {
    scan_on_push = true
  }
}
