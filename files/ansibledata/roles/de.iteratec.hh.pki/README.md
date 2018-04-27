# thomass.pki
This role is creating a PKI consisting of:

key                             | file name
------------------------------- | ---------------
CA private key                  | ca-key.pem
CA public key                   | ca.pem
Server private key              | server-key.pem
Server public key / certificate | server-cert.pem
Client private key              | client-key.pem
Client public key / certificate | client-cert.pem

## Mandatory Variables

variable       | value      | description
-------------- | ---------- | ------------------------------------
pki_password   | String     | The password for the CA private key.
pki_server_dns | FQND       | The FQND of the Server

# Example

```
- role: thomass.pki
  pki_password: mysecret
  pki_server_dns: example.com
  pki_ca_country: DE
  pki_ca_state: Sachsen
  pki_ca_locality: Zwickau
  pki_ca_organization: "Example Ltd."
  pki_server_extfile_content: "subjectAltName = IP:10.10.10.20,IP:127.0.0.1"
  pki_client_extfile_content: "extendedKeyUsage = clientAuth"
```

## Info
Mention common information in parent [README.md](../README.md)

## Licence
The whole repository is licenced under BSD. Please mention following:

gitlab.xarif.de / ThomasSteinbach (thomass at aikq.de)
