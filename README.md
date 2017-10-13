# example.com

This is a Trellis-managed, Bedrock-based wordpress site. It uses
[trellis-template](https://github.com/robyurkowski/trellis-template) to speed up
and manage common development tasks.

-----

## Pre-requisites

- Ruby 2.1
- Rake
- Virtualbox

-----

## Setting up a dev environment

1. Clone this repository: `git clone
https://github.com/robyurkowski/trellis-template.git`
2. Run the bootstrap task: `rake bootstrap`
3. Boot up the VM: `cd provision && vagrant up`

-----

## Developing

As usual. You can edit composer.json to add plugins found on
[wpackagist](https://wpackagist.org), and then `composer update` on the VM to
lock the file.

-----

## Backups

### Setting up backups

### Verifying backups are working

-----

## Deploying

1. Buy your domain name.
2. Spin up a server: `ansible-playbook server.yml -e environment=production`
3. Point your domain to the server, and ensure that you have added CNAMEs for
any non-canonical domains you've listed in `wordpress_sites.yml`.
4. Deploy your code: `./bin/deploy.sh production example.com`
