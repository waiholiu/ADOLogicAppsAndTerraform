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
    storage_account_name = "tfstateapidemo"
    container_name       = "tfstatelogicapps"
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

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_storage_account" "newstorageacc" {
  name                     = "todellareadsa"
  resource_group_name      = azurerm_resource_group.logic_app_rg.name
  location                 = azurerm_resource_group.logic_app_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "files" {
  name                  = "files"
  storage_account_name  = azurerm_storage_account.newstorageacc.name
  container_access_type = "private"
}

data "azurerm_builtin_role_definition" "blob_contributor" {
  name = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_storage_account.newstorageacc.id
  role_definition_name = data.azurerm_builtin_role_definition.blob_contributor.name
  principal_id         = azurerm_logic_app_standard.example.identity[0].principal_id
}