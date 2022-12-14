output "STORAGE_ACCOUNT_NAME" {
  value = azurerm_storage_account.jmeter_storage.name
  sensitive = false
}

# output "STORAGE_PRIMARY_KEY" {
#   value = azurerm_storage_account.jmeter_storage.primary_access_key
#   sensitive = true
# }

# output "STORAGE_NFS_URL" {
#   value = azurerm_storage_account.jmeter_storage.primary_file_endpoint
#   sensitive = true
# }

output "RESOURCE_GROUP_NAME" {
  value = azurerm_resource_group.jmeter_rg.name
  sensitive = true
}
