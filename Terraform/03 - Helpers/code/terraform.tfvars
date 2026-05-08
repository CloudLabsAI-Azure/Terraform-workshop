rg             = ""  # Enter your resource group name (e.g. "my-lab-rg")
location       = ""  # Enter your Azure region (e.g. "eastus", "westeurope")
admin_password = ""  # Set a strong VM admin password (min 12 chars)

security_group_rules = [
  {
    name                 = "http"
    priority             = 100
    protocol             = "tcp"
    destinationPortRange = "80"
    direction            = "Inbound"
    access               = "Allow"
  },
  {
    name                 = "https"
    priority             = 150
    protocol             = "tcp"
    destinationPortRange = "443"
    direction            = "Inbound"
    access               = "Allow"
  },
  {
    name                 = "deny-the-rest"
    priority             = 200
    protocol             = "*"
    destinationPortRange = "0-65535"
    direction            = "Inbound"
    access               = "Deny"
  },
]

tags = {
  environment = "lab"
  workshop    = "IaC-with-Terraform"
  year        = "2026"
}

