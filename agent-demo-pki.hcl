# agent-demo-pki.hcl

# Define the connection to the Vault cluster
vault {
  # Setting here will override VAULT_ADDR env var
  # address = "http://ec2-123-16-50-115.us-east-2.compute.amazonaws.com:8200"
}

auto_auth {
  method {
    type      = "approle"

    config = {
      role_id_file_path = "roleid"
      secret_id_file_path = "secretid"
      remove_secret_id_file_after_reading = false
    }
  }
}

template {
  source      = "template-pki.ctmpl"
  destination = "render-pki.txt"
  backup      = true
  error_on_missing_key = false
}

template {
  source      = "template-pki-key.ctmpl"
  destination = "render-pki.key"
  backup      = false
  error_on_missing_key = false
}
