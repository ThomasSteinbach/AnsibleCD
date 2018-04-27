#!/bin/bash

set -e

function checkout_custom_repo(){
  if [[ -f /used_config/custom_ansible_repository ]]; then
    cd /ansible_custom
    rm -rf * .[a-zA-Z0-9]*
    git clone "$(cat /used_config/custom_ansible_repository | head -n 1)" --recursive .
  fi
}

function run_setup_playbook(){
  cd /ansible_data/playbooks/setup
  ansible-playbook --vault-password-file /used_config/aci_vaultpass site.yml
}

function assure_prerequisites(){

  if [[ -z $ACI_VAULT_PASSWORD ]] && [[ -z $ACIA_LOGIN_USER ]]; then
    echo -e '\nFirst install VirtualBox and Vagrant.'
    echo ''
    echo -e '\nFor local usage of ACI create a new, empty workspace folder, run the'
    echo 'following commands inside and follow the instructions: '
    echo ''
    echo '  docker run --rm iteratechh/ansibleci local-setup > aci.sh'
    echo '  chmod +x aci.sh'
    echo '  ./aci.sh'
    echo ''
    echo ''
    echo 'For deploying ACI on a remote server run the following command instead:'
    echo ''
    echo '  docker run -it --rm -v "$PWD":/ansible_config iteratechh/ansibleci server-setup'

    exit
  fi

  # execute default Docker jenkins start script to populate jenkins home
  /usr/local/bin/jenkins.sh date 1>/dev/null # pass 'date' to suppress startup of jenkins

  # gather vault password for aci configuration
  if [[ -z $ACI_VAULT_PASSWORD ]]; then
    echo "You have to provide the vault password through the ACI_VAULT_PASSWORD variable."
    exit 1
  fi
  echo "$ACI_VAULT_PASSWORD" > /used_config/aci_vaultpass

  # gather AnsibleCI agents login user if agents.yml not already present
  if [[ ! -f /used_config/agents.yml ]] || [[ ! $(grep acia_login_user /used_config/agents.yml) ]]; then
    if [[ -z $ACIA_LOGIN_USER ]]; then
      echo "You have to provide the user for logging onto the ACI agents machine through the ACIA_LOGIN_USER variable."
      exit 1
    fi
    echo "acia_login_user: $ACIA_LOGIN_USER" >> /used_config/agents.yml
  fi
}

## START OF SCRIPT EXECUTION

if [[ "$1" = "local-setup" ]]; then
  cat /usr/local/bin/local_setup.sh; exit 1;
elif [[ "$1" = "server-setup" ]]; then
  server_setup.sh; exit 1;
elif [[ "$1" = "get-public-key" ]]; then
  ssh-keygen -y -f /var/jenkins_home/.ssh/id_rsa; exit 1;
fi

# update used configuration
if [[ $(ls /ansible_config/) ]]; then
  cp /ansible_config/* /used_config
fi

# quit script and exec command if it is not a jenkins option
if [[ $# -gt 1 ]] && [[ "$1" != "--"* ]]; then
  exec "$@"
fi

# initiate default startup if no other commands than jenkins parameters are passed...
assure_prerequisites
run_setup_playbook
source /var/jenkins_home/proxyenv
checkout_custom_repo
exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS "$@"
