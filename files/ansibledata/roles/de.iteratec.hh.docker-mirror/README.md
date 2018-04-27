# thomass.docker-mirror
Would act as proxy cache between the official Docker repository and your Docker clients.

## Installation
Execute the role. It is very important that the domain and ip fits to the URL you want to access the mirror later.

```
- role: de.iteratec.hh.docker-mirror
  dmirror_domain: "myserver.de"
  dmirror_ip: "192.168.1.1"
  dmirror_port: "5000"
  dmirror_pki_password: "{{ PKI_PASSWORD }}"
  dmirror_pki_countrycode: "DE"
  dmirror_pki_state: "Hamburg"
  dmirror_pki_locality: "Hamburg"
  dmirror_pki_organization: "MyServer"
```

It will create some PKI files with self-signed certificates the mirror gets startet with. Thus the CA certificate needs to be registered on hosts using the mirror:

## Setup clients
First you have to add the mirror to the Docker daemons start parameters (in Ubuntu under `/etc/default/docker`):

```
...
DOCKER_OPTS="--registry-mirror=https://myserver.de:5000"
```

Depending on your operating system (following Ubuntu) you then have to register your CA certificate. This certificate was deployed with the upper role on the (remote) host under the path `<ansible_user_dir>/.ansible-data/thomass.docker-mirror/ca.pem`. First you have to transfer the `ca.pem` to the client and rename it to `ca.crt`. Now you have to proceed with the following steps:

```
sudo cp ca.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
sudo service docker restart
```

## Checking your mirror becomes filled

```
curl https://myserver.de:5000/v2/_catalog
```

## Trouble Shooting

Error                                                                                                                                                         | Solution
------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------
When you curl `https://myserver.de:5000/v2/_catalog` you'll get: `curl: (35) error:0407006A:rsa routines:RSA_padding_check_PKCS1_type_1:block type is not 01` | You have registered the wrong CA certificate.
When you curl `https://myserver.de:5000/v2/_catalog` you'll get: `curl: (60) SSL certificate problem: unable to get local issuer certificate`                 | You haven't registered the CA certificate at all.
When you try to push an image to the mirror, you'll get: `cannot validate certificate for <ip> because it doesn't contain any IP SANs`                        | The <ip> was not setup correctly during the role deployment (variable `dmirror_ip`) or another IP is used for accessing the mirror.
