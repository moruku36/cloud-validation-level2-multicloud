resource "azurerm_network_interface" "web" {
  for_each = var.vm_zones

  name                = "nic-${local.name_prefix}-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "web" {
  for_each = azurerm_network_interface.web

  network_interface_id    = each.value.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = one(azurerm_application_gateway.web.backend_address_pool[*].id)
}

resource "azurerm_linux_virtual_machine" "web" {
  for_each = var.vm_zones

  name                            = "vm-${local.name_prefix}-${each.key}"
  computer_name                   = "${local.name_prefix}-${each.key}"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  zone                            = each.value
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web[each.key].id]
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    server_name = "${local.name_prefix}-${each.key}"
  }))
  tags = local.common_tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = trimspace(var.admin_ssh_public_key)
  }

  os_disk {
    name                 = "osdisk-${local.name_prefix}-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {}

  depends_on = [
    azurerm_nat_gateway_public_ip_association.backend,
    azurerm_subnet_nat_gateway_association.backend,
    azurerm_subnet_network_security_group_association.backend,
  ]
}

