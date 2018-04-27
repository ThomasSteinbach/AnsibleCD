#!/bin/bash
if [[ ! -f .aci ]]; then
  echo 'It seems to be the first time running ACI at this workspace location:'
  echo -e "\n\t$(pwd)\n"
  read -p 'Do you want to create a new workspace in this directory? (y/N): ' createworkspace
  if [[ -z "$createworkspace" ]] || [[ "$createworkspace" != 'y' ]]; then
    echo 'exiting...'
    exit
  else
    touch .aci
    cp /example_config/aci.yml /ansible_config/aci.yml
    cp /example_config/agents.inventory /ansible_config/agents.inventory
    cp /example_config/agents.yml /ansible_config/agents.yml
    cp /example_config/conf_ansible_repository.example /ansible_config/conf_ansible_repository.example
    cp /example_config/prelive.inventory /ansible_config/prelive.inventory
    cp /example_config/prelive.yml /ansible_config/prelive.yml
    cp /example_config/repositories.yml /ansible_config/repositories.yml
  fi
fi

if [[ ! -f vault.yml ]]; then
  echo "PKI_PASSWORD: $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)" > vault.yml

  echo 'ACI_PRIVATE_KEY: |' >> vault.yml
  ssh-keygen -t rsa -C 'AnsibleCI' -N '' -f /tmp/aci_key 1>/dev/null
  cat /tmp/aci_key | sed 's/^/  /' >> vault.yml
  echo "ACI_PUBLIC_KEY: $(cat /tmp/aci_key.pub)" >> vault.yml

  cat /tmp/aci_key.pub >> ~/.ssh/authorized_keys
  rm /tmp/aci_key /tmp/aci_key.pub

  echo 'ACIA_PRIVATE_KEY: |' >> vault.yml
  ssh-keygen -t rsa -C 'ACIAgent' -N '' -f /tmp/acia_key 1>/dev/null
  cat /tmp/acia_key | sed 's/^/  /' >> vault.yml
  echo "ACIA_PUBLIC_KEY: $(cat /tmp/acia_key.pub)" >> vault.yml
  rm /tmp/acia_key /tmp/acia_key.pub

  clear
  echo 'Your workspace did not contain a vault file, therefore a new one was created.'
  echo 'This is an encrypted file containing unique and secret information for this ACI instance.'
  echo 'This information is machine specific, thus being automatically added to .gitignore.'
  echo 'Please provide the Vault Password.'
  echo 'You will be asked for this password whenever you start ACI from this workspace.'
  echo ''
  ansible-vault encrypt vault.yml
fi

clear
echo 'The basic configuration of your workspace is ready. Now you have to configure'
echo 'all configuration files created. After finishing the configuration you can'
echo 'either package the configuration to a new Docker image derived from the'
echo 'iteratechh/ansibleci image or deploy the workspace to the server and mount the'
echo 'workspace directory to the iteratechh/ansibleci container. On the server you'
echo 'should run the AnsibleCI container with at least following configuration:'
echo ''
echo 'docker run -d \'
echo '  --name aci \'
echo '  -p <aci_server_port>:8080 \'
echo '  -e "ACI_VAULT_PASSWORD=<aci_vault_password>" \'
echo '  -e "ACIA_LOGIN_USER=<agents_machine_login_user>" \'
echo '  -v "<path/to/workspace>":/ansible_config \'
echo '  iteratechh/ansibleci'
