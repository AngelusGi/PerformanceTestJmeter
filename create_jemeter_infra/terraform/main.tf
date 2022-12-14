
data "azurerm_subnet" "agent_pool_subnet" {
  name                 = var.DEVOPS_TEAM_SUBNET
  virtual_network_name = var.DEVOPS_TEAM_VNET
  resource_group_name  = var.DEVOPS_TEAM_RESOURCE_GROUP
}

############################ Dedicated subnet for Project RG

data "azurerm_subnet" "dedicated_subnet" {
  name                 = var.PERFORMANCE_TEST_SUBNET
  virtual_network_name = var.PERFORMANCE_TEST_VNET
  resource_group_name  = var.PERFORMANCE_TEST_VNET_RESOURCE_GROUP
}

############################ Project RG

resource "azurerm_resource_group" "jmeter_rg" {
  name     = "pt${var.PROJECT}iot-rg"
  location = var.LOCATION
}


resource "random_id" "random" {
  byte_length = 4
}

data "azurerm_client_config" "current" {
}

/*
resource "azurerm_network_profile" "jmeter_net_profile" {
  name                = "${var.PREFIX}netprofile"
  location            = azurerm_resource_group.jmeter_rg.location
  resource_group_name = azurerm_resource_group.jmeter_rg.name

  container_network_interface {
    name = "${var.PREFIX}cnic"

    ip_configuration {
      name      = "${var.PREFIX}ipconfig"
      subnet_id = azurerm_subnet.jmeter_subnet.id
    }
  }
}
*/
resource "azurerm_storage_account" "jmeter_storage" {
  name                     = "pt${lower(var.PROJECT)}iot${random_id.random.hex}"
  resource_group_name      = azurerm_resource_group.jmeter_rg.name
  location                 = azurerm_resource_group.jmeter_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
  is_hns_enabled           = false
  /*
  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    virtual_network_subnet_ids = [data.azurerm_subnet.dedicated_subnet.id,data.azurerm_subnet.agent_pool_subnet.id]
  }
  */
}

resource "azurerm_role_assignment" "storge_blob_owner" {
  scope                = azurerm_storage_account.jmeter_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_share" "jmeter_share" {
  name                 = "jmeter"
  storage_account_name = azurerm_storage_account.jmeter_storage.name
  quota                = var.JMETER_STORAGE_QUOTA_GIGABYTES
}

data "azurerm_storage_account_sas" "jmeter_sas" {
  connection_string = azurerm_storage_account.jmeter_storage.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = false
    queue = false
    table = false
    file  = true
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "30m")

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = false
    tag     = false
    filter  = false
  }
}

data "azuredevops_project" "target" {
  name = var.PROJECT
}

resource "azuredevops_variable_group" "target_library" {

  depends_on = [
    azurerm_storage_account.jmeter_storage
  ]

  project_id   = data.azuredevops_project.target.id
  name         = "${var.PROJECT}-Secret-PerformanceTest-StorageAccount"
  description  = "${var.PROJECT}-Secret-PerformanceTest-StorageAccount-Description"
  allow_access = true

  variable {
    name         = "fileStorageUrl"
    secret_value = azurerm_storage_share.jmeter_share.url
    is_secret    = true
  }

  variable {
    name         = "fileStorageSAS"
    secret_value = data.azurerm_storage_account_sas.jmeter_sas.sas
    is_secret    = true
  }
}

# data "azuredevops_project" "admin" {
#   name = "AZU1730"
# }

# data "azuredevops_variable_group" "admin" {
#   project_id = data.azuredevops_project.admin.id
#   name       = "AZU1730-Secret-PerformanceTest-StorageAccount"
# }

# resource "azuredevops_variable_group" "admin" {
#   project_id = data.azuredevops_project.admin.id
#   name       = data.azuredevops_variable_group.admin.name

#   variable {
#     name      = "${var.PROJECT}-fileStorageUrl"
#     value     = azurerm_storage_account.jmeter_storage.primary_file_endpoint
#     is_secret = false
#     # is_secret = true
#   }

#   variable {
#     name         = "${var.PROJECT}-fileStorageSAS"
#     secret_value = azurerm_storage_account.jmeter_storage.primary_access_key
#     is_secret    = false
#     # is_secret    = true
#   }
# }
