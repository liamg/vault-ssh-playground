#!/bin/bash

set -e

echo "Add the following to your /etc/hosts:"
echo
echo "    vault.form3.local 127.0.0.1"
echo
read -p "Press enter to continue"

echo "Initialising vault..."

export VAULT_ADDR=https://vault.form3.local:8200
export VAULT_SKIP_VERIFY=1
vault operator init -key-threshold=2
vault operator unseal
vault operator unseal

echo "Enter vault token: "
read token
export VAULT_TOKEN=$token

echo "Configuring vault..."

vault secrets enable -path=form3tech -description="Form3 Root CA" -max-lease-ttl=87600h pki

vault write form3tech/root/generate/internal \
    common_name="Form3 Root CA" \
    ttl=87600h \
    key_bits=4096 \
    exclude_cn_from_sans=true

vault write form3tech/config/urls \
    issuing_certificates="http://vault.form3.local:8200/v1/form3tech/ca" \
    crl_distribution_points="http://vault.form3.local:8200/v1/form3tech/crl"

vault secrets enable -path=form3_intermediate -description="Form3 Intermediate CA" -max-lease-ttl=26280h  pki

vault write -format=json form3_intermediate/intermediate/generate/internal \
    common_name="Form3 Intermediate CA" \
    ttl=26280h \
    key_bits=4096 \
    exclude_cn_from_sans=true | jq -r .data.csr > form3_intermediate.csr

vault write -format=json form3tech/root/sign-intermediate \
    csr=@form3_intermediate.csr  \
    common_name="Form3 Intermediate CA" \
    ttl=26280h | jq -r .data.certificate > form3_intermediate.crt

rm -f form3_intermediate.csr

vault write form3_intermediate/intermediate/set-signed certificate=@form3_intermediate.crt 

rm -f form3_intermediate.crt 

vault write form3_intermediate/config/urls \
    issuing_certificates="http://vault.form3.local:8200/v1/form3_intermediate/ca" \
    crl_distribution_points="http://vault.form3.local:8200/v1/form3_intermediate/crl"

vault policy write ed policy-ed.hcl
vault policy write liam policy-liam.hcl

vault write form3_intermediate/roles/ed \
 key_bits=2048 \
 max_ttl=8760h \
 allow_any_name=true \
 enforce_hostnames=false \
 client_flag=true \
 server_flag=false \
 policies="ed"

vault write form3_intermediate/roles/liam \
 key_bits=2048 \
 max_ttl=8760h \
 allow_any_name=true \
 enforce_hostnames=false \
 client_flag=true \
 server_flag=false \
 policies="liam"

echo "Enter yubikey management key: "
read -s key
echo "Touch yubikey twice."
yubico-piv-tool --touch-policy=always -s 9a -a generate -o pubkey.pem -k$key

echo "Remember to touch yubikey after entering pin... "
yubico-piv-tool -s 9a -a verify -a request \
     -S /CN=liam.galvin@form3.tech \
     -i pubkey.pem \
     -o csr.pem

rm -f pubkey.pem

 vault write -format=json form3_intermediate/sign/liam \
     common_name=liam.galvin@form3.tech \
     csr=@csr.pem \
     exclude_cn_from_sans=false \
     format=pem | jq -r .data.certificate > user.pem

rm -f csr.pem

echo "Importing certificate to your yubikey..."
yubico-piv-tool -a import-certificate -s 9a -i user.pem -k

echo "Enabling cert based authentication in vault..."

vault auth enable cert

vault write auth/cert/certs/liam policies="liam" \
    certificate=@user.pem

rm -f user.pem

vault secrets enable ssh
vault write ssh/roles/liam key_type=otp default_user=liam-2001 allowed_users=liam-2001 cidr_list=0.0.0.0/0
vault write ssh/roles/ed key_type=otp default_user=ed-2002 allowed_users=ed-2002 cidr_list=0.0.0.0/0

# get CA from container and trust it when we log in
docker-compose exec vault cat /certificate.crt > ./sshd/ca/ca.crt

echo "Attempting login..."

echo "Enter PIN: "
read -s pin
echo "Touch yubikey now!"
token=$(curl --cacert ./sshd/ca/ca.crt -vvv -s -X POST -E "pkcs11:manufacturer=piv_II;id=%01;pin-value=$pin" $VAULT_ADDR/v1/auth/cert/login | jq -r '.auth.client_token')
#curl -vvv -s -X POST -E "pkcs11:manufacturer=piv_II;id=%01;pin-value=$pin" $VAULT_ADDR/v1/auth/cert/login #| jq -r '.auth.client_token'

if [ "$token" = "" ]; then
    echo "Failed to authenticate with vault"
    exit 1
fi

export VAULT_TOKEN=$token
vault write ssh/creds/liam ip=127.0.0.1
