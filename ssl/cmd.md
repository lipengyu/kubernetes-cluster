
## CA 密钥及证书
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout ca.key -out ca.crt -subj "/CN=ca.k8s.local"

## kube-apiserver、kube-controller-manager 及 kube-scheduler 密钥及证书
openssl req -nodes -newkey rsa:4096 -keyout master.key -out master.csr -subj "/CN=master.k8s.local"
openssl x509 -req -CAcreateserial -CA ca.crt -CAkey ca.key -days 3650 -extensions v3_req -extfile master_ssl.cnf -in master.csr -out master.crt

## kube-proxy 及 kubelet 密钥及证书
openssl req -nodes -newkey rsa:4096 -keyout node.key -out node.csr -subj "/CN=node.k8s.local"
openssl x509 -req -CAcreateserial -CA ca.crt -CAkey ca.key -days 3650 -extensions v3_req -extfile node_ssl.cnf -in node.csr -out node.crt

## kubectl 密钥及证书
openssl req -nodes -newkey rsa:4096 -keyout kubectl.key -out kubectl.csr -subj "/CN=kubectl.k8s.local"
openssl x509 -req -CAcreateserial -CA ca.crt -CAkey ca.key -days 3650 -extensions v3_req -extfile kubectl_ssl.cnf -in kubectl.csr -out kubectl.crt


## Service Account 密钥对

openssl genrsa -out service-account.key 4096


--client-ca-file=/etc/kubernetes/ssl/ca.crt --tls-cert-file=/etc/kubernetes/ssl/master.crt --tls-private-key-file=/etc/kubernetes/ssl/master.key



kubectl --server=https://172.17.0.100:6443 \
--certificate-authority=/etc/kubernetes/ssl/ca.crt \
--client-certificate=/etc/kubernetes/ssl/kubectl.crt \
--client-key=/etc/kubernetes/ssl/kubectl.key \
version


openssl x509 -text -noout -in ca.crt

openssl req -text -noout -in kubectl.csr


## 参考资料
[The Most Common OpenSSL Commands](https://www.sslshopper.com/article-most-common-openssl-commands.html)
[openssl-req](https://www.openssl.org/docs/man1.0.2/apps/openssl-req.html)
[openssl-x509](https://www.openssl.org/docs/man1.0.2/apps/x509.html)

