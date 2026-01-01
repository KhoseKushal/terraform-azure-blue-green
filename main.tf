resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

data "local_file" "ssh_key" {
  filename = "C:/Users/kushal/.ssh/id_rsa.pub"
}

#vnet
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}

#nsg
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#associate nsg with subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#public ip
resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#lb
resource "azurerm_lb" "lb" {
  name                = var.lb_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.frontend_ip_name
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

#backend pool blue and green
resource "azurerm_lb_backend_address_pool" "blue_pool" {
  name            = var.blue_backend_pool_name
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_backend_address_pool" "green_pool" {
  name            = var.green_backend_pool_name
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "http_probe" {
  name                = var.health_probe_name
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# change blue <---> green
resource "azurerm_lb_rule" "http_rule" {
  name                           = var.lb_rule_name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.frontend_ip_name

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.green_pool.id
  ]

  probe_id = azurerm_lb_probe.http_probe.id
}

#nic
resource "azurerm_network_interface" "blue_nic" {
  name                = "nic-blue"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "green_nic" {
  name                = "nic-green"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

#vm blue
resource "azurerm_linux_virtual_machine" "blue_vm" {
  name                = "vm-blue"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.blue_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.local_file.ssh_key.content
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




  custom_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install nginx -y
echo "<h1>BLUE ENVIRONMENT</h1>" > /var/www/html/index.html
systemctl restart nginx
EOF
  )
}


#vm green
resource "azurerm_linux_virtual_machine" "green_vm" {
  name                = "vm-green"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.green_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.local_file.ssh_key.content
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

  custom_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install nginx -y
echo "<h1>GREEN ENVIRONMENT</h1>" > /var/www/html/index.html
systemctl restart nginx
EOF
  )
}


# Attach BLUE VM NIC to BLUE backend pool
resource "azurerm_network_interface_backend_address_pool_association" "blue_assoc" {
  network_interface_id    = azurerm_network_interface.blue_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.blue_pool.id
}

# Attach GREEN VM NIC to GREEN backend pool
resource "azurerm_network_interface_backend_address_pool_association" "green_assoc" {
  network_interface_id    = azurerm_network_interface.green_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.green_pool.id
}



