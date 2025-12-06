#############################################
# ECS Cluster
#############################################

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"
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
  task_role_arn      = aws_iam_role.ecs_task_role.arn

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
# ECS Security Group
#############################################

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

#############################################
# ECS Service
#############################################

resource "aws_ecs_service" "service" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fastapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
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
