# AWS High-Availability 3-Tier Architecture ☁️

A production-ready infrastructure deployed via **Terraform** and **GitHub Actions**. This project demonstrates an automated, self-healing, and secure cloud environment following DevSecOps best practices.

![Architecture Diagram](https://your-image-link-here.com) 
*(Note: Upload your diagram to the repo and link it here)*

## 🏗 Architecture Highlights
* **Infrastructure as Code (IaC):** Fully modularized Terraform code.
* **CI/CD Pipeline:** Automated planning and application via GitHub Actions.
* **Zero-Trust Security:** Used **OIDC (OpenID Connect)** for AWS authentication (No hardcoded access keys).
* **High Availability:** Auto Scaling Group (ASG) spanning multiple Availability Zones with an Application Load Balancer.
* **State Management:** Remote state storage in **S3** with **DynamoDB** locking for team collaboration.
* **Cost Optimization:** Designed a "Free-Tier Compatible" architecture that mimics production security (Private Subnets for DB) without the overhead of NAT Gateways.

## 🛠 Tech Stack
* **Cloud:** AWS (VPC, EC2, RDS, IAM, S3, DynamoDB, Route53)
* **IaC:** Terraform
* **CI/CD:** GitHub Actions
* **OS:** Amazon Linux 2023 (Bootstrapped via User Data)
* **Database:** MySQL 8.0

## 🚀 How It Works
1.  **Push to Git:** Developer pushes code to the `main` branch.
2.  **OIDC Auth:** GitHub Actions authenticates with AWS using a temporary token (no long-lived keys).
3.  **Terraform Plan:** Validates the configuration and checks for drift.
4.  **Terraform Apply:** Provisions the VPC, Firewall Rules, Compute Cluster, and Database.
5.  **Post-Deployment:** The Load Balancer URL is outputted for immediate access.

## 🔒 Security Decisions
* **Database Isolation:** The RDS instance is placed in a **Private Subnet**, accessible *only* via the App Security Group on port 3306.
* **Least Privilege:** CI/CD roles are scoped strictly to required resources.
* **Encryption:** S3 State bucket is encrypted at rest; Database storage is encrypted.