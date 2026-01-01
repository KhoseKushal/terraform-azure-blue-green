# Azure Blue-Green Deployment using Terraform

## 📌 Overview
This project demonstrates a **Blue–Green deployment strategy** on Microsoft Azure using **Terraform** to achieve **zero-downtime application releases**.

Two identical Linux environments (Blue and Green) are deployed behind an Azure Load Balancer. Traffic can be switched between environments by updating the Load Balancer backend pool.

---

## 🏗️ Architecture

User  
→ Azure Public IP  
→ Azure Load Balancer  
→ Backend Pool (Blue / Green)  
→ Network Interface  
→ Linux VM (NGINX)

---

## 🧰 Technologies Used
- Terraform
- Microsoft Azure
- Azure Virtual Machines (Linux)
- Azure Load Balancer
- NGINX
- Azure CLI
- SSH Key Authentication

---

## ⚙️ Key Features
- Infrastructure as Code (IaC) using Terraform
- Blue–Green deployment for zero downtime
- Automated VM provisioning with cloud-init
- NGINX installation during VM boot
- Safe rollback by switching backend pools

---

## 🔁 Blue–Green Traffic Switching

Traffic routing is controlled by Azure Load Balancer backend pools:

- **Blue active** → traffic routed to Blue VM
- **Green active** → traffic routed to Green VM

Traffic switch is performed by updating Terraform configuration and running:
```bash
terraform apply
