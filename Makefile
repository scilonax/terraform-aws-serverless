SHELL := /bin/bash

.EXPORT_ALL_VARIABLES:

AWS_DEFAULT_REGION=us-east-1
TF_IN_AUTOMATION=true
AWS_PROFILE=scilonax_sandbox

init:
	find . -type f -name "*.tf" \
		-exec dirname {} \;|sort -u | while read m; do ( \
		cd "$$m" && echo "-> $$m" && terraform init -input=false -backend=false) || exit 1; done
init-backend:
	find examples -path ./modules -prune -o -type f -name "*.tf" \
		-exec dirname {} \;|sort -u | while read m; do ( \
		cd "$$m" && echo "-> $$m" && terraform init -input=false) || exit 1; done
validate:
	find . -name ".terraform" -prune -o -type f -name "*.tf" \
		-exec dirname {} \;|sort -u | while read m; do ( \
		cd "$$m" && terraform validate && echo "√ $$m") || exit 1 ; done
fmt:
	find . -name ".terraform" -prune -o -type f -name "*.tf" \
		-exec dirname {} \;|sort -u | while read m; do ( \
		cd "$$m" && terraform fmt -check && echo "√ $$m" || (echo "✗ $$m" && exit 1)) || exit 1 ; done

lint:
	find . -name ".terraform" -prune -o -type f -name "*.tf" \
		-exec dirname {} \;|sort -u | while read m; do ( \
			cd "$$m" && tflint && echo "√ $$m") || exit 1 ; done
test-plan:
	find examples -type d -name ".terraform" \
		-exec dirname {} \;|sort -u | while read m; do ( \
			cd "$$m" && echo "-> $$m" && terraform plan -input=false) || exit 1; done
plan:
	find examples -type d -name ".terraform" \
		-exec dirname {} \;|sort -u | while read m; do ( \
			cd "$$m" && echo "-> $$m" && terraform plan -out=tfplan -input=false) || exit 1; done
apply:
	find examples -type d -name ".terraform" \
		-exec dirname {} \;|sort -u | while read m; do ( \
			cd "$$m" && echo "-> $$m" && terraform apply -input=false tfplan) || exit 1; done