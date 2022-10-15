COMMAND_NAME := $(shell awk -F '[ ="]+' '$$1 == "name" { print $$2 }' ./pyproject.toml)

all: help

check: ## Check for problems
	poetry run pre-commit run -a

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

try: ## Try a command using the current state of the files without building
ifdef args
	poetry run $(COMMAND_NAME) $(args)
else
	poetry run $(COMMAND_NAME)
endif
