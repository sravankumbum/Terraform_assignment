resource "aws_ecr_repository" "frontend_repo" {
  name                 = "my_app/frontend_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
  Name = "frontend-repo"
  }
}
resource "aws_ecr_repository" "backend_repo" {
  name                 = "my_app/backend_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
  Name = "backend-repo"
  }
}