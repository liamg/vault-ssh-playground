storage "inmem" {}

listener "tcp" {
 address     = "0.0.0.0:8200"
 tls_cert_file = "/combined.crt"
 tls_key_file = "/primary.key"
}

ui = true
log_level = "debug"