# makefile

setup-env:
	ANSIBLE_SSH_KEY := $(shell echo | ssh-keygen -o -a 100 -t ed25519 -C "ansible" -f "$(HOME)/.ssh/id_ansible_ed25519" -P "" > /dev/null && cat $(HOME)/.ssh/id_ansible_ed25519.pub)
	ROOT_PASS := $(shell openssl rand -base64 32)
	DATETIME := $(shell date '+%Y-%m-%d_%H:%M:%S')
	VARS_URL := "https://gist.githubusercontent.com/rylabs-billy/58333048d8c2b39cd55b8b08de4e1ac0/raw/77b112a3a270189b6203b69bfb7af16af2dc166d/galera_test_varse"
	VARS_PATH := ./group_vars/galera/vars
	SECRET_VARS_PATH := ./group_vars/galera/secret_vars
	ANSIBLE_VAULT_PASS := $(shell openssl rand -base64 32)
	UBUNTU_IMAGE := linode/ubuntu20.04
	DEBIAN_IMAGE := linode/debian10

setup-config:
	curl -so $(VARS_PATH) $(VARS_URL)
	ansible-vault encrypt_string "$(ROOT_PASS)" --name 'root_pass' > $(SECRET_VARS_PATH)
	ansible-vault encrypt_string "$(TOKEN)" --name 'token' >> $(SECRET_VARS_PATH)

build: setup-env setup-config

test-ubuntu20.04:
	ansible-playbook provision.yml --extra-vars "ssh_keys=$(ANSIBLE_SSH_KEY) label=ubuntu_$(DATETIME) image=$(UBUNTU_IMAGE)"
	ansible-playbook -i hosts site.yml
	ansible-playbook -i hosts destroy.yml

test-debian10:
	ansible-playbook provision.yml --extra-vars "ssh_keys=$(ANSIBLE_SSH_KEY) label=debian_$(DATETIME) image=$(DEBIAN_IMAGE)"
	ansible-playbook -i hosts site.yml
	ansible-playbook -i hosts destroy.yml

clean:
	cd ../
	rm -rf *

