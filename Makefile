# Makefile — operator shortcuts (expanded per phase)
.PHONY: help pre-commit

help:
	@echo "Targets:"
	@echo "  pre-commit   Run all pre-commit hooks"
	@echo "  (more targets added per implementation phase)"

pre-commit:
	pre-commit run --all-files
