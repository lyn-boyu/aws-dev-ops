# README.md (Root Project)

## 🏗️ VPC + NAT Gateway Terraform Setup

This project provisions a highly available VPC network across multiple Availability Zones with optional NAT Gateway egress control for private subnets.

---
## 🌐  Network Architecture Overview

```
[ VPC: 10.0.0.0/16 ]
│
├── Internet Gateway (IGW)
│
├── [ AZ-1 ]
│   ├── Public Subnet A (10.0.0.0/24)
│   │   ├── NAT Gateway A
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet A (10.0.10.0/24)
│       ├── ✅ NAT Egress
│       └── Route: 0.0.0.0/0 → NAT Gateway A
│
├── [ AZ-2 ]
│   ├── Public Subnet B (10.0.1.0/24)
│   │   ├── NAT Gateway B
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet B (10.0.11.0/24)
│       ├── ❌ No NAT (isolated)
│       └── Route: local only (no 0.0.0.0/0)
```



## 📁 Directory Structure
```
├── main.tf                        # Root configuration using both modules
├── terraform.tfvars              # Custom variables
├── terraform.tfvars.example      # Example config
├── modules/
│   ├── vpc-network/              # Creates VPC, public/private subnets, IGW, public routes
│   │   └── README.md             # Documentation for vpc-network module
│   └── nat-gateway/              # Creates NAT Gateway(s) and egress route tables
│       └── README.md             # Documentation for nat-gateway module
└── outputs.tf                    # Unified output exports
```

---

## 🔧 Usage  

### ✅ Option A: All private subnets use NAT

**Path**: `/terraform/network.tf`
```hcl
module "vpc_network" {
  source       = "../../modules/vpc-network"
  vpc_cidr     = "10.0.0.0/16"
  subnet_count = 2
  project      = "demo"
  environment  = "dev"
}

module "nat_gateway" {
  source                          = "../../modules/nat-gateway"
  vpc_id                          = module.vpc_network.vpc_id
  azs                             = module.vpc_network.azs
  public_subnet_ids               = module.vpc_network.public_subnet_ids
  private_subnet_ids              = module.vpc_network.private_subnet_ids
  private_subnet_ids_with_egress = module.vpc_network.private_subnet_ids
  project                         = "demo"
  environment                     = "dev"
}
```
#### 🧭 Network Architecture Overview
All private subnets → NAT Gateway in their AZ
Route: 0.0.0.0/0 → NAT

```
[ VPC: 10.0.0.0/16 ]
│
├── Internet Gateway (IGW)
│
├── [ AZ-1 ]
│   ├── Public Subnet A (10.0.0.0/24)
│   │   ├── NAT Gateway A
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet A (10.0.10.0/24)
│       ├── ✅ NAT Egress
│       └── Route: 0.0.0.0/0 → NAT Gateway A
│
├── [ AZ-2 ]
│   ├── Public Subnet B (10.0.1.0/24)
│   │   ├── NAT Gateway B
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet B (10.0.11.0/24)
│       ├── ✅ NAT Egress
│       └── Route: 0.0.0.0/0 → NAT Gateway B
```

 

### ✅ Option B: Only specific subnets use NAT
**Path**: `/terraform/network.tf`
```hcl
module "vpc_network" {
  source       = "../../modules/vpc-network"
  vpc_cidr     = "10.0.0.0/16"
  subnet_count = 2
  project      = "demo"
  environment  = "dev"
}

module "nat_gateway" {
  source                          = "../../modules/nat-gateway"
  vpc_id                          = module.vpc_network.vpc_id
  azs                             = module.vpc_network.azs
  public_subnet_ids               = module.vpc_network.public_subnet_ids
  private_subnet_ids              = module.vpc_network.private_subnet_ids
  private_subnet_ids_with_egress = [module.vpc_network.private_subnet_ids[0]]
  project                         = "demo"
  environment                     = "dev"
}
```

#### 🧭 Network Architecture Overview

Private Subnet A → NAT Gateway A
Private Subnet B → No internet (local route only)

```
[ VPC: 10.0.0.0/16 ]
│
├── Internet Gateway (IGW)
│
├── [ AZ-1 ]
│   ├── Public Subnet A (10.0.0.0/24)
│   │   ├── NAT Gateway A
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet A (10.0.10.0/24)
│       ├── ✅ NAT Egress
│       └── Route: 0.0.0.0/0 → NAT Gateway A
│
├── [ AZ-2 ]
│   ├── Public Subnet B (10.0.1.0/24)
│   │   ├── NAT Gateway B
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet B (10.0.11.0/24)
│       ├── ❌ No NAT (isolated)
│       └── Route: local only (no 0.0.0.0/0)
```
 

### ✅ Option C: No private subnets use NAT
**Path**: `/terraform/network.tf`
```hcl
module "vpc_network" {
  source       = "../../modules/vpc-network"
  vpc_cidr     = "10.0.0.0/16"
  subnet_count = 2
  project      = "demo"
  environment  = "dev"
}

# Omit the nat_gateway module
```
#### 🧭 Network Architecture Overview
All private subnets are isolated
No NAT Gateways or outbound internet routes

```
[ VPC: 10.0.0.0/16 ]
│
├── Internet Gateway (IGW)
│
├── [ AZ-1 ]
│   ├── Public Subnet A (10.0.0.0/24)
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet A (10.0.10.0/24)
│       └── Route: local only (no 0.0.0.0/0)
│
├── [ AZ-2 ]
│   ├── Public Subnet B (10.0.1.0/24)
│   │   └── Route: 0.0.0.0/0 → IGW
│   └── Private Subnet B (10.0.11.0/24)
│       └── Route: local only (no 0.0.0.0/0)
```



---

## ✨ Features
- Multi-AZ public and private subnet creation
- Public subnets route to Internet Gateway
- NAT Gateway per AZ (high availability)
- Selectively route only specified private subnets through NAT
- Modular, reusable design

---

## 📤 Outputs
| Output               | Description |
|----------------------|-------------|
| `vpc_id`             | VPC ID |
| `public_subnet_ids`  | List of public subnets |
| `private_subnet_ids` | List of private subnets |
| `nat_gateway_ids`    | List of NAT Gateway IDs |
| `azs`                | List of Availability Zones |

---

## 🧪 terraform.tfvars.tf
```hcl
vpc_cidr     = "10.0.0.0/16"
subnet_count = 2
project      = "my-app"
environment  = "prod"
```

---

## 📘 Notes
- You can control which private subnets have internet access via `private_subnet_ids_with_egress`
- Subnets not listed in that variable will remain isolated (no 0.0.0.0/0 route)
- Each NAT Gateway is placed in a different AZ to improve fault tolerance

---


