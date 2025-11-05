terraform {
  required_providers {
    company = {
      source = "yourcompany/company"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

provider "company" {
  cmdb_endpoint = "https://cmdb.company.com"
  cmdb_token    = var.cmdb_token
}

# Name generieren
data "company_naming" "webapp" {
  environment = "prod"
  application = "webapp"
  instance    = "001"
  region      = "eu"
}

# CMDB Eintrag erstellen
resource "company_cmdb_entry" "webapp" {
  name        = data.company_naming.webapp.vm_name
  environment = "prod"
  application = "webapp"
}

# VM erstellen
resource "vsphere_virtual_machine" "webapp" {
  name = data.company_naming.webapp.vm_name

  # ... weitere vSphere Konfiguration

  depends_on = [company_cmdb_entry.webapp]
}

output "vm_name" {
  value = data.company_naming.webapp.vm_name
}
