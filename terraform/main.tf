# Terraform Infrastructure for AWS Production Deployment of TaskApp

This Terraform configuration will provision a comprehensive AWS infrastructure for the TaskApp application. The setup includes a Virtual Private Cloud (VPC), IAM roles, networking configurations, and a Kubernetes cluster using EKS.

## Directory Structure
```
terraform/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── iam/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── eks/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── main.tf
```

## Main Configuration File (`main.tf`)
```hcl
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./vpc"
}

module "iam" {
  source = "./iam"
}

module "eks" {
  source = "./eks"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}
```

## VPC Module (`vpc/main.tf`)
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "public" {
  count = var.subnet_count
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = var.subnet_count
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "PrivateSubnet-${count.index}"
  }
}
```

## IAM Module (`iam/main.tf`)
```hcl
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
      Effect = "Allow"
      Sid = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
```

## EKS Module (`eks/main.tf`)
```hcl
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_cluster_role.arn
  subnet_ids      = var.subnet_ids
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}
```

## Variables File Samples
- `vpc/variables.tf`
```hcl
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "subnet_count" {
  default = 2
}
```

- `iam/variables.tf`
```hcl
variable "aws_region" {
  default = "us-west-2"
}
```

- `eks/variables.tf`
```hcl
variable "cluster_name" {
  default = "taskapp-cluster"
}

variable "subnet_ids" {
  description = "The VPC Subnets to launch the EKS Cluster in."
  type = list(string)
}
```

## Output Files Samples
- `vpc/outputs.tf`
```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}
```