# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate12909"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "logic_app_rg" {
  name     = "todella-rg"
  location = "Australia East"
}

resource "azurerm_storage_account" "todellastorageacc" {
  name                     = "todellastorageacc"
  resource_group_name      = azurerm_resource_group.logic_app_rg.name
  location                 = azurerm_resource_group.logic_app_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# resource "azurerm_app_service_plan" "todellaasp" {
#   name                = "todellaasp"
#   location            = azurerm_resource_group.logic_app_rg.location
#   resource_group_name = azurerm_resource_group.logic_app_rg.name
#   kind                = "elastic"


#   sku {
#     tier = "WorkflowStandard"
#     size = "WS1"
#   }
# }

resource "azurerm_service_plan" "todellaasp" {
  name                = "todellaasp"
  resource_group_name = azurerm_resource_group.logic_app_rg.name
  location            = azurerm_resource_group.logic_app_rg.location
  os_type             = "Windows"
  sku_name            = "WS1"
}

resource "azurerm_logic_app_standard" "todellaasp" {
  name                       = "todellaasp"
  location                   = azurerm_resource_group.logic_app_rg.location
  resource_group_name        = azurerm_resource_group.logic_app_rg.name
  app_service_plan_id        = azurerm_service_plan.todellaasp.id
  storage_account_name       = azurerm_storage_account.todellastorageacc.name
  storage_account_access_key = azurerm_storage_account.todellastorageacc.primary_access_key
  version                    = "~4"

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
  }
}