output "frontend_public_ip" {
description = "Public IP of the EC2 instance"
value       = aws_instance.frontend_server.public_ip
}

output "backend_private_ip" {
description = "Public IP of the EC2 instance"
value       = aws_instance.backend_server.private_ip
}

output "frontend_public_dns" {
description = "Public DNS of the EC2 instance"
value       = aws_instance.frontend_server.public_dns
}


output "frontend_instance_id" {
description = "EC2 instance ID"
value       = aws_instance.frontend_server.id
}
output "backend_instance_id" {
description = "EC2 instance ID"
value       = aws_instance.backend_server.id
}

output "frontend_security_group_id" {
description = "Security group ID"
value       = aws_security_group.frontend_sg.id
}
output "backend_security_group_id" {
description = "Security group ID"
value       = aws_security_group.backend_sg.id
}

output "frontend_url" {
description = "URL to access Express frontend"
value       = "http://${aws_instance.frontend_server.public_ip}:3000"
}

