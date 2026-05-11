# terraform {
#   cloud {

#     organization = "depi-gradProject"

#     workspaces {
#       name = "depi-dev"
#     }
#   }
# }

terraform {
  backend "s3" {
    bucket         = "terraform-state-israa-12345"
    key            = "devops-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
