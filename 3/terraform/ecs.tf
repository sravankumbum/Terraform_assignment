############################################
# IAM Role (with logs permission FIX)
############################################
resource "aws_iam_role" "ecs_exec" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 🔥 FIX: Allow CreateLogGroup
resource "aws_iam_role_policy" "logs_policy" {
  role = aws_iam_role.ecs_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup"
      ]
      Resource = "*"
    }]
  })
}

############################################
# CloudWatch Log Groups
############################################
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/backend"
  retention_in_days = 1
}

resource "aws_service_discovery_private_dns_namespace" "namespace" {
  name = "todo-namespace"
  vpc  = aws_vpc.main.id
}

############################################
# ECS Cluster
############################################
resource "aws_ecs_cluster" "cluster" {
  name = "todo-cluster"
}

############################################
# Security Groups
############################################
resource "aws_security_group" "frontend_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
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

resource "aws_security_group" "backend_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# Backend Task Definition
############################################
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu    = "512"
  memory = "1024"

  execution_role_arn = aws_iam_role.ecs_exec.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend_repo.repository_url}:latest"

      portMappings = [
        {
          containerPort = 5000
          name          = "backend"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/backend"
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

############################################
# Frontend Task Definition
############################################
resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu    = "512"
  memory = "1024"

  execution_role_arn = aws_iam_role.ecs_exec.arn

  container_definitions = jsonencode([
    {
      name  = "frontend"
      image = "${aws_ecr_repository.frontend_repo.repository_url}:latest"

      portMappings = [
        {
          containerPort = 3000
          name          = "frontend"
        }
      ]

      environment = [
        {
          name  = "BACKEND_URL"
          value = "http://backend:5000"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/frontend"
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

############################################
# Backend Service
############################################
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.backend_sg.id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
     namespace = aws_service_discovery_private_dns_namespace.namespace.arn

    service {
      port_name      = "backend"
      discovery_name = "backend"

      client_alias {
        port     = 5000
        dns_name = "backend"
      }
    }
  }
}

############################################
# Frontend Service
############################################
resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.frontend_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.listener]

  service_connect_configuration {
    enabled   = true
     namespace = aws_service_discovery_private_dns_namespace.namespace.arn

    service {
      port_name      = "frontend"
      discovery_name = "frontend"

      client_alias {
        port     = 3000
        dns_name = "frontend"
      }
    }
  }
}