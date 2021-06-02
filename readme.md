# Vault Agent demo

Purpose: This repo was created to demo how [Vault Agent](https://www.vaultproject.io/docs/agent) can read a simple KV secret, populate a config simple file, and maybe more as we get into it. 
If you are looking for a more verbose tutorial, the HashiCorp Learn site has one here https://learn.hashicorp.com/vault/identity-access-management/agent-templates


Future versions of this might include:
* Inject variables into a complex config file, not just one we create
* Run commands after a new KV is found, ie, update a config file and restart a service
* Documentation updates to the Vault docs about how KV TTLs and why KVs are not updated in real time or at their TTL expiration (see https://github.com/hashicorp/consul-template/blob/db8385207eb1ed69bf25172373a227d0a1e82342/dependency/vault_common.go#L152)

### Prerequisites

* Vault environment. This can be a single Vault instance or a cluster. 
* This guide will get you started with a 3-node cluster running raft/integrated storage:
    * https://github.com/hashicorp/vault-guides/tree/master/operations/raft-storage
* Vault binary 1.3.x (or later, this guide was authored with 1.3.1) in path

### Environment Prep

1. Config/connect to your environment, Vault UI, firewall rules, login, etc so that `vault status` returns an unsealed vaulting vault
	* `$ export VAULT_ADDR=http://ec2-123-221-82-51.us-east.compute.amazonaws.com:8200`
	* `$ vault status`
	* `$ vault login s.token_here`
1. Enable approle auth method
	* `$ vault auth enable approle`
	* Returns: `Success! Enabled approle auth method at: approle/`
1. Enable a new KV (version 2) secrets engine at kvAgentDemo:
	```
	vault secrets enable -path=kvAgentDemo -version=2 kv
	Success! Enabled the kv secrets engine at: kvAgentDemo/
	```
1. Write and verify the new KV:
	```
	$ vault kv put /kvAgentDemo/legacy_app_creds_01 username=legacyUser password=supersecret
	Key              Value
	---              -----
	created_time     2020-01-07T21:42:08.288139501Z
	deletion_time    n/a
	destroyed        false
	version          1

	$ vault kv get /kvAgentDemo/legacy_app_creds_01
	====== Metadata ======
	Key              Value
	---              -----
	created_time     2020-01-07T21:42:08.288139501Z
	deletion_time    n/a
	destroyed        false
	version          1

	====== Data ======
	Key         Value
	---         -----
	password    supersecret
	username    legacyUser
	```
1. Create policy demo-policy from demo-policy.hcl file. This policy gives permissions on kvAgentDemo/*, see file for details.
	```
	$ vault policy write demo-policy demo-policy.hcl
	Success! Uploaded policy: demo-policy
	```
1. Create [approle](https://www.vaultproject.io/docs/auth/approle.html) role
	```
	$ vault write auth/approle/role/agentdemo policies="demo-policy"
	Success! Data written to: auth/approle/role/agentdemo
	```
1. Get role ID for new approle role
    ```
    $ vault read auth/approle/role/agentdemo/role-id
	role_id    ffcfd009-86e0-5c11-e85f-lee78310ee0cd
	```
	Make a new file `roleid` (in repo folder) that contains only the role_id UUID returned above

1. Create a secret ID for the role
	```
	$ vault write -f auth/approle/role/agentdemo/secret-id
	Key                   Value
	---                   -----
	secret_id             62a9b134-cd6d-cc77-909e-0a6a4c0289e6
	secret_id_accessor    3a1670da-4811-b9ca-acba-bafdf6c7925b
	```
	Make a new file `secretid` (in repo folder) that contains only the secret_id UUID returned above

	* Note, the secret ID that is read as part of the auth_auth config stanza,
	```
	    config = {
      		role_id_file_path = "roleid"
      		secret_id_file_path = "secretid"
      		remove_secret_id_file_after_reading = false
    ```
    defaults to removing the file at the secred_id_file_path (remove_secret_id_file_after_reading = true). 
    In this example we have set this to false to keep the secret ID in the filesystem. In the real world, 
    this should be a consideration and a security concern for both keeping this file and permissions of it.

1. Review the [template.ctmpl](../master/template.ctmpl) file. This file defines the output that will be rendered. 
    * [Template syntax](https://www.vaultproject.io/docs/agent/template/index.html#configuration) for further use cases
    * Vault agent template follows [Consul template](https://github.com/hashicorp/consul-template) syntax
    * Any metadata can be used - for example, see KV2 metadata here:
    https://www.vaultproject.io/docs/secrets/kv/kv-v2.html#key-metadata

## Running the demo

1.  Run vault agent

    ```
    $ vault agent -config=agent-demo.hcl
	==> Vault server started! Log data will stream in below:

	==> Vault agent configuration:

	           Api Address 1: unix://foo.txt
	                     Cgo: disabled
	               Log Level: info
	                 Version: Vault v1.3.1

	2020-01-17T08:16:33.144-0700 [INFO]  sink.file: creating file sink
	2020-01-17T08:16:33.144-0700 [INFO]  sink.file: file sink configured: path=sink_file.txt mode=-rw-r-----
	2020-01-17T08:16:33.144-0700 [INFO]  auth.handler: starting auth handler
	2020-01-17T08:16:33.144-0700 [INFO]  auth.handler: authenticating
	2020-01-17T08:16:33.144-0700 [INFO]  sink.server: starting sink server
	2020-01-17T08:16:33.144-0700 [INFO]  template.server: starting template server
	2020/01/17 15:16:33.147270 [INFO] (runner) creating new runner (dry: false, once: false)
	2020/01/17 15:16:33.147621 [INFO] (runner) creating watcher
	2020-01-17T08:16:33.262-0700 [INFO]  auth.handler: authentication successful, sending token to sinks
	2020-01-17T08:16:33.262-0700 [INFO]  auth.handler: starting renewal process
	2020-01-17T08:16:33.262-0700 [INFO]  template.server: template server received new token
	2020/01/17 15:16:33.262450 [INFO] (runner) stopping
	2020/01/17 15:16:33.262475 [INFO] (runner) creating new runner (dry: false, once: false)
	2020/01/17 15:16:33.262555 [INFO] (runner) creating watcher
	2020/01/17 15:16:33.262671 [INFO] (runner) starting
	2020-01-17T08:16:33.262-0700 [INFO]  sink.file: token written: path=sink_file.txt
	2020-01-17T08:16:33.362-0700 [INFO]  auth.handler: renewed auth token
	2020/01/17 15:16:33.457677 [INFO] (runner) rendered "template.ctmpl" => "render.txt"
    ```

    This results in a render.txt file being created, with the contents (based on [template.ctmpl](../blob/master/template.ctmpl).
    ```
    Username: legacyUser
	Password: supersecret
	Create TS: 2020-01-17T15:16:27.215746404Z
	 Version: 9

	All raw metadata: map[data:map[password:supersecret4 username:legacyUser] metadata:map[created_time:2020-01-17T15:16:27.215746404Z deletion_time: destroyed:false version:9]]
    ```
1. The agent will continue to run and update the render.txt, to use in scripts or single-use upon startup requiring run once and exit, set `exit_after_auth` true.  Note, KV values are not updated in real time but on a random timer from 1-5 minutes. GH issue will be linked here once created. 

1. If your use case does not need a token to interact with Vault, now would be a good time to remove the `sink` stanza from the agent-demo.hcl file.
   Note: A sink file or listener must be enabled with auto_auth. This requirement will soon be removed, see https://github.com/hashicorp/vault/issues/7988 and https://github.com/hashicorp/vault/tree/template-sinkless

## Use Vault to generate a PKI certificate and save to a file

1. Setup [PKI secrets engine](https://www.vaultproject.io/docs/secrets/pki)
   ```language
   $ vault secrets enable -path=pki-agent pki
   Success! Enabled the pki secrets engine at: pki-agent/
   
   $ vault write pki-agent/root/generate/internal common_name=my.hashicorpdemo.com ttl=24h
	Key              Value
	---              -----
	certificate      -----BEGIN CERTIFICATE-----
	MIIDUj...
	-----END CERTIFICATE-----
	expiration       1622748662
	issuing_ca       -----BEGIN CERTIFICATE-----
	MIIDUjC...
	-----END CERTIFICATE-----
	serial_number    3b:8a:13:04:8c:ab:74:ee:65:3c:f6:66:51:52:ed:fa:65:60:c1:6e

	$ vault write pki-agent/roles/dev-dot-com allowed_domains=hashicorpdemo.com allow_subdomains=true
	Success! Data written to: pki-agent/roles/dev-dot-com

	$ vault write pki-agent/issue/dev-dot-com common_name=dev.hashicorpdemo.com ttl=1h
	Key                 Value
	---                 -----
	certificate         -----BEGIN CERTIFICATE-----
	MIIDYjC...
	OlaS++YZ
	-----END CERTIFICATE-----
	expiration          1622666066
	issuing_ca          -----BEGIN CERTIFICATE-----
	MIIDUjC...
	-----END CERTIFICATE-----
	private_key         -----BEGIN RSA PRIVATE KEY-----
	MIIEpQI...
	-----END RSA PRIVATE KEY-----
	private_key_type    rsa
	serial_number       35:da:a9:1c:ba:35:bb:56:2c:b7:df:d7:6e:11:4b:b8:f9:c7:6a:ce

   ```

1. Run vault agent `$ vault agent --config=agent-demo-pki.hcl`

1. You'll see in the log output a file was created: `[INFO] (runner) rendered "template-pki.ctmpl" => "render-pki.txt"`

1. And the contents of the file should look like this example: [render-pki.example](./render-pki.example)

1. It is possible to have the template put the certificate, private and public keys in separate files. Possibility for improvement of this repo. 

