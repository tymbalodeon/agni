REQUIREMENTS = requirements.txt

all: help

add: package freeze ## pip install package and freeze requirements [arg: "package"]

check: ## Check for problems
	pre-commit run -a

freeze: ## Freeze the dependencies to the requirements.txt file
	pip freeze > $(REQUIREMENTS)

help: ## Display the help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Install the dependencies from the requirements.txt file
	pip install -U pip && pip install -r $(REQUIREMENTS)

package:
	pip install $(package)

