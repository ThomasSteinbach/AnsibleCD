# Server Installation

## 1 Create the Configuration

Get the example configuration and modify according your needs:

```
docker run --rm -v "$(pwd)":/config iteratechh/ansibleci cp -a /example_config /config
mv example_config ansible_config
```

## 2 Start ACI with Configuration

```
#!/bin/bash
echo 'Vault Password: '
read -s avp
docker run -d --name aci -p 8081:8080 --env "ACI_VAULT_PASSWORD=$avp"
  -v /path/to/ansible_config:/ansible_config
  -v /path/to/repository:/var/jenkins_home/workspace/develop/<repo-label>
  iteratechh/ansibleci

```

## 3 Deploy ACI Agent

Run Jenkins Job 00_SETUP_AGENTS
