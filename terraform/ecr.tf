resource "aws_ecr_repository" "predict_api" {
  name = "healthy-api"

  image_scanning_configuration {
    scan_on_push = true
  }
}
