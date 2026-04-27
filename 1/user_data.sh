#!/bin/bash

# Update system
yum update -y

# Install Git
yum install git -y

# Install Python3 & pip
yum install python3 -y
pip3 install flask

# Install Node.js (v18)
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install nodejs -y

# Clone your project (IMPORTANT: replace with your repo if needed)
cd /home/ec2-user
git clone https://github.com/sravankumbum/Terraform_assignment/tree/main/1 app

# Go into project
cd app

# Backend setup (Flask)
cd backend
pip3 install -r requirements.txt

# Run Flask in background
nohup python3 app.py > flask.log 2>&1 &

# Frontend setup (Express)
cd ../frontend
npm install

# Run Express in background
nohup node server.js > express.log 2>&1 &