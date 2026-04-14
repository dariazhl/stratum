terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "rg-stratum-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
    project     = "stratum"
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_account" "datalake" {
  name                     = "ststratum${var.environment}${var.suffix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

resource "azurerm_databricks_workspace" "main" {
  name                = "dbw-stratum-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "premium"

  tags = azurerm_resource_group.main.tags
}

provider "databricks" {
  host = azurerm_databricks_workspace.main.workspace_url
}

resource "databricks_cluster_policy" "dev_policy" {
  name = "stratum-dev-policy"

  definition = jsonencode({
    "autotermination_minutes" = {
      "type"  = "fixed"
      "value" = 20
    }
    "num_workers" = {
      "type"     = "range"
      "minValue" = 1
      "maxValue" = 4
    }
    "node_type_id" = {
      "type"         = "allowlist"
      "values"       = ["Standard_DS3_v2", "Standard_DS4_v2"]
      "defaultValue" = "Standard_DS3_v2"
    }
  })
}