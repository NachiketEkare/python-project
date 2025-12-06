resource "aws_ecr_repository" "predict_api" {
  name = "predict-api-healthy"

  image_scanning_configuration {
    scan_on_push = true
  }
}
