# modules/vpc-network/README.md

## VPC Network Module

This module creates a base VPC network with the following:
- One VPC
- Multiple public subnets (across AZs)
- Multiple private subnets (across AZs)
- Internet Gateway and public route table

### Inputs
| Name         | Description                     | Type     | Required |
|--------------|----------------------------------|----------|----------|
| `vpc_cidr`   | CIDR block for the VPC          | string   | ✅ Yes    |
| `subnet_count` | Number of subnets per type     | number   | ✅ Yes    |
| `project`    | Project or service name         | string   | ✅ Yes    |
| `environment`| Environment name (dev/prod/etc) | string   | ✅ Yes    |

### Outputs
| Name                 | Description                |
|----------------------|----------------------------|
| `vpc_id`             | VPC ID                     |
| `public_subnet_ids`  | List of public subnet IDs  |
| `private_subnet_ids` | List of private subnet IDs |
| `azs`                | List of selected AZ names  |

