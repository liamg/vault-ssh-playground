# Vault Fun

This includes two containers, one running Vault and another running sshd on Ubuntu. 

The sshd container has been configured to automatically create non-existant users on SSH login. This currently requires the user to initially attempt to authenticate twice, as the first attempt sshd will not have information about the uid/guid of the freshly created user.

## Setup

```
docker-compose up --build
```

and in separate terminal:

```
./init.sh
```

then you can

```
ssh liam-2001@127.0.0.1 -p2222
```

(you will need to attempt to ssh in twice, as the first attempt will always fail)


### Configuring SSH OTP

Now you can configure vault to provide OTPs for ssh:

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

