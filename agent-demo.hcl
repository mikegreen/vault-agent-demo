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

# https://www.vaultproject.io/docs/agent/index.html#exit_after_auth
# If set to true, the agent will exit with code 0 after a single successful
# auth, where success means that a token was retrieved and all sinks
# successfully wrote it
exit_after_auth = false

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
  # Comment out the sink stanza below to not generate the file
    sink {
      type = "file"
      wrap_ttl = "30m"
      config = {
        path = "sink_file_wrapped_1.txt"
      }
    }

    sink {
      type = "file"
      config = {
        path = "sink_file_unwrapped_2.txt"
      }
    }

    # Encrypted Token example
    # TODO Need to improve documentation on Curve 25591 encryption and how this workflow works
    # sink {
    #  type = "file"
    #  dh_type = "curve25519"
    #  dh_path = "test_ed25591_key.pub"
    #  config = {
    #    path = "sink_file_encrypted_1.txt"
    #  }
    # }    

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

# Caching testing below
listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = true
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