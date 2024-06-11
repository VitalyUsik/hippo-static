terraform {
  backend "s3" {
    bucket         = "477911757103-hellohippo-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "sa-east-1"
    dynamodb_table = "terraform-locks"
  }
}
