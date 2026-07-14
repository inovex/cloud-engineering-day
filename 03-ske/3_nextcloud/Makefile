# Also consider using helmfile instead of this Makefile

RELEASE ?= nextcloud
NS      ?= nextcloud
CHART   ?= nextcloud/nextcloud
VALUES  ?= -f values.yaml

##@ Helm targets

.PHONY: install
install: ## Run the helm installation or make an upgrade
	helm repo add nextcloud https://nextcloud.github.io/helm/
	helm repo update
	helm upgrade --install $(RELEASE) $(CHART) -n $(NS) --create-namespace \
	$(VALUES) --wait
	
.PHONY: template
template: ## see the k8s resources which helm composes (local dry run)
	helm template $(RELEASE) --namespace $(NS) $(CHART) $(VALUES)

.PHONY: dry
dry: ## Dry run involving remote
	helm upgrade --install $(RELEASE) $(CHART) -n $(NS) $(VALUES) \
	--dry-run --debug

.PHONY: uninstall
uninstall: ## Delete deployment. Make sure you wait until the pods really terminated.
	helm uninstall $(RELEASE) -n $(NS) --wait
	
.PHONY: diff
diff: ## preview changes
	helm diff upgrade $(RELEASE) $(CHART) -n $(NS)  $(VALUES)

.PHONY: status
status:
	helm status $(RELEASE) -n $(NS)
	
##@ Plumbing

values.yaml: ## Copy the values.yaml prepared by terraform
	cp ../1_alloc/generated/nextcloud_chart_values.yml values.yaml

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
