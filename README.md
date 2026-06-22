# AWS EKS Project by M. Irwan Asikin

## Repository Structure

```yaml
.
├── environment
│   └── dev
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── LICENSE
├── module
│   ├── backend
│   │   ├── addons.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── role.tf
│   │   ├── security.tf
│   │   └── variables.tf
│   ├── cdn
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── database
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── security.tf
│   │   └── variables.tf
│   ├── frontend
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── network
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── README.md
```

## To Do List

- [ ] Complete Network Module
- [ ] Complete Backend Module
- [ ] Complete Frontend Module
- [ ] Complete Database Module
- [ ] Complete CDN Module
- [ ] Add Module to Dev environment
- [ ] Add Gitlab CI for Checking with Checkov
- [ ] Add Productions environment

## Some information

- Using `m7i-flex.large` as Node
- Using 2 Public and 2 Private Subnet
- Using EIP and NAT Gateway

## Situation

- [x] Lab
- [ ] Portfolio/Dev environment
- [ ] Portfolio/Productions
