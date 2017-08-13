# My Trellis Project

This is a Trellis-managed, Bedrock-based wordpress site.

## Steps

1. Get everything set up.


## Deploying

1. Buy your domain name.
2. Spin up a server.
3. Point your domain to the server, and ensure that you have added CNAMEs for
any non-canonical domains you've listed in `wordpress_sites.yml`.
4. Run `ansible-playbook server.yml -e environment=production`.
