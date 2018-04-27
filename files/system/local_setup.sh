#!/bin/bash

set -e

# respect old bash versions on mac os
regex='^[4-9].*'
if [[ $BASH_VERSION =~ $regex ]]; then
  oldbash=false
else
  oldbash=true
fi

# check if aci stack is present but must be started
# check if 'aci' container is present but in paused state
if [[ $(docker inspect -f "{{ .State.Paused }}" aci 2>/dev/null) ]]; then

  # initialize variable (assume agent is deployed)
  mustDeployAgents=false

  # check if 'squid-deb-proxy' container is present but in paused state
  if [[ $(docker inspect -f "{{ .State.Paused }}" squid-deb-proxy 2>/dev/null) ]]; then
    docker start squid-deb-proxy
  else
    mustDeployAgents=true
  fi

  # check if 'docker-mirror' container is present but in paused state
  if [[ $(docker inspect -f "{{ .State.Paused }}" docker-mirror 2>/dev/null) ]]; then
    docker start docker-mirror
  else
    mustDeployAgents=true
  fi

  echo 'ACI container already exists. Starting...'
  docker start aci

  # agents are not fully configured; squid-deb-proxy and/or docker-mirror are missing
  if [[ "$mustDeployAgents" = 'true' ]]; then
    echo 'However your agent is not fully running, so you have to run the'
    echo '00_SETUP_AGENTS Jenkins job again.'
  fi

  exit
fi

# check if workspace directory must be created
if [[ ! -f .aci ]]; then
  echo 'It seems to be the first time running ACI at this workspace location:'
  echo -e "\n\t$(pwd)\n"
  read -p 'Do you want to create a new workspace in this directory? (y/N): ' createworkspace
  if [[ -z "$createworkspace" ]] || [[ "$createworkspace" != 'y' ]]; then
    echo 'exiting...'
    exit
  else
    touch .aci
  fi
fi

# create repository configuration
if [[ ! -f repositories.yml ]]; then

  docker run --rm iteratechh/ansibleci cat /example_config/repositories.yml > repositories.yml

  echo -e "aci_repository:" >> repositories.yml

  clear
  echo 'Configuration Check [..    ]'
  echo ''
  echo 'Your workspace did not contain a repository configuration, therefore a new one was created.'
  echo 'The configuration contains information of how the repository is structured, meaning in'
  echo ' which (sub) directories the roles and playbooks are located.'
  echo 'The physical location of the repository is gathered in a later step.'
  echo 'Please provide following information:'

  addNextRepo=true
  while [[ $addNextRepo = 'true' ]]; do
    unset grouplabel
    unset reponame
    unset rolespath
    unset playbookspath
    unset rolesfrom
    echo ''
    read -p ' An arbitrary group label identifying a group of ansible repositories [default]: ' grouplabel
    [ -z "$grouplabel" ] && var='default'
    read -p ' An arbitrary but unique name for the repository: ' reponame
    read -p ' The relative subpath in the repo containing the roles (leave blank if root or none): ' rolespath
    read -p ' The relative subpath in the repo containing the playbooks (leave blank if root or none): ' playbookspath
    read -p ' A list of repository labels to gather roles from (leave blank if none): ' rolesfrom

    echo "  - group: $grouplabel" >> repositories.yml
    echo "    name: $reponame" >> repositories.yml
    if [[ $rolespath ]]; then echo "    subpath_roles: $rolespath" >> repositories.yml; fi
    if [[ $playbookspath ]]; then echo "    subpath_playbooks: $playbookspath" >> repositories.yml; fi

    if [[ ! -z "$rolesfrom" ]]; then
      echo "    roles_path_from:" >> repositories.yml
      for label in $rolesfrom; do
        echo "      - $label" >> repositories.yml
      done
    fi

    read -p ' Would you add one more repository? (y/n): ' oneMoreRepo
    if [[ -z "$oneMoreRepo" ]] || [[ "$oneMoreRepo" != 'y' ]]; then
      addNextRepo=false
    fi
  done
fi

# begin collection of local paths to the repos
# the paths in the resulting file will later be mounted to the container
if [[ ! -f conf_repository_path ]]; then
  clear
  echo 'Configuration Check [....  ]'
  echo ''
  echo "ACI needs to know the local locations of your repositories."
  echo 'This information is machine specific, thus being automatically added to .gitignore.'
  echo ''
  touch conf_repository_path
fi

# collect the local paths to the repos
for repo in $(egrep '^\s+name: ' repositories.yml | cut -c 11-); do
  set +e; grep -q "/var/jenkins_home/workspace/develop/$repo" conf_repository_path; rc=$?; set -e
  if [[ $rc != 0 ]]; then
    if [[ "$oldbash" = 'true' ]]; then
      read -p " Please provide the absolute path to the repository with the label '${repo}': " repopath
    else
      read -p " Please provide the absolute path to the repository with the label '${repo}': " -e -i "${HOME}/" repopath
    fi
    echo "-v $repopath:/var/jenkins_home/workspace/develop/$repo" >> conf_repository_path
  fi
done

# configure aci vault file
if [[ ! -f vault.yml ]]; then
  read -s -p " SUDO password for the user $(whoami): " sudopass
  echo "ACIA_SUDO_PASSWORD: ${sudopass}"  > vault.yml

  echo "PKI_PASSWORD: $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)" >> vault.yml

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
  echo 'Configuration Check [......]'
  echo ''
  echo 'Your workspace did not contain a vault file, therefore a new one was created.'
  echo 'This is an encrypted file containing unique and secret information for this ACI instance.'
  echo 'This information is machine specific, thus being automatically added to .gitignore.'
  echo 'Please provide the Vault Password.'
  echo 'You will be asked for this password whenever you start ACI from this workspace.'
  echo ''
  ansible-vault encrypt vault.yml
fi

# copy other configuration stubs
if [[ ! -f aci.yml ]]; then
    docker run --rm iteratechh/ansibleci cat /example_config/aci.yml > aci.yml
fi

if [[ ! -f agents.inventory ]]; then
    docker run --rm iteratechh/ansibleci cat /example_config/agents.inventory > agents.inventory
fi

if [[ ! -f agents.yml ]]; then
    docker run --rm iteratechh/ansibleci cat /example_config/agents.yml > agents.yml
fi

# create .gitignore
if [[ ! -f .gitignore ]]; then touch .gitignore; fi
# add files to .gitignore if not already present
for file in vault.yml conf_repository_path; do
  grep -q -F "$file" .gitignore || echo "$file" >> .gitignore
done

# FINISHED CONFIGURATION - START ACI

clear

read -s -p 'Vault Password:' avp && echo ''

docker run -d \
  --name aci \
  -p 24680:8080 \
  -e "ACI_VAULT_PASSWORD=$avp" \
  -e "ACIA_LOGIN_USER=$(whoami)" \
  -v "$(pwd)":/ansible_config \
  $(cat conf_repository_path) \
  iteratechh/ansibleci 1>/dev/null

echo ''
echo 'The AnsibleCI Docker container has been started.'
echo 'You can monitor the startup and further logs with'
echo ''
echo '    docker logs -f aci'
echo ''
echo 'After a while ACI will be available on http://localhost:8081'
echo ''
echo 'When ACI is up and running you have to complete the setup by'
echo 'running the Jenkins job 00_SETUP_AGENTS once.'
