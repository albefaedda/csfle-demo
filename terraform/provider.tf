terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.17.0"
    }
  }
}

provider "confluent" {}
