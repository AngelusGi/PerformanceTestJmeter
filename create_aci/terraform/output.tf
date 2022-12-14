output "JMETER_CONTROLLER_IP" {
  value = azurerm_container_group.jmeter_controller.ip_address
  sensitive = false
}

output "JMETER_CONTROLLER_NAME" {
  value = azurerm_container_group.jmeter_controller.name
  sensitive = false
}

output "PF_RESOURCE_GROUP_NAME" {
  value = azurerm_resource_group.jmeter_rg.name
  sensitive = false
}

output "JMETER_WORKER_IPS" {
  value = join(",", "${azurerm_container_group.jmeter_workers.*.ip_address}")
  sensitive = false
}

output "JMETER_RESULTS_FILE" {
  value = var.JMETER_RESULTS_FILE
  sensitive = false
}

output "JMETER_DASHBOARD_FOLDER" {
  value = var.JMETER_DASHBOARD_FOLDER
  sensitive = false
}
