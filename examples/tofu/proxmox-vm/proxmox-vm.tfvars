env     = "dev"
app     = "tofu-vm"
pool_id = "example-tofu-pool"
network_config = {
    type        = "static"
    ip_address  = "192.168.1.33"
    cidr        = 24
    gateway     = "192.168.1.1"
}
