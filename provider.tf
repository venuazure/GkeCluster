terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  # Configuration options
  project     = "devops-dev-439108"
  credentials = file("D:/work/gkecluster/serviceaccount/devops-dev-439108-1bab0aba7605.json")
}