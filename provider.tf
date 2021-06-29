provider "aws" {
  region                  = "ap-south-1"
  profile                 = "terraform-profile"
}

provider "azurerm" {
  features {}
}