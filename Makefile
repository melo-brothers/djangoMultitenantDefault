TEST_TARGET=./src
FLAKE8_FLAGS=--ignore=W503,E501
ISORT_FLAGS=--profile=black --lines-after-import=2
PROJECT=./project/
MANAGE =python manage.py
DJANGO_SETTINGS_MODULE=DJANGO_SETTINGS_MODULE=project.settings

.PHONY: all help install clean
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
install: ## Instala / Atualiza os pacotes python no virtualenv instalado.
	pip install --no-cache -U pip setuptools wheel
	pip install --no-cache -r requirements-dev.txt
clean:
	@py3clean .
## @ Running
.PHONY: run shell migrations migrate
run: ## Executa o servidor em ambiente de desenvolvimento
	python manage.py runserver
shell: ## Inicializa o shell
	python manage.py shell_plus
migrations: ## Cria as migrações
	python manage.py makemigrations
migrate: ## Aplica as migrações
	python migrate_tenants.py
manage_tenant: ## Aplica as migrações
	python manage_tenants.py

## @ testes
.PHONY: test cover
test: ## Executa os testes
	pytest
cover: ## Executa os testes e gera o arquivo de report
	pytest

## @ lint
.PHONY: lint_black flake lint_isort git_lint lint
lint_black:
	black --check ${PROJECT}
flake:
	flake8 ${FLAKE8_FLAGS} ${PROJECT}
lint_isort:
	isort ${ISORT_FLAGS} --check ${PROJECT}
git_lint:
	flake8 ${FLAKE8_FLAGS} $$(git diff --name-only | grep .py)
lint: lint_black flake lint_isort ## Realiza a análise estática do código: black, flake, mypy e isort

## @ format python files
.PHONY: black isort format git_format
black:
	black ${PROJECT}
isort:
	isort ${ISORT_FLAGS} ${PROJECT}
git_format:## formata somente os arquivos alterados (git)
	@black $$(git diff --name-only | grep .py)
	@isort ${ISORT_FLAGS} $$(git diff --name-only | grep .py)
format: isort black ## Formata os arquivos python usando black e isort