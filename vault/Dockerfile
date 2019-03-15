FROM ubuntu:18.04

RUN apt update && apt install -y unzip wget

RUN wget https://releases.hashicorp.com/vault/1.0.3/vault_1.0.3_linux_amd64.zip -O vault.zip

RUN unzip vault.zip -d /usr/local/bin/

RUN echo "127.0.0.1 vault.form3.local" >> /etc/hosts

RUN openssl req -new -newkey rsa:4096 -x509 -sha256 \
    -days 365 -nodes -out /certificate.crt -keyout \
    /key.key -subj '/C=GB/ST=x/L=x/O=x/OU=x/CN=vault.form3.local' 

RUN openssl genrsa -out /primary.key 4096
RUN openssl req -new -sha256 -key /primary.key -subj '/C=GB/ST=x/L=x/O=x/OU=x/CN=vault.form3.local' -out /primary.csr
RUN openssl x509 -req -in /primary.csr -CA /certificate.crt -CAkey /key.key -CAcreateserial -out /primary.crt -days 500 -sha256
RUN cat /primary.crt > /combined.crt
RUN cat /certificate.crt >> /combined.crt

COPY config.hcl /config.hcl

EXPOSE 8200

CMD ["vault", "server", "-config=/config.hcl"]