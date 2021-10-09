#!/bin/bash
set -e
trap "cleanup $? $LINENO" EXIT

function cleanup {
  if [ "$?" != "0" ]; then
    echo "PIPELINE FAILED."
    exit 1
  fi
}

# global constants
readonly ANSIBLE_SSH_KEY=$(ssh-keygen -o -a 100 -t ed25519 -C "ansible" -f "${HOME}/.ssh/id_ansible_ed25519" -q -N "" <<<y >/dev/null && cat ${HOME}/.ssh/id_ansible_ed25519.pub)
readonly ROOT_PASS=$(openssl rand -base64 32)
readonly DATETIME=$(date '+%Y-%m-%d_%H:%M:%S')
readonly VARS_URL="https://gist.githubusercontent.com/rylabs-billy/58333048d8c2b39cd55b8b08de4e1ac0/raw/ec7a63a3eb95c37fc20f64a6ccdacfd472acc37c/galera_test_vars"
readonly VARS_PATH="./group_vars/galera/vars"
readonly SECRET_VARS_PATH="./group_vars/galera/secret_vars"
readonly ANSIBLE_VAULT_PASS=$(openssl rand -base64 32)
readonly UBUNTU_IMAGE="linode/ubuntu20.04"
readonly DEBIAN_IMAGE="linode/debian10"

function build {
    curl -so ${VARS_PATH} ${VARS_URL}
	echo "${ANSIBLE_VAULT_PASS}" > ./vault-pass
	ansible-vault encrypt_string "${ROOT_PASS}" --name 'root_pass' > ${SECRET_VARS_PATH}
	ansible-vault encrypt_string "${TOKEN}" --name 'token' >> ${SECRET_VARS_PATH}
    ansible-galaxy collection install linode.cloud community.crypto community.mysql
}

function test_ubuntu2004 {
    echo "${ANSIBLE_SSH_KEY}"
    ansible-playbook provision.yml --extra-vars "ssh_keys=${ANSIBLE_SSH_KEY} galera_prefix=ubuntu_${DATETIME} image=${UBUNTU_IMAGE}" --flush-cache
	ansible-playbook -i hosts site.yml
	ansible-playbook destroy.yml
}

function test_debian10 {
    ansible-playbook provision.yml --extra-vars "ssh_keys=${ANSIBLE_SSH_KEY} galera_prefix=ubuntu_${DATETIME} image=${DEBIAN_IMAGE}" --flush-cache
	ansible-playbook -i hosts site.yml
	ansible-playbook destroy.yml
}

case $1 in
    build) "$@"; exit;;
    test_ubuntu2004) "$@"; exit;;
    test_debian10) "$@"; exit;;
esac

# main
build
test_ubuntu2004
test_debian10

