// resource_prefix generates names for all resources
resource_prefix = "vm-example"

// tags are applied to all deployed resources
tags = {
  Purpose     = "VM Example"
  Environment = "Proof of Concept"
}

// vm_public_access provides a public IP address with the created virtual machines
vm_public_access = true
