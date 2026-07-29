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

1. **No Ansible files** — The project name implies Ansible integration, but no playbooks, inventory files, `ansible.cfg`, or dynamic inventory scripts are included. Ansible configuration management is not yet implemented.

1. **Backend still in bootstrap** — The `backend.tf` and `backend-resources.tf` files are present, but you must run the bootstrap steps (see Usage) before the remote backend is active. Until then, state remains local.

2. **SSH exposed to全世界** — Security group allows SSH from `0.0.0.0/0` (line 73) in addition to the admin IP restriction (line 65). The `0.0.0.0/0` rule makes the admin IP restriction redundant and opens SSH to the internet.

3. **All subnets are public** — No private subnets, NAT gateway, or bastion host. Instances have public IPs and are directly reachable from the internet, which is not a production-grade network layout.

4. **Port 8080 lacks description** — Ingress rule for port 8080 (line 93) has an empty `description` field, making its purpose unclear.

5. **Duplicate Name tag on instances** — All 3 instances get the identical tag `ansiterra-public-instance` (no index suffix), making them indistinguishable in the AWS console.

6. **Hardcoded instance count** — The `count = 3` is hardcoded in `main.tf:143` instead of being parameterized as a variable.

7. ~~**Local Terraform state** — Fixed. S3 remote backend with DynamoDB locking is configured in `backend.tf`.~~

8. ~~**State files committed** — Fixed. `.gitignore` now excludes state files. You must run `git rm --cached terraform.tfstate terraform.tfstate.backup` to stop tracking them.~~

9. ~~**No `.gitignore`** — Fixed. `.gitignore` now excludes state files, `.terraform/` directory, crash logs, and override files.~~

10. **No Terraform version constraints** — Neither `required_version` nor provider version constraints are specified, which can lead to unexpected behavior with different Terraform versions.

11. **Key pair not managed** — The EC2 key pair (`gridsynk-keypair`) is expected to pre-exist in AWS. Terraform does not create or manage it.

12. **No provisioners** — There are no `provisioner` blocks or `remote-exec` to bootstrap instances or trigger Ansible after provisioning.

13. **Single subnet for all instances** — All 3 instances are placed in `aws_subnet.public[0]`, ignoring the second available subnet. There is no distribution across subnets.

14. **Limited outputs** — Only public IPs are output. No private IPs, instance IDs, VPC ID, subnet IDs, or security group IDs are exposed.
