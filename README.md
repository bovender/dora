# dora

## *DO*cker container for *RA*ils

This is a little project that helps me to set up and operate
[Docker][] containers for [Ruby on Rails][] apps. It builds
upon the [passenger-docker][] container by [Phusion][], the
makers of the [Passenger][] app server.

The Dockerfile and the maintenance scripts are generic.
Customization for specific apps happens through Docker build
`ARGS` and environment variables.

> If you stumble upon this, be advised that this is amateur
work. It may suit your needs, but it was mainly created to
help me with my own projects. I would be more than happy though
to take pull request to improve this.

An alternative and much more sophisticated approach to
Dockerizing a Rails app can be found at [Discourse][].

## Customization

Customization is done with environment variables.

| Environment variable | Use | Default
|------|------|------
| `APP_NAME` | Application name | `app`
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
| `RAILS_SECRET_KEY` | Rails' secret key base |

### YAML snippet for docker-compose

To use this with [docker-compose][], clone the repository,
then add the following snippet to your `docker-compose.yml`
file and customize it (e.g., replace `MY_APP` with something
else).

The bracketed bits (`{{ ... }}`) are [Ansible][] variables.
If you do not use Ansible, just replace them with something
else.

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
      GIT_REPO: "{{ MY_APP.git.repo}} "
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
      RAILS_SECRET_KEY: "{{ MY_APP.secret_key }}"
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

Snippet for Ansible's `defaults/main.yml` file (I define all variables
here, even those with a default value, to prevent surprises in the
future):

```yaml
docker:
  volume_dir: /home/ME/docker-data
ports:
  # This is the port that is exposed internally on the host
  MY_APP: 8080
MY_APP:
  name:
  secret_key:
  git:
    repo:
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

Remember to use `ansible-vault encrypt_string` to hash all
passwords!

> **WARNING:** Even then using `ansible-vault` to encrypt all
secrets in your Ansible repository, be aware that they will
appear unencrypted in the `docker-compose.yml` file that is
deployed on the server!

Please ensure your secrets are safe.

### Using ENV in your Rails app

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

I use [Apache2][] as a reverse proxy to relay requests from
the Docker host to the container. This can of course also be
done with [Nginx][] or any other web server that can act as
a reverse proxy, but I have more experience with Apache.

NB: This is an [Ansible][] template with some Ansible variables
in it.

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

The Dockerfile installs a service into `/etc/services/sidekiq`
that runs [Sidekiq][] in the app directory. The Sidekiq log is
written to `/shared/log/sidekiq.log`.

There is currently no sanity check, so make sure your `Gemfile`
bundles Sidekiq.

## Upgrading the app

To upgrade the app, call the `upgrade-app.sh` script that
the `Dockerfile` places in `/usr/local/bin`. The script will
pull the app from the [Git][] repository, migrate the database,
precompile assets, and restart [Passenger][].

There is no good contingency plan for when any of these steps
fail. Rolling back the application to a former version is
currently not supported (unlike, for example, when you
deploy your app using [Capistrano][].)

## Data persistence

Data can be persisted with a Docker volume that is mounted
onto `/shared`. The maintenance scripts link several directories
into `/shared`:

- `/home/app/app/vendor/bundle` (which contains the bundled Gems)
- `/home/app/app/log` (Rails' log files)


## Troubleshooting

### Sending mail

If your mail server is secured by a firewall, make sure
it accepts connections from the Docker network.

### Avoiding confusion

One thing that I initially had quite a hard time wrapping my
head around is the distinction between an image and a container.
However, this distinction is quite important in practice:

When the container is being built, any and all external
dependencies such as mounted volumes and of course the
database server are _not available_. This seems trivial, but
I struggled with it initially.

The _container_ on the other hand has all these dependencies
available, but it may need some initial bootstrapping when
it is first started. [Discourse][] takes care of this with
an external control script called `launcher`. I prefer to
have my container as atomic as possible. Therefore I
decided to place the bootstrapping commands in a script that
is run whenever the container is started, but checks for the
presence of a sentinel file to decide whether bootstrapping
is needed or not. This avoids unnecessary and possibly time
consuming tasks such as precompiling assets, migrating the
database and so on.

## Further reading
- [Discourse's Docker container][Discourse]

## License

(c) 2020 Daniel Kraus (bovender).

MIT license. See [`LICENSE`](LICENSE).

[Ansible]: https://www.ansible.com
[Apache2]: https://httpd.apache.org
[Capistrano]: https://www.capistranorb.com
[Discourse]: https://www.discourse.org
[Docker]: https://www.docker.com
[docker-compose]: https://www.docker.com
[Git]: https://www.git-scm.com
[Nginx]: https://www.nginx.com
[passenger-docker]: https://github.com/phusion/passenger-docker
[Passenger]: https://www.phusionpassenger.com
[Phusion]: https://www.phusion.nl
[Sidekiq]: https://github.com/mperham/sidekiq
