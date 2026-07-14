# Wraps the most common Terraform commands so you don't have to remember the flags.

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: init validate plan apply output destroy

init: ## Download providers and modules (first time only)
	terraform init

validate: init ## Check configuration files for syntax errors.
	terraform validate

plan: validate ## Preview what Terraform will create/change/destroy
	terraform plan

apply: ## Apply the plan and provision all resources (can take a while during the first run)
	terraform apply

output: ## Show the generated outputs after a successful apply. The generated/ directory also contains human-readable files for downstream steps.
	terraform output -json

destroy: ## Tear down all managed resources
	terraform destroy -auto-approve
