# Vault Agent demo

Purpose: This repo was created to demo how Vault Agent can read a simple KV secret, populate a config sinple file, and maybe more as we get into it. 
Extendsion of this might include:
* Inject variables into a complex config file, not just one we create
* Run commands after a new KV is found
* Documentation updates to the Vault docs about how KV TTLs and why KVs are not updated in real time or at their TTL expiration (see https://github.com/hashicorp/consul-template/blob/db8385207eb1ed69bf25172373a227d0a1e82342/dependency/vault_common.go#L152)

### Prerequisites

* Vault environment. This can be a single Vault instance or a cluster. 
* TODO: Link existing guide on how to quickly setup a Vault cluster with integrated (raft) storage in AWS
* Vault binary 1.3.x (or later, this guide was authored with 1.3.1) in path

### Environment Prep

* Config/connect to your environment, Vault UI, firewall rules, login, etc so that `vault status` returns an unsealed vaulting vault
	* `export VAULT_ADDR=http://ec2-123-221-82-51.us-east.compute.amazonaws.com:8200`
	* `vault status`
	* `vault login s.token_here`
* Enable approle auth method
	* `vault auth enable approle`
	* Returns: `Success! Enabled approle auth method at: approle/`
* Enable the KV engine at TODO
* Create a policy for the approle to use
* Create a role ID and get the secret ID for that role
* Create policy all_secrets via UI:
```
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```
* Create approle role
	* `vault write auth/approle/role/agentdemo policies="all_secrets"`
	* Returns: `Success! Data written to: auth/approle/role/agentdemo`
* Get role ID for new approle role
	* `vault read auth/approle/role/agentdemo/role-id`
	* Returns key/value: `role_id    ffcfd009-86e0-5c11-e85f-lee78310ee0cd`
* Create a secret ID for the role
	* `vault write -f auth/approle/role/agentdemo/secret-id`
	* Returns:
```
Key                   Value
---                   -----
secret_id             12312344-306b-abcd-4fc6-bf6eddc4f9f8
secret_id_accessor    3a1670da-4811-b9ca-acba-bafdf6c7925b
```
* Setup sample data
	* Insert 

make agent-demo.hcl

to run agent:
./vault agent -config=agent-demo.hcl
Note this deletes the secretid file on startup! Will make a new one each time you start this. 

this puts a sink-file with a token
need to make this drop a user/pass KV set

