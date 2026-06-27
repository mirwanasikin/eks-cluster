# Production-Grade AWS EKS Infrastructure

**by M. Irwan Asikin**

A production-grade Infrastructure as Code project for deploying containerized applications on AWS EKS, built with a security-first mindset and enterprise best practices.

## Architecture

```
Cloudflare DNS
      │
      ▼
AWS CloudFront (CDN)
      │
   ┌──┴─────────────────────┐
   │                        │
   ▼                        ▼
S3 (Vue.js Frontend)    ALB (Load Balancer)
                             │
                             ▼
                     EKS (Private Subnet)
                     m7i-flex.large nodes
                             │
                             ▼
                     RDS PostgreSQL
                     (Private Subnet)
```

## Tech Stack

| Layer                   | Technology                                          |
| ----------------------- | --------------------------------------------------- |
| IaC                     | OpenTofu (Terraform-compatible)                     |
| Container Orchestration | AWS EKS 1.33 (Kubernetes)                           |
| Networking              | VPC, ALB, NAT Gateway, EIP                          |
| Database                | RDS PostgreSQL (encrypted, SSM-managed credentials) |
| Frontend Delivery       | S3 + CloudFront + OAC                               |
| Security                | KMS, IAM IRSA, Checkov, Security Groups             |
| CI/CD                   | GitLab CI with OIDC (zero hardcoded credentials)    |
| Monitoring              | Prometheus, Grafana, Loki, CloudWatch               |

## Security Highlights

- **Zero hardcoded credentials** — AWS credentials via OIDC, DB password generated via `random_password` and stored in SSM Parameter Store
- **Private-only EKS endpoint** — cluster API not exposed to the internet
- **KMS encryption everywhere** — all data at rest (EKS secrets, RDS, S3, SSM) encrypted with customer-managed keys
- **Shift-left security** — Checkov scanning locally and in GitLab CI before any `tofu apply`
- **Least privilege IAM** — every component has a dedicated IAM role with minimal required permissions
- **IMDSv2 enforced** — node metadata service requires session tokens

## Repository Structure

```
.
├── environment
│   └── dev                  # Root module — wires all child modules
│       ├── backend.tf        # S3 native locking (OpenTofu 1.8+, no DynamoDB)
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── module
│   ├── network               # VPC, Subnets, IGW, NAT Gateway, EIP
│   ├── backend               # EKS Cluster, Node Group, OIDC, Addons
│   ├── frontend              # S3, CloudFront OAC, GitLab CI OIDC role
│   └── database              # RDS PostgreSQL, SSM Parameters, KMS
├── .gitlab-ci.yml            # Checkov scan + tofu validate pipeline
└── README.md
```

## Infrastructure Details

| Component     | Configuration                                   |
| ------------- | ----------------------------------------------- |
| Region        | ap-southeast-1 (Singapore)                      |
| VPC           | 10.0.0.0/16                                     |
| Subnets       | 2 public + 2 private (multi-AZ)                 |
| EKS Version   | Kubernetes 1.33                                 |
| Node Type     | m7i-flex.large (ON_DEMAND)                      |
| Autoscaling   | min 2 / desired 2 / max 4                       |
| RDS           | PostgreSQL, db.t3.micro, 7-day backup retention |
| State Backend | S3 with native locking (OpenTofu 1.8+)          |

## CI/CD Pipeline

```
git push
    │
    ▼
Checkov (module/)
    │
    ▼
Checkov (environment/)
    │
    ▼
tofu validate
```

All checks must pass before merging to `main`.

## Roadmap

- [x] Network Module (VPC, Subnets, NAT Gateway)
- [x] EKS Backend Module (Cluster, Node Group, OIDC, Addons)
- [x] Frontend Module (S3 + CloudFront OAC)
- [x] Database Module (RDS PostgreSQL + SSM)
- [x] Root Module (environment/dev)
- [x] GitLab CI Pipeline (Checkov + tofu validate)
- [ ] External Secrets Operator
- [ ] Prometheus + Grafana + Loki deployment
- [ ] ArgoCD integration
- [ ] Production environment
