output "public_ip" {
description = "Public IP of the EC2 instance"
value       = aws_instance.app_server.public_ip
}

output "public_dns" {
description = "Public DNS of the EC2 instance"
value       = aws_instance.app_server.public_dns
}

output "instance_id" {
description = "EC2 instance ID"
value       = aws_instance.app_server.id
}

output "security_group_id" {
description = "Security group ID"
value       = aws_security_group.app_sg.id
}

output "frontend_url" {
description = "URL to access Express frontend"
value       = "http://${aws_instance.app_server.public_ip}:3000"
}

output "backend_url" {
description = "URL to access Flask backend"
value       = "http://${aws_instance.app_server.public_ip}:5000"
}
