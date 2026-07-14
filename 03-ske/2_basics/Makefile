# Makefile for 2_basics — bootstrapping the empty Kubernetes cluster.
# Values consumed from Terraform are read from ../1_alloc/generated/tf_output.env.

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help install-all install-ingress install-cert-manager install-dashboard install-storage _check-tf-output

SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TF_OUTPUT  := $(SCRIPT_DIR)../1_alloc/generated/tf_output.env

# Guard: fail early with a clear message if Terraform has not been applied yet.
_check-tf-output:
	@test -f "$(TF_OUTPUT)" || { \
	  echo ""; \
	  echo "ERROR: $(TF_OUTPUT) not found."; \
	  echo "       Run 'make apply' in 1_alloc/ first."; \
	  echo ""; \
	  exit 1; \
	}

install-ingress: _check-tf-output ## Install the Traefik ingress controller (routes external HTTP/S traffic into the cluster)
	bash $(SCRIPT_DIR)21_install-ingress-controller.sh

install-cert-manager: install-ingress ## Install cert-manager with a Let's Encrypt issuer (automates TLS certificates)
	bash $(SCRIPT_DIR)22_install-cert-manager.sh

install-dashboard: install-cert-manager ## Install the Headlamp Kubernetes dashboard
	bash $(SCRIPT_DIR)23_install-headlamp.sh

install-storage: _check-tf-output ## Install Longhorn storage driver (enables RWX persistent volumes, required by Nextcloud)
	bash $(SCRIPT_DIR)24_install-longhorn.sh

install-all: install-dashboard install-storage ## Run all steps in the correct order
