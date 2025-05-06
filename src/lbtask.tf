terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "3ac8ce2b-8fd7-49e2-9d67-4fd41c9f917f"
  tenant_id       = "9204a01a-986e-4144-9310-eed639cbcb65"
  client_id       = "de867ce5-77f3-4adb-84f4-883d30c55e5a"
  client_secret   = "MWc8Q~5gMqUVPBNI1nKKla8fqm3b5bAL3ayGPcE2"
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-3tier"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-3tier"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Subnets
resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]

    delegation {
    name = "postgresql-delegation"
    
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Public IP for Web Load Balancer
resource "azurerm_public_ip" "web" {
  name                = "web-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Web Load Balancer
resource "azurerm_lb" "web_lb" {
  name                = "web-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "web-frontend-ip"
    public_ip_address_id = azurerm_public_ip.web.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_pool" {
  name            = "web-backend-pool"
  loadbalancer_id = azurerm_lb.web_lb.id
}

resource "azurerm_lb_probe" "web_http_probe" {
  name                = "web-http-probe"
  loadbalancer_id     = azurerm_lb.web_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "web_http_rule" {
  name                           = "web-http-rule"
  loadbalancer_id                = azurerm_lb.web_lb.id
  frontend_ip_configuration_name = "web-frontend-ip"
  probe_id                       = azurerm_lb_probe.web_http_probe.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
}

# App Load Balancer (Internal)
resource "azurerm_lb" "app_lb" {
  name                = "app-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "app-frontend-ip"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "app_pool" {
  name            = "app-backend-pool"
  loadbalancer_id = azurerm_lb.app_lb.id
}

resource "azurerm_lb_probe" "app_http_probe" {
  name                = "app-http-probe"
  loadbalancer_id     = azurerm_lb.app_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "app_http_rule" {
  name                           = "app-http-rule"
  loadbalancer_id                = azurerm_lb.app_lb.id
  frontend_ip_configuration_name = "app-frontend-ip"
  probe_id                       = azurerm_lb_probe.app_http_probe.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 80
}

# Web NICs and VMs
resource "azurerm_network_interface" "web_nic" {
  count               = 2
  name                = "web-nic-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "web-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_linux_virtual_machine" "web_vm" {
  count               = 2
  name                = "web-vm-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.web_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/terraform_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# App NICs and VMs
resource "azurerm_network_interface" "app_nic" {
  count               = 2
  name                = "app-nic-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "app-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  count               = 2
  name                = "app-vm-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.app_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/terraform_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}
resource "azurerm_storage_account" "main" {
  name                     = "storageacct${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "random_string" "postgres_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "pg-flex-db-${random_string.postgres_suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "13"
  administrator_login    = "pgadmin"
  administrator_password = "SecureP@ssw0rd123!"
  sku_name               = "GP_Standard_D2s_v3"
  storage_mb             = 32768
  delegated_subnet_id    = azurerm_subnet.db.id
  zone                   = "1"
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id

  public_network_access_enabled = false

  high_availability {
    mode = "ZoneRedundant"
  }

  authentication {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.vnet_link]
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.main.name
}

 