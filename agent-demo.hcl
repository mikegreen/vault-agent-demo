# Vault Agent syntax supports HashiCorp HCL comments,
// meaning you can mix #, // and 
/* block comments
   like this */

# This is the path to store a PID file which will contain the process ID of the
# Vault agent process. This is useful if you plan to send custom signals
# to the process. 
pid_file = "./pidfile"

# https://www.vaultproject.io/docs/agent/index.html#exit_after_auth
# If set to true, the agent will exit with code 0 after a single successful
# auth, where success means that a token was retrieved and all sinks
# successfully wrote it
exit_after_auth = false

vault {

  # See https://www.vaultproject.io/docs/agent#vault-stanza
  # address = "http://ec2-123-16-50-115.us-east-2.compute.amazonaws.com:8200"

  # See https://www.vaultproject.io/docs/agent#retry-stanza
  retry {
    num_retries = 5
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
  # Comment out the sink stanzas below to not generate the file
  
  # Create a text file containing a wrapped token
  # To use this token, unwrap with `$ VAULT_TOKEN=s.lTjQQHZWknFMkO190qZka5C8 vault unwrap`
    sink {
      type = "file"
      wrap_ttl = "30m"
      config = {
        path = "sink_file_wrapped_1.txt"
      }
    }

  # Create a text file containing a plain-text token
    sink {
      type = "file"
      config = {
        path = "sink_file_unwrapped_2.txt"
      }
    }

}

# this is a workaround to not write a sink file containing 
# a token file that could be a security risk
#
# listener "unix" {
#         address = "foo.txt"
#         tls_disable = true
#}

cache {
  use_auto_auth_token = true
}

# Create a local listener, this allows apps to use Vault locally without auth'ing on their own
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
  # Exit with an error when accessing a struct or map field/key that does not
  # exist. The default behavior will print "<no value>" when accessing a field
  # that does not exist. It is highly recommended you set this to "true" when
  # retrieving secrets from Vault.
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
