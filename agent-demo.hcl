# Vault Agent syntax supports HashiCorp HCL comments,
// meaning you can mix #, // and 
/* block comments
   like this */
# 
# 

# This is the path to store a PID file which will contain the process ID of the
# Vault agent process. This is useful if you plan to send custom signals
# to the process. 
pid_file = "./pidfile"

#
exit_after_auth = true

# Define the connection to the Vault cluster
vault {

  # define the connection to Vault
  # Setting here will override VAULT_ADDR env var
  # address = "http://ec2-123-16-50-115.us-east-2.compute.amazonaws.com:8200"

  retry {
    # Note that Vault Agent does *NOT* support the retry block from Consul template,
    # which are found here 
    # https://github.com/hashicorp/consul-template#templating-language  
    # see https://github.com/hashicorp/vault/issues/6001
    #    enabled = false
    #    attempts = 2
    #    backoff = "5s"
    #    max_backoff = "60s"
  }
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

# If cache and listener is not used, a sink file must be created. 
# However, it is not recommended to leave this file for security concerns. 
#
#  sink {
#    type = "file"

#    config = {
#      path = "sink_file.txt"
#    }
#  }

}

# this is a workaround to not write a sink file containing 
# a token file that could be a security risk
#
listener "unix" {
         address = "foo.txt"
         tls_disable = true
}

cache {
  use_auto_auth_token = true
}

# template stanza documentation is the same as Consul template, see
# https://www.vaultproject.io/docs/agent/template/#configuration

template {
  source      = "template.ctmpl"
  destination = "render.txt"
  backup      = true
  error_on_missing_key = false

# Wait is included here for syntax only, since we don't have a
# command defined to execute after an update, it is ignored
# Wait is the min/mnax times to wait before rendering a new template to
# disk and triggering a command

  wait {
    min = "30s"
    max = "60s"
  }

}