docker build --build-arg http_proxy="http://172.24.104.188:3128" --build-arg https_proxy="http://172.24.104.188:3128" -t ansibleci . && dcp ansibleci ansibleci
