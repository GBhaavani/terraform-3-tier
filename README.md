# Azure 3-Tier Architecture Deployment with Terraform

This project uses [Terraform](https://www.terraform.io/) to deploy a 3-tier architecture on Microsoft Azure. It provisions a virtual network with three subnets (Web, App, DB), internal and external load balancers, Linux virtual machines for web and app tiers, and a PostgreSQL flexible server for the database tier with private DNS integration.

## Architecture Overview

- **Resource Group**: `rg-3tier`
- **Virtual Network**: `vnet-3tier` with subnets:
  - `web-subnet` (Public-facing)
  - `app-subnet` (Internal)
  - `db-subnet` (Internal, delegated for PostgreSQL)
- **Load Balancers**:
  - Public Load Balancer for Web VMs
  - Internal Load Balancer for App VMs
- **Compute**:
  - 2 Linux VMs for Web tier
  - 2 Linux VMs for App tier
- **Database**:
  - Azure PostgreSQL Flexible Server in DB subnet
- **Storage**:
  - Azure Storage Account
- **DNS**:
  - Private DNS zone for PostgreSQL connectivity

## Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- Azure CLI or Service Principal credentials
- SSH key pair at `~/.ssh/terraform_key.pub`
- Azure subscription and required IAM permissions

## Getting Started

1. **Clone the repository**:# Azure 3-Tier Architecture Deployment with Terraform

This project uses [Terraform](https://www.terraform.io/) to deploy a 3-tier architecture on Microsoft Azure. It provisions a virtual network with three subnets (Web, App, DB), internal and external load balancers, Linux virtual machines for web and app tiers, and a PostgreSQL flexible server for the database tier with private DNS integration.

## Architecture Overview

- **Resource Group**: `rg-3tier`
- **Virtual Network**: `vnet-3tier` with subnets:
  - `web-subnet` (Public-facing)
  - `app-subnet` (Internal)
  - `db-subnet` (Internal, delegated for PostgreSQL)
- **Load Balancers**:
  - Public Load Balancer for Web VMs
  - Internal Load Balancer for App VMs
- **Compute**:
  - 2 Linux VMs for Web tier
  - 2 Linux VMs for App tier
- **Database**:
  - Azure PostgreSQL Flexible Server in DB subnet
- **Storage**:
  - Azure Storage Account
- **DNS**:
  - Private DNS zone for PostgreSQL connectivity

## Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- Azure CLI or Service Principal credentials
- SSH key pair at `~/.ssh/terraform_key.pub`
- Azure subscription and required IAM permissions

## Getting Started

1. **Clone the repository**:
   ```bash
   https://github.com/GBhaavani/terraform-3-tier.git
   cd terraform-3-tier.git
terraform init
terraform apply
terraform destroy

Notes:

The PostgreSQL server is created with zone redundancy and private access only.

Web VMs are accessible through the public IP and Load Balancer; App and DB tiers are isolated within the virtual network.

Passwords and secrets are hardcoded for demo purposes. Do not use this setup in production without securing sensitive data using secret management tools (e.g., Azure Key Vault).
