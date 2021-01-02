# dora

<!-- TOC ignore:true -->
## *DO*cker container for *RA*ils

This is a little project that helps me to set up and operate [Docker][]
containers for [Ruby on Rails][] apps. It builds upon the [passenger-docker][]
container by [Phusion][], the makers of the [Passenger][] app server.

The Dockerfile and the maintenance scripts are generic. Customization for
specific apps happens through Docker build `ARGS` and environment variables.
There is built-in support to generate PDF files with [wkhtmltopdf][].

The container is expected to sit behind a [reverse proxy](#reverse-proxy) that
handles name-based virtual hosts, SSL, etc.

> If you stumble upon this, be advised that this is amateur work. It may suit
your needs, but it was mainly created to help me with my own projects. I would
be more than happy though to take pull request to improve this.

An alternative and much more sophisticated approach to Dockerizing a Rails app
can be found at [Discourse][].

<!-- TOC ignore:true -->
## Outline
<!-- TOC -->

- [Current versions of third-party components](#current-versions-of-third-party-components)
- [Customization](#customization)
  - [Environment variables](#environment-variables)
  - [Build argument](#build-argument)
  - [YAML snippet for docker-compose](#yaml-snippet-for-docker-compose)
  - [Using ENV in your Rails app](#using-env-in-your-rails-app)
  - [Reverse proxy](#reverse-proxy)
- [Sidekiq](#sidekiq)
- [Upgrading the app](#upgrading-the-app)
- [Data persistence](#data-persistence)
- [SSH access](#ssh-access)
- [wkhtmltopdf support](#wkhtmltopdf-support)
- [Status reports](#status-reports)
- [Development and testing](#development-and-testing)
  - [MailHog](#mailhog)
- [Container time zone](#container-time-zone)
- [Logrotate](#logrotate)
- [Troubleshooting](#troubleshooting)
  - [Sending mail](#sending-mail)
  - [Receiving mail](#receiving-mail)
  - [Database configuration](#database-configuration)
  - [SMTP configuration](#smtp-configuration)
  - [Required gems](#required-gems)
  - [Sidekiq configuration](#sidekiq-configuration)
  - [Avoiding confusion](#avoiding-confusion)
- [Further reading](#further-reading)
- [License](#license)

<!-- /TOC -->

## Current versions of third-party components

| Domain                 | Component                                    |         |
|------------------------|----------------------------------------------|--------:|
| Dockerfile             | [phusion/passenger-ruby27][passenger-docker] | 1.0.11
| install-wkhtmltopdf.sh | [wkhtmltopdf][]                              | 0.12.5
| docker-compose.yml     | Postgres                                     | 11
| docker-compose.yml     | Adminer                                      | 4.7
| docker-compose.yml     | [Mailhog][]                                  | 1.0.0

## Customization

Customization is mostly done with environment variables.

### Environment variables

| Variable | Use | Default
|------|------|------
| `APP_NAME` | Application name | `app`
| `PASSENGER_APP_ENV` | Rails environment (this is a `passenger-docker` variable) | `production`
| `RAILS_PRECOMPILE_ASSETS` | Whether to precompile Rails assets | `true`
| `GIT_PULL` | Indicates whether to clone and pull the app from a Git repository (*must* be `false` to suppress cloning and pulling) | `true`
| `GIT_REPO` | URL of the Git repository |
| `GIT_BRANCH` | Branch to check out of the Git repository | `master`
| `GIT_USER` | Git user that has read access for the repository (opt.) |
| `GIT_PASS` | Password for the Git user (opt.) |
| `RAILS_DB_HOST` | Database host | `db`
| `RAILS_DB_NAME` | Database name | `$APP_NAME`
| `RAILS_DB_USER` | Database user | `$APP_NAME`
| `RAILS_DB_PASS` | Database password |
| `RAILS_SMTP_HOST` | SMTP server |
| `RAILS_SMTP_PORT` | SMTP port | 587
| `RAILS_SMTP_USER` | SMTP user name | `$APP_NAME`
| `RAILS_SMTP_PASS` | SMTP password |
| `RAILS_SMTP_FROM` | FROM address for [system messages](#status-reports) |
| `EMAIL_REPORTS_TO` | Optional e-mail recipient for daily [status reports](#status-reports) |
| `SECRET_KEY_BASE` | Rails' secret key base |
| `TIMEZONE` | Time zone of the container | `UCT`
| `NO_WKHTMLTOPDF` | Do not attempt to install [wkhtmltopdf][] | (empty)
| `WKHTMLTOPDF_URL` | Download URL for [wkhtmltopdf][] |
| `WEBHOOK_SECRET` | Secret token that can we used for webhooks (not used by Dora) |

### Build argument

There is one argument that can be used during image build:

| Argument | Use | Default
|----------|-----|---------
| `PUBLIC_KEY` | Public SSH key that will be added to `/home/dora/.ssh/authorized_keys` | `unusable.pub`

The repository contains an `unusable_pub` key whose private key has been
discarded (promise! ;-) ). Its sole purpose is to be act as a dummy key in the
repository. To use your own key, set the `PUBLIC_KEY` argument to the path of
the _public_ key and store the private key in a safe place. NB: The public key
must be in Dora's directory because it must be sent to the Docker daemon
along with the rest of the build context. Files ending with `.pub` are ignored
in the repository.

See below for more information about SSH'ing into the container.

### YAML snippet for docker-compose

To use dora with [docker-compose][], clone the repository, then add the
following snippet to your `docker-compose.yml` file and customize it (e.g.,
replace `MY_APP` with something else).

The bracketed bits (`{{ ... }}`) are [Ansible][] variables. If you do not use
Ansible, just replace them with something else.

```yaml
  MY_APP:
    container_name: MY_APP
    build:
      context: dora
    restart: always
    ports:
      - "127.0.0.1:{{ ports.MY_APP }}:80"
    volumes:
      - "{{ docker.volume_dir }}/MY_APP:/shared"
    environment:
      APP_NAME: "{{ MY_APP.name }}"
      PASSENGER_APP_ENV: "{{ MY_APP.rails_env }}"
      GIT_REPO: "{{ MY_APP.git.repo}} "
      GIT_BRANCH: "{{ MY_APP.git.branch}} "
      GIT_USER: "{{ MY_APP.git.user}} "
      GIT_PASS: "{{ MY_APP.git.pass}} "
      RAILS_DB_HOST: "{{ MY_APP.db.host }}"
      RAILS_DB_NAME: "{{ MY_APP.db.name }}"
      RAILS_DB_USER: "{{ MY_APP.db.user }}"
      RAILS_DB_PASS: "{{ MY_APP.db.pass }}"
      RAILS_SMTP_HOST: "{{ MY_APP.smtp.host }}"
      RAILS_SMTP_PORT: "{{ MY_APP.smtp.port }}"
      RAILS_SMTP_USER: "{{ MY_APP.smtp.user }}"
      RAILS_SMTP_PASS: "{{ MY_APP.smtp.pass }}"
      SECRET_KEY_BASE: "{{ MY_APP.secret_key }}"
    depends_on:
      - db

  # The following may be entirely different in your environment
  db:
    container_name: db
    image: postgres:11
    restart: always
    volumes:
      - "{{ docker.volume_dir }}/db/pgdata:/var/lib/postgresql/data"
    environment:
      - "POSTGRES_PASSWORD={{ postgres_master_password }}"
```

Snippet for Ansible's `defaults/main.yml` file (I define all variables here,
even those with a default value, to prevent surprises in the future):

```yaml
docker:
  volume_dir: /home/ME/docker-data
ports:
  # This is the port that is exposed internally on the host
  MY_APP: 8080
MY_APP:
  name:
  rails_env:
  secret_key:
  git:
    repo:
    branch:
    user:
    pass:
  db:
    host:
    name:
    user:
    pass:
  smtp:
    host:
    port: 587
    user:
    pass:
```

Remember to use `ansible-vault encrypt_string` to hash all passwords!

> **WARNING:** Even then using `ansible-vault` to encrypt all secrets in your
Ansible repository, be aware that they will appear unencrypted in the
`docker-compose.yml` file that is deployed on the server!

Please ensure your secrets are safe.

### Using ENV in your Rails app

Rails secret:

```yaml
production:
  secret_key_base: <%= ENV['SECRET_KEY_BASE'] %>
```

Database:

```yaml
# config/database.yml
# Keep in mind that this is parsed with ERB.
production:
  adapter: postgresql
  host: <%= ENV['RAILS_DB_HOST'] %>
  database: <%= ENV['RAILS_DB_NAME'] %>
  username: <%= ENV['RAILS_DB_USER'] %>
  password: <%= ENV['RAILS_DB_PASS'] %>
```

SMTP server:

```ruby
# config/environments/production.rb
Rails.application.configure do

  # ...

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['RAILS_SMTP_HOST'],
    port: ENV['RAILS_SMTP_PORT'],
    user_name: ENV['RAILS_SMTP_USER'],
    password: ENV['RAILS_SMTP_PASS']

  # ...

end
```

### Reverse proxy

I use [Apache2][] as a reverse proxy to relay requests from the Docker host to
the container. This can of course also be done with [Nginx][] or any other web
server that can act as a reverse proxy, but I have more experience with Apache.

NB: This is an [Ansible][] template with some Ansible variables in it.

```apache
# Redirect all HTTP requests to HTTPS
<VirtualHost *:80>
  ServerName MY_SERVER
  Redirect permanent / https://MY_SERVER/
  ServerAdmin webmaster@MY_SERVER
</Virtualhost>

<VirtualHost *:443>
  ServerName MY_SERVER

  # Common include file for all my virtual host configurations that
  # enables MOD_SSL and configures the SSL connection.
  Include {{ letsencrypt_vhost_inc }}

  SSLCertificateFile      {{ letsencrypt_live_dir }}/MY_APP/fullchain.pem
  SSLCertificateKeyFile   {{ letsencrypt_live_dir }}/MY_APP/privkey.pem

  ErrorLog ${APACHE_LOG_DIR}/MY_APP-error.log
  CustomLog ${APACHE_LOG_DIR}/MY_APP-access.log combined

  ServerAdmin webmaster@MY_SERVER

  # SSL-secured applications must have this exception in order for certbot
  # certificate renewal to work without the need to take the web server down.
  # IMPORTANT! This directive must come before the ProxyPass directives!
  #
  # This enables certificate renewal without needing to stop the web server.
  # certbot usage: certbot certonly --webroot --webroot-path MY_PATH ...
  ProxyPassMatch ^/\.well-known/acme-challenge/ !

  ProxyPreserveHost On
  ProxyPass /        http://localhost:{{ ports.MY_APP }}/
  ProxyPassReverse / http://localhost:{{ ports.MY_APP }}/
  RequestHeader set X-Forwarded-Proto "https"
</VirtualHost>
```

## Sidekiq

The Dockerfile installs a service into `/etc/services/sidekiq` that runs
[Sidekiq][] in the app directory. The Sidekiq log is written to
`/shared/log/sidekiq.log`.

There is currently no sanity check, so make sure your `Gemfile` bundles
Sidekiq.

## Upgrading the app

To upgrade the app, call the `upgrade-app.sh` script that the `Dockerfile`
places in `/usr/local/bin`. The script will pull the app from the [Git][]
repository, migrate the database, precompile assets, and restart [Passenger][].

There is no good contingency plan for when any of these steps fail. The
`upgrade-app.sh` script provides only very limited support to roll back the
application to a previous state. One tool that is definitively better at this
is [Capistrano][].

## Data persistence

Data can be persisted with a Docker volume that is mounted onto `/shared`. The
maintenance scripts link several directories into `/shared`:

- `/home/dora/rails/vendor/bundle` (which contains the bundled Gems)
- `/home/dora/rails/log` (Rails' log files)

## SSH access

Dora enables the SSH daemon be default.

`passenger-docker` expects SSH logins by root. I have decided to restrict
SSH access to the `dora` user. Normally, the `dora` user is not allowed to log
into the container because `passenger-docker` (or `baseimage-docker` from which
it is derived) locks the `dora` user (who is still called `app` when this
happens). If you attempt to log in with SSH, the following message is logged to
`/var/log/auth.log`:

```plain
User not allowed dora because account is locked
```

Dora configures `sshd` to not allow root logins and not allow password logins.

To _ssh_ from a workstation into the container that is running on a server,
make use of the `ProxyCommand` configuration option of OpenSSH:

```bash
# ~/.ssh/config
Host my_rails_app
  HostName 172.22.0.22 # This is likely to change when the container is recreated
  User dora
  IdentityFile ~/.ssh/docker # Private key, must exist on your _workstation_!
  ProxyCommand ssh <your_server> -W %h:%p # -W enables STDIN/STDOUT redirection

```

Then you can simply log into your Rails container from your workstation:

```bash
ssh my_rails_app
```

## wkhtmltopdf support

To facilitate generating PDF files, Dora has built-in support to install
[wkhtmltopdf][]. When the container is started, Dora checks for the presence
of the `wkhtmltopdf` command. If it is not found, the binary will be downloaded
from Github and installed along with the required dependencies.

Define the `$NO_WKKHTMLTOPDF` environment variable with any value to prevent
Dora from installing [wkhtmltopdf][].

You can customize the download by overriding `$WKHTMLTOPDF_URL`. Just do not
forget to also place the SHA-256 checksum into `$WKHTMLTOPDF_SUM`.

## Status reports

If the environment variables `$RAILS_SMTP_FROM` and `$EMAIL_REPORTS_TO` are set,
dora will send a daily status e-mail that reports on the services inside the
container. Of course, this does not eliminate the need to properly monitor the
container in production.

## Development and testing

To use `dora` for development and testing, you may want to set `$GIT_PULL` to
`false` and mount your entire Rails application's directory onto `/home/dora`.

With `$GIT_PULL` set to `false`, it is assumed that the entire `/home/dora/rails`
directory is a mounted Docker volume. The bootstrapping script will _not_ link
directories to `/shared/...`. It _will_ however set Bundler's `path` config
option to `vendor/bundle` (even though it does not set `deployment` mode), so
that Gems are saved in the mounted volume. This speeds up rebuilding the
container.

`dora` ships with a generic `docker-compose.yml` file that can be customized
via environment variables. A `.env` file lends itself well to this
configuration. The composition consists of the rails app, Postgres, and Redis.
See `sample.env` for usage instructions.

### MailHog

`dora`'s Docker composition includes [MailHog][] to facilitate interacting with
e-mails on a development or staging machine. The web UI is exposed on the local
host's port 8025. MailHog is configured to store mails in `maildir` format,
which is a Docker volume on `${DORA_HOST_VOL_DIR}/mailhog`.

You can declare MailHog's [configuration variables][MailHog config] in your `.env`
file to adjust MailHog to your needs.

## Container time zone

`passenger-docker` does not configure a time zone for the container. Dora does
do it by installing the `tzdata` package and supporting a `$TIMEZONE` variable.
This variable _must_ be set to a directory and file unter `/usr/share/zoneinfo`,
e.g. `Europe/Berlin`.

To see all possible values for `$TIMEZONE`, issue:

```bash
find /usr/share/zoneinfo -follow | sed -E 's_(/[^/]+){3}/__'
```

## Logrotate

Log files in `/shared/log` will be logrotated on a daily basis for 14 days
before they are discarded.

## Troubleshooting

### Sending mail

If your mail server is secured by a firewall, make sure it accepts connections
from the Docker network.

### Receiving mail

To receive mail with your Rails app (and if not yet using [Action Mailbox][]),
you can configure a [Postfix][] mail transport like so:

```postfix
# /etc/postfix/master.cf
app           unix  -       n       n       -       -       pipe
  flags=DRhu user=USER:docker directory=/DIR/OF/DOCKER-COMPOSE-FILE argv=/usr/local/bin/docker-compose exec -T dora_rails_1 bash -c {(cd /home/dora/rails; bin/rails runner -e production bin/receive.rb ${extension})}
```

Replace `USER` with the user that owns the compose file. NB: It is imperative
to include the group `docker` in `user=USER:docker`, because otherwise
`docker-compose` will complain that it cannot connect to the Docker daemon,
even if `USER` is normally a member of the group `docker`. The group must be
stated explicitly (as I learned by trial and error).

The `receive.rb` file could look like this:

```ruby
require 'syslog/logger'
log = Syslog::Logger.new __FILE__
log.info "Entering #{__FILE__}"
input = STDIN.read
log.debug "E-Mail local extension: #{extension[0, 20]}"
MyMailer.receive input
log.info "Leaving #{__FILE__}"
```

### Database configuration

```yaml
# config/database.yml
default: &default
  adapter: postgresql
  host: <%= ENV['RAILS_DB_HOST'] %>
  database: <%= ENV['RAILS_DB_NAME'] %>
  username: <%= ENV['RAILS_DB_USER'] %>
  password: <%= ENV['RAILS_DB_PASS'] %>

development:
  <<: *default

test:
  <<: *default
  # Facilitate running tests in the development container
  database: <%= ENV['RAILS_DB_NAME'] %>_test

production:
  <<: *default

staging:
  <<: *default
```

### SMTP configuration

```ruby
# config/environments/production.rb
Rails.application.configure do
  # ...
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['RAILS_SMTP_HOST'],
    port: ENV['RAILS_SMTP_PORT'],
    user_name: ENV['RAILS_SMTP_USER'],
    password: ENV['RAILS_SMTP_PASS']
  # ...
end
```

### Required gems

```ruby
# Gemfile
gem 'sidekiq', '~> 5.2'
```

### Sidekiq configuration

```ruby
# frozen_string_literal: true

# config/initializers/sidekiq.rb
REDIS_HOST = 'redis://redis:6379/1' # may need to change Redis' db number

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_HOST }
end

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_HOST }
end
```

### Avoiding confusion

One thing that I initially had quite a hard time wrapping my head around is the
distinction between an image and a container. However, this distinction is
quite important in practice:

When the container is being built, any and all external dependencies such as
mounted volumes and of course the database server are _not available_. This
seems trivial, but I struggled with it initially.

The _container_ on the other hand has all these dependencies available, but it
may need some initial bootstrapping when it is first started. [Discourse][]
takes care of this with an external control script called `launcher`. I prefer
to have my container as atomic as possible. Therefore I decided to place the
bootstrapping commands in a script that is run whenever the container is
started, but checks for the presence of a sentinel file to decide whether
bootstrapping is needed or not. This avoids unnecessary and possibly time
consuming tasks such as precompiling assets, migrating the database and so on.

A note on the **user name** and **application directory**: `passenger-docker`
creates a user called `app`; this is hard-coded into the `passenger-docker`
image and cannot be changed without patching the upstream repository.
Starting with version 2.0.0, `dora` installs the application into a directory
in the main user's home directory that is called `rails`; previously, this directory
was also named `app`, resulting in confusing path names such as
`/home/dora/app/app`. Starting with version 3.0.0, the main user is renamed
to `dora` by the Dockerfile. Thus, the directory where the Rails application is
installed is:

```bash
/home/dora/rails
```

Initially I had intended to make the application directory configurable, but it
would have been overly complicated to adjust the Nginx server configuration to
this custom directory, at least if an environment variable was involved.
Therefore, the `rails` directory is now hard-coded into dora.

## Further reading

- [Discourse's Docker container][Discourse]

## License

(c) 2020-2021 Daniel Kraus (bovender).

MIT license. See [`LICENSE`](LICENSE).

[Action Mailbox]: https://guides.rubyonrails.org/action_mailbox_basics.html
[Ansible]: https://www.ansible.com
[Apache2]: https://httpd.apache.org
[Capistrano]: https://www.capistranorb.com
[Discourse]: https://www.discourse.org
[Docker]: https://www.docker.com
[docker-compose]: https://www.docker.com
[Git]: https://www.git-scm.com
[MailHog]: https://github.com/mailhog/MailHog
[MailHog config]: https://github.com/mailhog/MailHog/blob/master/docs/CONFIG.md
[Nginx]: https://www.nginx.com
[passenger-docker]: https://github.com/phusion/passenger-docker
[Passenger]: https://www.phusionpassenger.com
[Phusion]: https://www.phusion.nl
[Postfix]: https://postfix.org
[Ruby on Rails]: https://rubyonrails.org
[Sidekiq]: https://github.com/mperham/sidekiq
[wkhtmltopdf]: https://wkhtmltopdf.org
