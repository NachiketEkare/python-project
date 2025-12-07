# 🚀 python-project

This project demonstrates a production-grade deployment of a Python FastAPI service using:

1. AWS ECS Fargate
2. Application Load Balancer (ALB)
3. AWS ECR
4. Terraform (IaC)
5. GitHub Actions CI/CD
6. CloudWatch Monitoring & Alerts
7. IAM Least-Privilege + OIDC
8. AWS Secrets Manager


Two simple API endpoints expose application health and prediction score:
* GET /health   → {"status": "ok"}
* GET /predict  → {"score": 0.75}

# 🏗 Architecture Diagram

<img width="1024" height="1536" alt="architecture_diagram" src="https://github.com/user-attachments/assets/c45e1e01-be48-4f0e-965d-a28586a17695" />

* GitHub Actions performs test → build → push → deploy.

* OIDC allows secure AWS access without storing keys.

* ECS Fargate runs the FastAPI container in a private subnet.

* ALB routes external traffic and performs health checks.

* CloudWatch provides monitoring, dashboard, and alerts.

* Secrets Manager stores sensitive values securely.

# 🔧 Features

* FastAPI Application with /health and /predict routes

* Dockerized using a secure non-root multi-stage build

* Terraform-based infrastructure

* ECS Fargate deployment with rolling updates

* GitHub Actions CI/CD (build → test → push → deploy)

* CloudWatch Dashboard for CPU, memory, and ALB error metrics

* Two Alerting Policies:

  * High CPU alert

  * Unhealthy ALB Target alert

* IAM Least-Privilege with OIDC

* AWS Secrets Manager for sensitive configuration

# ⚙️ CICD Workflow

CI/CD Workflow
Continuous Integration (CI)

* Triggered on main branch updates:

* Checkout repository

* Install dependencies & run tests

* Build Docker image

* Authenticate to AWS using OIDC

* Push the image to Amazon ECR

Continuous Deployment (CD)

* After image push:

* Pull current ECS task definition

* Inject new image SHA

* Register updated task definition

* Update ECS service

* Amazon ECS performs rolling deployment

* GitHub Actions waits for service stabilization

# 📁 Deployment Guide
1. Initialize Terraform
terraform init

2. Provision Infrastructure
terraform apply --auto-approve

3. Test Application :
* http://ALB-DNS/health
* http://ALB-DNS/predict

# 📊 Monitoring, Dashboard and Alerts
CloudWatch Dashboard Includes:

* CPUUtilization

* MemoryUtilization

* HTTPCode_ELB_5XX_Count

Alerts Implemented:
* High CPU Alarm
* Triggers when ECS CPU > 70%.
* Unhealthy Target Alarm (ALB)
* Triggers when ALB detects ≥1 unhealthy container.

# 🔐 Security Considerations
* IAM Least-Privilege

1. GitHub workflow role can only:

2. Push to ECR

3. Register ECS task definitions

4. Update ECS services

5. Pass only the ECS execution role

* OIDC Authentication

1. Secure GitHub → AWS access without storing AWS keys.
2. Follows Amazon's recommended CI/CD security pattern.

* AWS Secrets Manager

1. All sensitive configuration values stored securely.

* Docker Security

1. Non-root user

2. Minimal base image

3. Multi-stage build ensures smaller attack surface

* HTTPS Ready

1. ALB can enforce HTTPS (port 80 → 443 redirect).
2. ACM certificate integration supported.

