terraform {
  required_version = ">= 1.3.3"
  required_providers {
    google = {
      version = "> 4.4"
      source  = "hashicorp/google"
    }
  }
}
