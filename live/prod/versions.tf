terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.28.0"
    }
  }

  backend "s3" {
    bucket         = "so1s-terraform-remote-state-storage"
    region         = "ap-northeast-2"
    access_key     = "live/prod"
    dynamodb_table = "remote_state_locking"
    encrypt        = true
  }
}
