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

```plaintext
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
✅ Features
👤 User Auth – Sign up, login, verify email using Amazon Cognito

📝 Task Management – Add, update, delete personal tasks

⏰ Task Deadlines – Store due dates for reminders

📩 Email Reminders – EventBridge triggers Lambda to check deadlines and use SES to email users 24h before a task is due

📷 Profile Uploads – Store and access user images securely via S3

♻️ CI/CD – GitHub push triggers full frontend deployment to S3

🔐 Access Control – IAM roles and least-privilege inline policies

🌐 HTTPS Enabled – CloudFront uses SSL certificates issued by AWS ACM

🧱 Provisioning – All infra defined and deployed with Terraform

🚀 Deployment
You can deploy this project in your own AWS account:

1. Clone the repo
bash
Copy
Edit
git clone https://github.com/your-username/todolist-app.git
2. Configure Terraform
Edit variables such as bucket name, domain name, region, etc.

3. Deploy Infrastructure (Recommended Practice)
bash
Copy
Edit
cd terraform/
terraform init
terraform plan   # Review changes before applying
terraform apply  # Deploy infrastructure
4. Push Frontend Code to GitHub
Pushing to the main branch will trigger CodePipeline

Frontend files will auto-sync to the S3 static site

📦 Folder Structure
bash
Copy
Edit
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
IAM policies are scoped to least privilege

S3 buckets use bucket policies for access control

Lambda functions use execution roles

Cognito authorizes API requests securely via Bearer tokens

CloudFront traffic secured via HTTPS (ACM)

📚 Learning Highlights
This project helped me practice and demonstrate skills in:

AWS Serverless architecture

Infrastructure as Code with Terraform

CI/CD pipelines with GitHub + CodePipeline + CodeBuild

Secure app design using IAM and Cognito

Building feature-rich, user-facing applications on the cloud

Event-driven workflows using EventBridge + Lambda + SES

SSL provisioning with AWS Certificate Manager

📸 Screenshots (Optional)
Homepage

Task dashboard

Cognito login/signup

S3 profile picture upload preview

📌 To-Do (Improvements)
 Add WAF for extra protection

 Separate dev and prod environments using Terraform workspaces

## 🙋 About Me

I'm an aspiring **Cloud Engineer** passionate about AWS and DevOps.  
This project is part of my hands-on learning journey and cloud portfolio.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Patrick%20Baylen-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/patrick-neil-baylen-01b175159)

- 🧠 AWS Certified Cloud Practitioner
