# modules/nat-gateway/README.md

## NAT Gateway Module

This module provisions one NAT Gateway per AZ (public subnet) and routes selected private subnets through them for internet access.

### Features
- Multi-AZ NAT deployment
- Per-subnet egress control
- Scales with public/private subnet counts

### Inputs
| Name                          | Description                                             | Type         | Required |
|-------------------------------|---------------------------------------------------------|--------------|----------|
| `vpc_id`                      | VPC ID where the NAT Gateways will be deployed         | string       | ✅ Yes    |
| `public_subnet_ids`          | List of public subnet IDs for NAT placement            | list(string) | ✅ Yes    |
| `private_subnet_ids`         | All private subnet IDs (reference only)                | list(string) | ✅ Yes    |
| `private_subnet_ids_with_egress` | Subset of private subnets to allow outbound NAT      | list(string) | ❌ Optional |
| `azs`                         | List of availability zones (to match public subnets)   | list(string) | ✅ Yes    |
| `project`                     | Project prefix                                          | string       | ✅ Yes    |
| `environment`                | Environment (e.g. dev/stage/prod)                      | string       | ✅ Yes    |

### Outputs
| Name             | Description            |
|------------------|------------------------|
| `nat_gateway_ids`| List of NAT Gateway IDs|

### Example Usage
```hcl
module "nat_gateway" {
  source = "./modules/nat-gateway"

  vpc_id                          = module.vpc_network.vpc_id
  azs                             = module.vpc_network.azs
  public_subnet_ids               = module.vpc_network.public_subnet_ids
  private_subnet_ids              = module.vpc_network.private_subnet_ids
  private_subnet_ids_with_egress = [module.vpc_network.private_subnet_ids[0]]

  project     = "demo"
  environment = "dev"
}
```

### Notes
- Use `private_subnet_ids_with_egress` to control which subnets receive NAT access
- Each subnet will be mapped to one NAT Gateway in the same AZ (round-robin if unequal)
