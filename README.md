# AnsiTerra

A practice project combining **Terraform provisioning** and **Ansible configuration management** on AWS.

## Architecture

Terraform provisions the following AWS infrastructure in `eu-west-1`:

- **VPC** — `10.0.0.0/16` with DNS support enabled
- **Public Subnets** — 2 subnets across different availability zones
- **Internet Gateway** — attached to the VPC with a public route table
- **Security Group** — allows SSH (port 22), HTTP (80), HTTPS (443), and port 8080
- **EC2 Instances** — 3 x `t3.small` Ubuntu 24.04 instances in the first public subnet

## Variables (terraform.tfvars)

| Variable        | Description        | Example Value        |
|-----------------|--------------------|----------------------|
| `aws_region`    | AWS region         | `eu-west-1`          |
| `vpc_cidr`      | VPC CIDR block     | `10.0.0.0/16`        |
| `instance_type` | EC2 instance type  | `t3.small`           |
| `my_ip`         | Admin IP for SSH   | `197.211.59.102/32`  |
| `name_prefix`   | Resource name tag  | `ansiterra`          |
| `key_pair`      | EC2 key pair name  | `gridsynk-keypair`   |

## Usage

### Bootstrap (first-time backend setup)

The remote backend must be bootstrapped before first use, since the S3 bucket
and DynamoDB table need to exist before Terraform can store state remotely.

```bash
# 1. Comment out the backend block in backend.tf temporarily, then:
terraform init
terraform apply -target=aws_s3_bucket.terraform_state \
                -target=aws_dynamodb_table.terraform_state_lock

# 2. Uncomment backend.tf, then migrate local state to S3:
terraform init -migrate-state

# 3. Confirm "yes" when prompted to copy existing state
```

### Standard workflow

```bash
terraform init
terraform plan
terraform apply
```

Instance public IPs are available via output:

```bash
terraform output public_instance_public_ip
```

## Limitations

1. **Backend still in bootstrap** — The `backend.tf` and `backend-resources.tf` files are present, but you must run the bootstrap steps (see Usage) before the remote backend is active. Until then, state remains local.

2. **SSH exposed to public** — Security group allows SSH from `0.0.0.0/0` (line 73) in addition to the admin IP restriction (line 65). The `0.0.0.0/0` rule makes the admin IP restriction redundant and opens SSH to the internet.

3. **All subnets are public** — No private subnets, NAT gateway, or bastion host. Instances have public IPs and are directly reachable from the internet, which is not a production-grade network layout.

4. **Hardcoded instance count** — The `count = 3` is hardcoded in `main.tf:143` instead of being parameterized as a variable.

5. **Single subnet for all instances** — All 3 instances are placed in `aws_subnet.public[0]`, ignoring the second available subnet. There is no distribution across subnets.

