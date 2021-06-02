# demo-policy.hcl 
path "kvAgentDemo/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}

path "pki-agent/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}
