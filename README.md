# Vault Fun

This includes two containers, one running Vault and another running sshd on Ubuntu. 

Start them up:

```bash
docker-compose up --build
```

Grab the Vault token from the output of the above, and run:

```bash
export VAULT_TOKEN=<TOKEN HERE>
```

Then you can configure vault for ssh OTP:

```bash
vault secrets enable ssh
vault write ssh/roles/otp_key_role key_type=otp default_user=myusername allowed_users=myusername cidr_list=0.0.0.0/0
```

Next, you can get an OTP with:

```bash
vault write ssh/creds/otp_key_role ip=127.0.0.1
```

The key field in the above is what you need.

Now we can try and ssh into the other container with that password:

```
ssh myusername@127.0.0.1 -p2222
```

