output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.main.workspace_url
}