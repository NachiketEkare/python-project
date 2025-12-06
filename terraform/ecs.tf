#############################################
# ECS Cluster
#############################################

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"
}


#############################################
# OPTIONAL: Task Role (for app permissions)
#############################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

#############################################
# ECS Task Definition (FASTAPI)
#############################################

resource "aws_ecs_task_definition" "fastapi_task" {
  family                   = "${var.project}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn   # App can access AWS APIs

  container_definitions = jsonencode([
    {
      name      = "fastapi"
      image     = "${aws_ecr_repository.predict_api.repository_url}:latest"
      essential = true

      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]

      command = [
        "uvicorn", "src.main:app",
        "--host", "0.0.0.0",
        "--port", tostring(var.container_port)
      ]
    }
  ])
}

#############################################
# ECS Security Group (Allows ALB -> ECS only)
#############################################

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]   # Allow ONLY ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################
# ECS Service (Fargate)
#############################################

resource "aws_ecs_service" "service" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fastapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false    # Must have NAT Gateway
  }

  load_balancer {
    container_name   = "fastapi"
    container_port   = var.container_port
    target_group_arn = aws_lb_target_group.tg.arn
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]
}
