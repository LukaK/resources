.PHONY: all clean deploy

INFRASTRUCTURE_DIRECTORY = infrastructure

all: deploy

deploy:
	cd $(INFRASTRUCTURE_DIRECTORY) && \
	terraform init && \
	terraform plan && \
	terraform apply -auto-approve

clean:
	cd $(INFRASTRUCTURE_DIRECTORY) && \
	terraform destroy -auto-approve && \
	rm -rf .terraform terraform* builds *jpg cookie.txt


######################
# HELP
######################

help:
	@echo '===================='
	@echo '-- DOCUMENTATION --'
	@echo 'deploy			    - deploy resources'
	@echo 'clean                        - clean up resources'
