help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help install expose-ui credentials

SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

install: ## Install ArgoCD into the argocd namespace
	kubectl apply --server-side -k $(SCRIPT_DIR)argocd

expose-ui: ## Expose the ArgoCD UI via Traefik Ingress (requires DOMAIN to be set)
	bash $(SCRIPT_DIR)scripts/setup-ingress.sh

credentials: ## Print the initial admin credentials
	@echo "Username: admin"
	@echo "Password: $$(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	@echo ""
