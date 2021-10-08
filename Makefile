# makefile

ANSIBLE_SSH_KEY := $(shell echo | ssh-keygen -o -a 100 -t ed25519 -C "ansible" -f "$(HOME)/.ssh/id_ansible_ed25519" -P "" > /dev/null && cat $(HOME)/.ssh/id_ansible_ed25519.pub)
ROOT_PASS := $(shell openssl rand -base64 32)
DATETIME := $(shell date '+%Y-%m-%d_%H:%M:%S')
VARS_URL := "hhttps://gist.githubusercontent.com/rylabs-billy/58333048d8c2b39cd55b8b08de4e1ac0/raw/afb0990118b5b18af39bb41d70859627f6c25a19/galera_test_vars"
VARS_PATH := ./group_vars/galera/vars
SECRET_VARS_PATH := ./group_vars/galera/secret_vars
ANSIBLE_VAULT_PASS := $(shell openssl rand -base64 32)
UBUNTU_IMAGE := linode/ubuntu20.04
DEBIAN_IMAGE := linode/debian10

build:
 	python3 -m pip install --upgrade pip
    python3 -m pip install wheel==0.37.0
    python3 -m pip install -r requirements.txt
	curl -so $(VARS_PATH) $(VARS_URL)
	ansible-vault encrypt_string "$(ROOT_PASS)" --name 'root_pass' > $(SECRET_VARS_PATH)
	ansible-vault encrypt_string "$(TOKEN)" --name 'token' >> $(SECRET_VARS_PATH)
	ansible-galaxy collection install linode.cloud community.crypto community.mysql

test-ubuntu20.04:
	ansible-playbook provision.yml --extra-vars "ssh_keys=$(ANSIBLE_SSH_KEY) label=ubuntu_$(DATETIME) image=$(UBUNTU_IMAGE)"
	ansible-playbook -i hosts site.yml
	ansible-playbook destroy.yml

test-debian10:
	ansible-playbook provision.yml --extra-vars "ssh_keys=$(ANSIBLE_SSH_KEY) label=debian_$(DATETIME) image=$(DEBIAN_IMAGE)"
	ansible-playbook -i hosts site.yml
	ansible-playbook destroy.yml

test: test-ubuntu20.04 test-debian10

