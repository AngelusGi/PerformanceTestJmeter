data "azurerm_container_registry" "jmeter_acr" {
  name                = var.JMETER_ACR_NAME
  resource_group_name = var.JMETER_ACR_RESOURCE_GROUP_NAME
}

# data "azurerm_resource_group" "jmeter_rg" {
#   name = var.RESOURCE_GROUP_NAME
# }

resource "azurerm_resource_group" "jmeter_rg" {
  name     = "pt${var.PROJECT}iot-rg"
  location = var.LOCATION
}

############################ Import data from first deployment

data "azurerm_client_config" "current" {
}

resource "azurerm_role_assignment" "storge_blob_owner" {
  scope                = azurerm_storage_account.jmeter_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# data "azurerm_storage_share" "jmeter_share" {
#   name                 = "jmeter"
#   storage_account_name = data.azurerm_storage_account.jmeter_storage.name
# }

resource "azurerm_storage_share" "jmeter_share" {
  name                 = "jmeter"
  storage_account_name = azurerm_storage_account.jmeter_storage.name
  quota                = var.JMETER_STORAGE_QUOTA_GIGABYTES
}

resource "random_id" "random" {
  byte_length = 4
}

############################ Dedicated subnet for Project RG

data "azurerm_subnet" "dedicated_subnet" {
  name                 = var.PERFORMANCE_TEST_SUBNET
  virtual_network_name = var.PERFORMANCE_TEST_VNET
  resource_group_name  = var.PERFORMANCE_TEST_VNET_RESOURCE_GROUP
}

# data "azurerm_storage_account" "jmeter_storage" {
#   name                = var.STORAGE_ACCOUNT_NAME
#   resource_group_name = data.azurerm_resource_group.jmeter_rg.name
# }

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

resource "azurerm_network_profile" "jmeter_net_profile" {
  name                = "${var.PREFIX}netprofile"
  location            = data.azurerm_container_registry.jmeter_acr.location
  resource_group_name = azurerm_resource_group.jmeter_rg.name

  container_network_interface {
    name = "${var.PREFIX}cnic"

    ip_configuration {
      name      = "${var.PREFIX}ipconfig"
      subnet_id = data.azurerm_subnet.dedicated_subnet.id
    }
  }
}

resource "azurerm_container_group" "jmeter_workers" {
  count               = var.JMETER_WORKERS_COUNT
  name                = "${var.PREFIX}-worker${count.index}"
  location            = data.azurerm_container_registry.jmeter_acr.location
  resource_group_name = azurerm_resource_group.jmeter_rg.name

  ip_address_type = "Private"
  os_type         = "Linux"

  restart_policy = "Never"
  
  network_profile_id = azurerm_network_profile.jmeter_net_profile.id

  image_registry_credential {
    server   = data.azurerm_container_registry.jmeter_acr.login_server
    username = data.azurerm_container_registry.jmeter_acr.admin_username
    password = data.azurerm_container_registry.jmeter_acr.admin_password
  }

  container {
    name   = "jmeter"
    image  = var.JMETER_DOCKER_IMAGE
    cpu    = var.JMETER_WORKER_CPU
    memory = var.JMETER_WORKER_MEMORY
    
    ports {
      port     = var.JMETER_DOCKER_PORT
      protocol = "TCP"
    }

    volume {
      name                 = "jmeter"
      mount_path           = var.JMETER_MOUNT_PATH
      read_only            = true
      storage_account_name = azurerm_storage_account.jmeter_storage.name
      # storage_account_key  = data.azurerm_storage_account.jmeter_storage.primary_access_key
      storage_account_key = azurerm_storage_account.jmeter_storage.secondary_access_key
      share_name          = var.SHARE_NAME
    }

    commands = [
      "/bin/sh",
      "-c",
      "cp -r /jmeter/* .; /entrypoint.sh -s -J server.rmi.ssl.disable=true -Djava.rmi.server.hostname=$(ifconfig eth0 | grep 'inet addr:' | awk '{gsub(\"addr:\", \"\"); print $2}')",
    ]

  }

}

resource "azurerm_container_group" "jmeter_controller" {
  name                = "${var.PREFIX}-controller"
  location            = data.azurerm_container_registry.jmeter_acr.location
  resource_group_name = azurerm_resource_group.jmeter_rg.name

  ip_address_type = "Private"
  os_type         = "Linux"

  network_profile_id = azurerm_network_profile.jmeter_net_profile.id

  restart_policy = "Never"

  image_registry_credential {
    server   = data.azurerm_container_registry.jmeter_acr.login_server
    username = data.azurerm_container_registry.jmeter_acr.admin_username
    password = data.azurerm_container_registry.jmeter_acr.admin_password
  }

  container {
    name   = "jmeter"
    image  = var.JMETER_DOCKER_IMAGE
    cpu    = var.JMETER_CONTROLLER_CPU
    memory = var.JMETER_CONTROLLER_MEMORY

    ports {
      port     = var.JMETER_DOCKER_PORT
      protocol = "TCP"
    }

    volume {
      name                 = "jmeter"
      mount_path           = var.JMETER_MOUNT_PATH
      read_only            = false
      storage_account_name = azurerm_storage_account.jmeter_storage.name
      # storage_account_key  = data.azurerm_storage_account.jmeter_storage.primary_access_key
      storage_account_key = azurerm_storage_account.jmeter_storage.secondary_access_key
      share_name          = var.SHARE_NAME
    }

    commands = [
      "/bin/sh",
      "-c",
      "cd /jmeter; /entrypoint.sh -n -J server.rmi.ssl.disable=true -t ${var.JMETER_JMX_FILE} -l ${var.JMETER_RESULTS_FILE} -e -o ${var.JMETER_DASHBOARD_FOLDER} -R ${join(",", "${azurerm_container_group.jmeter_workers.*.ip_address}")}",
    ]
  }
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
  expiry = timeadd(timestamp(), "12h")

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
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
