# -----------------------------
# OpenTofu Backend Configuration
# ------------------------------

terraform {
  backend "s3" {
    bucket       = "terra-irwan-s3"
    key          = "eks-cluster/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
