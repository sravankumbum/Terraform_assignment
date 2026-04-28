#!/bin/bash

# Log everything (very important for debugging)
exec > /home/ec2-user/user-data.log 2>&1

# Update system
yum update -y

# Install Git
yum install git -y


# Install Node.js (v18)
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install nodejs -y

# Clone your project (IMPORTANT: replace with your repo if needed)
cd /home/ec2-user
git clone https://github.com/sravankumbum/Terraform_assignment.git app
# Go into project
cd app/2

# Fix ownership
chown -R ec2-user:ec2-user /home/ec2-user/app


# Frontend setup (Express)
cd ./frontend

#assign backend URL to env variable for frontend to use
echo "BACKEND_URL=http://${backend_ip}:5000" > .env

npm install

# Run Express in background
nohup node server.js > express.log 2>&1 &