# demo-policy.hcl 
path "kvAgentDemo/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}
