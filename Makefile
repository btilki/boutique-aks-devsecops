# Makefile — operator shortcuts (expanded per phase)
.PHONY: help pre-commit pr-validate checkov dast-help

help:
	@echo "Targets:"
	@echo "  pre-commit    Run all pre-commit hooks"
	@echo "  checkov       Run Checkov on terraform/ (Topic 16)"
	@echo "  pr-validate   Local PR gates (pre-commit + TF + Checkov + kyverno)"
	@echo "  dast-help     Show local ZAP DAST usage (Topic 20; needs live URL)"
	@echo "  (more targets added per implementation phase)"

pre-commit:
	pre-commit run --all-files

checkov:
	./tests/terraform/checkov.sh

pr-validate:
	./tests/ci/pr-validate.sh

dast-help:
	@echo "Usage: ./tests/ci/dast-zap.sh https://dev-boutique.<DNS_ZONE>"
	@echo "Requires: Docker + reachable HTTPS target (platform rebuilt)."
