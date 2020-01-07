# Vault Agent demo

Purpose: This repo was created to demo how Vault Agent can read a simple KV secret, populate a config sinple file, and maybe more as we get into it. 

Future versions of this might include:
* Inject variables into a complex config file, not just one we create
* Run commands after a new KV is found
* Documentation updates to the Vault docs about how KV TTLs and why KVs are not updated in real time or at their TTL expiration (see https://github.com/hashicorp/consul-template/blob/db8385207eb1ed69bf25172373a227d0a1e82342/dependency/vault_common.go#L152)

### Prerequisites

* Vault environment. This can be a single Vault instance or a cluster. 
* This guide will get you started with a 3-node cluster running raft/integrated storage:
    * https://github.com/hashicorp/vault-guides/tree/master/operations/raft-storage
* Vault binary 1.3.x (or later, this guide was authored with 1.3.1) in path

### Environment Prep

* Config/connect to your environment, Vault UI, firewall rules, login, etc so that `vault status` returns an unsealed vaulting vault
	* `$ export VAULT_ADDR=http://ec2-123-221-82-51.us-east.compute.amazonaws.com:8200`
	* `$ vault status`
	* `$ vault login s.token_here`
* Enable approle auth method
	* `$ vault auth enable approle`
	* Returns: `Success! Enabled approle auth method at: approle/`
* Enable a new KV (version 2) secrets engine at kvAgentDemo:
	```
	vault secrets enable -path=kvAgentDemo -version=2 kv
	Success! Enabled the kv secrets engine at: kvAgentDemo/
	```
* Write and verify the new KV:
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
* Create a policy for the approle to use
* Create a role ID and get the secret ID for that role
* Create policy demo-policy from demo-policy.hcl file
	```
	$ vault policy write demo-policy demo-policy.hcl
	Success! Uploaded policy: demo-policy
	```
* Create approle role
	```
	$ vault write auth/approle/role/agentdemo policies="demo-policy"
	Success! Data written to: auth/approle/role/agentdemo
	```
* Get role ID for new approle role
    ```
    $ vault read auth/approle/role/agentdemo/role-id
	role_id    ffcfd009-86e0-5c11-e85f-lee78310ee0cd
	```
* Create a secret ID for the role
	```
	$ vault write -f auth/approle/role/agentdemo/secret-id
	Key                   Value
	---                   -----
	secret_id             62a9b134-cd6d-cc77-909e-0a6a4c0289e6
	secret_id_accessor    3a1670da-4811-b9ca-acba-bafdf6c7925b
	```
* Setup sample data (single KV is already inserted above) 
* Review the template file
    * Any metadata can be used - for example, see KV2 metadata here:
    https://www.vaultproject.io/docs/secrets/kv/kv-v2.html#key-metadata
* Run vault agent

	`$ vault agent -config=agent-demo.hcl`



make agent-demo.hcl

to run agent:
./vault agent -config=agent-demo.hcl
Note this deletes the secretid file on startup! Will make a new one each time you start this. 

this puts a sink-file with a token
need to make this drop a user/pass KV set

