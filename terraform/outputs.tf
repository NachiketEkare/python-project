output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "ecr_repo" {
  value = aws_ecr_repository.predict_api.repository_url
}

output "ecs_cluster" {
  value = aws_ecs_cluster.main.name
}
