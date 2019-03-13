FROM ubuntu:18.04

RUN apt update && apt install -y unzip openssh-server vim 

# Download the vault-ssh-helper
RUN wget https://releases.hashicorp.com/vault-ssh-helper/0.1.4/vault-ssh-helper_0.1.4_linux_amd64.zip

# Unzip the vault-ssh-helper in /user/local/bin
RUN unzip -q vault-ssh-helper_0.1.4_linux_amd64.zip -d /usr/local/bin

# Make sure that vault-ssh-helper is executable
RUN chmod 0755 /usr/local/bin/vault-ssh-helper

# Set the usr and group of vault-ssh-helper to root
RUN chown root:root /usr/local/bin/vault-ssh-helper

# Configure vault-ssh-helper
COPY config.hcl /etc/vault-ssh-helper.d/config.hcl

# Set up our user creation script
COPY pam-user-create /usr/bin/pam-user-create
RUN chmod 0755 /usr/bin/pam-user-create

# Configure PAM
RUN sed -ri 's/^@include common-auth/#@include common-auth/' /etc/pam.d/sshd
RUN echo "auth required pam_exec.so quiet log=/var/log/pam.log /usr/bin/pam-user-create" >> /etc/pam.d/sshd
RUN echo "auth requisite pam_exec.so quiet expose_authtok log=/var/log/helper.log /usr/local/bin/vault-ssh-helper -dev -config=/etc/vault-ssh-helper.d/config.hcl" >> /etc/pam.d/sshd
RUN echo "auth optional pam_unix.so not_set_pass use_first_pass nodelay" >> /etc/pam.d/sshd

# Configure SSHD
RUN sed -ri 's/^#?ChallengeResponseAuthentication\s+.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN mkdir /var/run/sshd

# Tidy up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose ssh port
EXPOSE 22

# Start sshd
CMD    ["/usr/sbin/sshd", "-D"]
