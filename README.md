# 📋 Todolist App — AWS Serverless & CI/CD Project

A fully serverless, scalable, and automated Todolist web application built on AWS, provisioned using Terraform, and integrated with CI/CD pipelines via CodePipeline and CodeBuild.

---

## 🖼️ Project Overview

This project demonstrates a real-world, production-grade cloud application with:

- Frontend hosting via **S3 + CloudFront + Route 53**
- Backend APIs using **Lambda + API Gateway**
- Secure user authentication with **Amazon Cognito**
- CI/CD using **AWS CodePipeline** and **CodeBuild**
- **Infrastructure as Code** using **Terraform**
- Task deadline notifications powered by **Amazon EventBridge + Lambda + SES**
- Profile upload functionality stored securely in S3
- **HTTPS support via AWS Certificate Manager (ACM)**

---

## 🔧 Tech Stack

| Layer             | Services Used                                                                  |
|-------------------|--------------------------------------------------------------------------------|
| **Frontend**       | HTML, CSS, JS hosted on **S3**, served via **CloudFront** + **Route 53**       |
| **CI/CD**          | **CodePipeline**, **CodeBuild**, GitHub integration, Artifacts stored in S3    |
| **Auth**           | **Amazon Cognito** for user pools, login/signup, and secure access             |
| **Backend API**    | **API Gateway** triggering **Lambda** functions                                |
| **Database**       | **Amazon DynamoDB** for task storage, isolated per user                        |
| **Storage**        | S3 bucket for profile pictures, private per user                               |
| **Notifications**  | **Amazon EventBridge** + **Lambda** + **SES** for task deadline reminders      |
| **Infrastructure** | Fully provisioned via **Terraform**                                            |
| **Access Control** | IAM Roles + Inline Policies for all services                                   |
| **SSL/TLS Certs**  | **AWS Certificate Manager (ACM)** for HTTPS on CloudFront and Route 53         |

---

## 🗂️ Architecture Diagram (Text Summary)

GitHub Repo (frontend source)
⬇
CodePipeline (zips, uploads to artifacts S3)
⬇
Artifacts S3 Bucket (source stage)
⬇
CodeBuild (unzips + syncs with hosting S3 bucket)
⬇
Static Website S3 (public)
⬇
CloudFront ➡️ Users ➡️ Route 53 (custom domain + HTTPS via ACM)

Users ➡️ Cognito ➡️ Token ➡️ API Gateway ➡️ Lambda ➡️ DynamoDB
⬆
S3 (profile pictures)

⏰ EventBridge (scheduled rule)
⬇
Lambda (check tasks nearing deadline)
⬇
Amazon SES (send notification email)


---

## ✅ Features

- 👤 **User Auth** – Sign up, login, verify email using Amazon Cognito  
- 📝 **Task Management** – Add, update, delete personal tasks  
- ⏰ **Task Deadlines** – Store due dates for reminders  
- 📩 **Email Reminders** – EventBridge + Lambda + SES send alerts before deadlines  
- 📷 **Profile Uploads** – S3 storage with per-user access  
- ♻️ **CI/CD** – GitHub push auto-syncs S3 static website  
- 🔐 **Access Control** – IAM with least-privilege roles  
- 🌐 **HTTPS** – Managed by AWS ACM on CloudFront  
- 🧱 **Infrastructure** – 100% managed via Terraform  

---

## 🚀 Deployment

You can deploy this project in your own AWS account:

### 1. Clone the repo
```bash
git clone https://github.com/patrickneil03/TaskflowRepoApp.git

2. Configure Terraform
Update variables (bucket names, domain, region, etc.).

3. Deploy Infrastructure
cd terraform/
terraform init
terraform plan   # Review planned changes
terraform apply  # Provision infrastructure

4. Push Frontend Code to GitHub
Push to the main branch

CodePipeline triggers CodeBuild

Static files sync to the public S3 bucket
project-root/
├── html/              # HTML files
├── css/               # CSS styles
├── js/                # JavaScript logic
├── img/               # Images, profile uploads
├── terraform/         # All Terraform .tf files
├── .gitignore
├── .gitattributes
└── README.md

🔐 Security
IAM policies follow least privilege best practices

Cognito secures API access via tokens

Profile uploads are per-user private in S3

HTTPS via ACM protects all public traffic

Lambda roles are tightly scoped

📚 Learning Highlights
This project helped me develop and demonstrate skills in:

AWS serverless architecture

Secure CI/CD pipelines with GitHub, CodePipeline, and CodeBuild

Infrastructure as Code using Terraform

Event-driven automation with EventBridge

IAM and Cognito for secure access control

Hosting static frontends on S3 with CloudFront and Route 53

Email automation via AWS SES

🙋 About Me
I'm an aspiring Cloud Engineer passionate about AWS and DevOps.
This project is part of my hands-on learning journey and cloud portfolio.

## 🙋 About Me

I'm an aspiring **Cloud Engineer** passionate about AWS and DevOps.  
This project is part of my hands-on learning journey and cloud portfolio.

[My LinkedIn Profile](https://www.linkedin.com/in/patrick-neil-baylen-01b175159)


🧠 AWS Certified Cloud Practitioner
