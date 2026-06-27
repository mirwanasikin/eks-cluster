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

- [x] Complete Network Module
- [x] Complete Backend Module
- [x] Complete Frontend Module
- [x] Complete Database Module
- [x] Add Module to Dev environment
- [x] Add Gitlab CI for Checking with Checkov
- [ ] Add Productions environment

## Some information

- Using `m7i-flex.large` as Node
- Using 2 Public and 2 Private Subnet
- Using EIP and NAT Gateway

## Situation

- [x] Lab
- [x] Portfolio/Dev environment
- [ ] Portfolio/Productions
