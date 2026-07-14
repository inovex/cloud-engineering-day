help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help install uninstall ui

SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

install: ## Install Grafana Alloy (applies secret.yaml first — fill in credentials before running)
	bash $(SCRIPT_DIR)01_install-alloy.sh

uninstall: ## Remove Grafana Alloy and the credentials Secret from the cluster
	helm uninstall alloy --namespace observability || true
	kubectl delete secret alloy-stackit-credentials --namespace observability || true

ui: ## Port-forward the Alloy debug UI to http://localhost:12345 (pick any running pod)
	kubectl port-forward -n observability \
	  $$(kubectl get pods -n observability -l app.kubernetes.io/name=alloy --no-headers | head -1 | awk '{print $$1}') \
	  12345:12345
