# de.iteratec.hh.ansible-ci

Installs the AnsibleCI Server.

## Requirements

-   This Role depends on the [iteratechh/ansibleci](https://hub.docker.com/r/iteratechh/ansibleci/) Docker image.
-   This Role is meant to be deployed with the de.iteratec.hh.ansible-ci-agent Role, even not on the same machine, and shares some configuration

## Mandatory Vault Variables

| Variable      | Value              | Description                                                                                         |
| ------------- | ------------------ | --------------------------------------------------------------------------------------------------- |
| PKI\_PASSWORD | String             | Password for the remote Docker PKI.                                                                 |
| ID\_RSA       | private key string | The private key file for Jenkins, which public key must be registered on the Git repository server. |

## Independent Configuration of Git Repository Server

You are encouraged to setup a post-receive hook on your Git server, by adding following line to the `/path/to/repository/.git/hooks/post-receive` file:

    curl 'http://ansible-ci-server:port/git/notifyCommit?url=<repository-url>'

The repository url is exact the same URL you setup for role testing. Example:

    curl 'http://aci.example.com:8081/git/notifyCommit?url=ssh://git@git.example.com:2222/user/repository.git'

## Info

Mention common information in parent [README.md](../README.md)

## Licence

The whole repository is licenced under BSD. Please mention following:

gitlab.xarif.de / ThomasSteinbach (thomass at aikq.de)
