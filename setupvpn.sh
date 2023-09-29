#!/bin/bash

#this shell is for ubuntu20.04
set -xv #this will enable debug
echo "input the vpn server ip address"
read ipaddress

#step1
apt update
apt install mono-runtime strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins libtss2-tcti-tabrmd0

#step2
mkdir -p ~/pki/{cacerts,certs,private}
chmod 700 ~/pki
pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem
pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem --type rsa --dn "CN=VPN root CA" --outform pem > ~/pki/cacerts/ca-cert.pem

#step3
pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem
pki --pub --in ~/pki/private/server-key.pem --type rsa \
    | pki --issue --lifetime 1825 \
        --cacert ~/pki/cacerts/ca-cert.pem \
        --cakey ~/pki/private/ca-key.pem \
        --dn "CN=$ipaddress" --san "$ipaddress" \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  ~/pki/certs/server-cert.pem

cp -r ~/pki/* /etc/ipsec.d/

#step4
mv /etc/ipsec.conf{,.original}
cat <<EOF > /etc/ipsec.conf
config setup
    charondebug="ike 1, knl 1, cfg 0"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=$ipaddress
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
    eap_identity=%identity
    ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
    esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!
EOF

#step5
cat <<EOF > /etc/ipsec.secrets
: RSA "server-key.pem"
jiangsong1 : EAP "jiangsong1666"
jiangsong2 : EAP "jiangsong2666"
jiangsong3 : EAP "jiangsong3666"
jiangsong4 : EAP "jiangsong4666"
jiangsong5 : EAP "jiangsong5666"
jiangsong6 : EAP "jiangsong6666"
jiangsong7 : EAP "jiangsong7666"
jiangsong8 : EAP "jiangsong8666"
jiangsong9 : EAP "jiangsong9666"
rensuyi1 : EAP "rensuyi1666"
rensuyi2 : EAP "rensuyi2666"
rensuyi3 : EAP "rensuyi3666"
rensuyi4 : EAP "rensuyi4666"
EOF

systemctl restart strongswan-starter

#step6
ufw allow OpenSSH
ufw enable
ufw allow 500,4500/udp

networkinterface=$(ip route | grep default | cut -d " " -f 5)

mono ParseRules.exe $networkinterface /etc/ufw/before.rules /etc/ufw/sysctl.conf
ufw disable
ufw enable
