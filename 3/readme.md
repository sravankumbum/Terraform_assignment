# ECS Fargate Deployment with Service Connect (Terraform)

## Overview

This project deploys a simple **Todo application** using:

* Frontend (Port 3000)
* Backend (Port 5000)
* Communication via **Service Connect**
* Infrastructure provisioned using **Terraform**

---

## 🏗 Architecture

```
Internet
   ↓
Application Load Balancer (Public Subnet)
   ↓
Frontend Service (Private Subnet)
   ↓
Backend Service (Private Subnet via Service Connect)
   ↓
VPC Endpoints (ECR, Logs, S3)
```

---

## Prerequisites

* AWS CLI configured
* Terraform installed
* Docker installed
* IAM permissions for ECS, VPC, ECR, ALB

---

## Step 1: Create ECR Repositories

```hcl
aws_ecr_repository.frontend_repo
aws_ecr_repository.backend_repo
```

---

## Step 2: Build and Push Docker Images

### Frontend

```bash
docker build -t frontend .
docker tag frontend:latest <frontend_repo_url>:latest
docker push <frontend_repo_url>:latest
```

### Backend

```bash
docker build -t backend .
docker tag backend:latest <backend_repo_url>:latest
docker push <backend_repo_url>:latest
```

---

## Step 3: Create VPC Infrastructure

* Custom VPC (10.0.0.0/16)
* Public Subnets → ALB
* Private Subnets → ECS
* Internet Gateway
* Route Tables

---

## Step 4: Add VPC Endpoints (NO NAT)

Required endpoints:

* ECR API
* ECR DKR
* CloudWatch Logs
* S3 (for image layers)

```hcl
private_dns_enabled = true  # IMPORTANT
```

---

## Critical Learning

Even if you don’t use S3 directly:

```
ECR → stores image layers in S3
```

Without S3 endpoint:

```
Image pull fails 
```

---

## Step 5: Security Groups

* ALB → allows port 80 from internet
* Frontend → allows 3000 from ALB
* Backend → allows 5000 from frontend
* VPC Endpoint SG → allows 443 from ECS services

---

## Step 6: ECS Setup

### Cluster

```
todo-cluster
```

---

### Task Definitions

#### Backend

* Port: 5000
* Log group: `/ecs/backend`

#### Frontend

* Port: 3000
* Env:

```env
BACKEND_URL=http://backend:5000
```
* Log group: `/ecs/frontend`

---

## Step 7: Service Connect

### Backend

```hcl
service {
  port_name      = "backend"
  discovery_name = "backend"

  client_alias {
    port     = 5000
    dns_name = "backend"
  }
}
```

---

### Frontend

```hcl
service {
  port_name      = "frontend"
  discovery_name = "frontend"

  client_alias {
    port     = 3000
    dns_name = "frontend"
  }
}
```

---

## Step 8: Application Load Balancer

* Listener: HTTP (80)
* Target Group: frontend (port 3000)
* Health check path: `/`

---

## Step 9: CloudWatch Logs

* `/ecs/frontend`
* `/ecs/backend`

IAM Role must include:

```
logs:CreateLogGroup
```

---

## Step 10: Deploy Infrastructure

```bash
terraform init
terraform apply
```

---

## Step 11: Access Application

```bash
terraform output alb_url
```

Open:

```
http://<alb_dns>
```

---

## Debugging Guide

### No logs

→ Container didn’t start

---

### ECR timeout

→ Missing:

* private_dns_enabled
* VPC endpoint SG rule

---

### Cannot pull image

→ Check:

* S3 endpoint
* Image pushed to ECR

---

### Service Connect not working

→ Ensure:

* port_name matches container
* client_alias exists

---

## Cost Notes

| Service         | Cost     |
| --------------- | -------- |
| ECS Fargate     | Medium   |
| ALB             | Constant |
| VPC Endpoints   | Low      |
| CloudWatch Logs | Low      |

---

## Key Learnings

* Service Connect uses Cloud Map + Envoy
* ECR depends on S3 internally
* Private DNS is mandatory for VPC endpoints
* Logs are created only after container starts

---

## Cleanup

```bash
terraform destroy -var="key_name=<key-pair configured in aws>"
```

---

## Final Result

```
Frontend → Backend → Response → UI
(All inside private network)
```

---
