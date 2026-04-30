resource "aws_ecs_cluster" "todoapp_cluster" {
  name = "todoapp_cluster"
  
  tags = {
  Name = "todoapp-cluster"
  }
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = <<TASK_DEFINITION
  [
    {
        "name": "backend_service",
        "image": "120091910163.dkr.ecr.ap-south-1.amazonaws.com/my_app/backend_repo:latest",
        "essential": true,
        
        "portMappings": [
        {
            "containerPort": 5000,
            "hostPort": 5000
        }
        ]
    }
  ]
  TASK_DEFINITION
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend_task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = <<TASK_DEFINITION
  [
    {
        "name": "frontend_service",
        "image": "120091910163.dkr.ecr.ap-south-1.amazonaws.com/my_app/frontend_repo:latest",
        "essential": true,
        "environment": [
            {"name":"BACKEND_URL","value":"http://backend.todoapp.local:5000"}
        ],
        
        "portMappings": [
        {
            "containerPort": 3000,
            "hostPort": 3000
        }
        ]
    }
  ]
  TASK_DEFINITION
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "backend_service" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.todoapp_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  launch_type     = "FARGATE"

  desired_count = 1


  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.backend_sg.id]
    assign_public_ip = true
  }
}
resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.todoapp_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  launch_type     = "FARGATE"

  desired_count = 1

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.frontend_sg.id]
    assign_public_ip = true
  }
}


