resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"
}

// task definition

resource "aws_ecs_task_definition" "fastapi_task" {
  family                   = "${var.project}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "fastapi"
      image     = "${aws_ecr_repository.predict_api.repository_url}:initial"

      essential = true
      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]
    }
  ])
}

// ecs security group

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
// ecs service

resource "aws_ecs_service" "service" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fastapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    container_name   = "fastapi"
    container_port   = var.container_port
    target_group_arn = aws_lb_target_group.tg.arn
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]
}

