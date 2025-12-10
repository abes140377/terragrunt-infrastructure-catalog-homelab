env     = "dev"
app     = "tofu-vm"
pool_id = "example-tofu-pool"
network_config = {
    type        = "static"
    ip_address  = "192.168.1.99"
    cidr        = 24
    gateway     = "192.168.1.1"
    dns_servers = ["192.168.1.13", "192.168.1.14"]
    domain      = "home.sflab.io"
}
