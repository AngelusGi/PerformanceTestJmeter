terraform {
    backend "azurerm" {
        storage_account_name    = "chronstorage "
        container_name          = "perfomancetest"
        key                     = var.tfstate
    }
}