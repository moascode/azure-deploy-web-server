#Create a public IP address to allow load balancer to be accessed over the internet
resource "azurerm_public_ip" "publicip_lb" {
  name                = "${var.prefix}-pip-lb"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags                = var.tags
}

#Create a load balancer to distribute incoming network traffic across multiple VMs
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "${var.prefix}-lb-fip"
    public_ip_address_id = azurerm_public_ip.publicip_lb.id
  }
}

#Create a backend address pool for load balancer to forward traffic to vm network interfaces
resource "azurerm_lb_backend_address_pool" "lb_backend" {
  name                = "${var.prefix}-lb-backend"
  loadbalancer_id     = azurerm_lb.lb.id
}

#Add load balancer rule to allow http traffic to be distributed across the pools
resource "azurerm_lb_nat_rule" "lb_rule_http" {
  count                          = var.vm_count
  name                           = "${var.prefix}-lb-rule-http-${count.index}"
  resource_group_name            = data.azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = "80${count.index}"
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.prefix}-lb-fip"
}

#Add load balancer health probe to monitor the health of the resources in the pool
resource "azurerm_lb_probe" "lb_probe_http" {
  name                = "${var.prefix}-lb-probe-http"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

#Link loadbalancer's backend address pool to network interfaces
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  count                   = var.vm_count
  network_interface_id    = element(azurerm_network_interface.nic.*.id, count.index)
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend.id
  ip_configuration_name   = "${var.prefix}-subnet-${count.index}"
}

#Link loadbalancer's NAT rule to network interfaces to allow interfaces use the rule for traffic
resource "azurerm_network_interface_nat_rule_association" "nic_lb_http" {
  count                 = var.vm_count
  network_interface_id  = element(azurerm_network_interface.nic.*.id, count.index)
  nat_rule_id           = element(azurerm_lb_nat_rule.lb_rule_http.*.id, count.index)
  ip_configuration_name = "${var.prefix}-subnet-${count.index}"
}