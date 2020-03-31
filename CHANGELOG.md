# dora changelog

## Version 1.6.1 (2020-03-31)

### Fixed

- Explicitly mention SMTP-related environment variables in `docker-compose.yml`
  so they are properly picked up from the current environment.

## Version 1.6.0 (2020-03-29)

### New

- Add [MailHog](https://github.com/mailhog/MailHog) to `docker-compose`.
- Added logrotate configuration for `/shared/log/*.log`.

## Version 1.5.2 (2020-03-14)

### Improved

- Expanded [README.md](README.md) with more instructions to configure the
  Rails application.

### Fixed

- Always git-describe repository, even if there are no tags.

## Version 1.5.1 (2020-03-11)

### Fixed

- Set Sidekiq environment to `$PASSENGER_APP_ENV`.

## Version 1.5.0 (2020-03-11)

### New feature

- `$PATH` is prepended with `/home/app/app/bin` by `bootstrap-container.sh` in
  order to make Rails scripts easily accessible.
- The image now comes with ImageMagick installed.

### Fixed

- Local Bundler configuration is now properly set.
- Add suggestions to configure Postfix to let the Rails app receive mail.

## Version 1.4.1 (2020-03-08)

### Changed

- Git repository is described to `tmp/version` rather than `public/version`.

## Version 1.3.0 (2020-03-08)

### New features

- Git repository is 'described' to `public/version`.
- Add a `WEBHOOK_SECRET` environment variable.

### Improved

- Tag adminer at version ~> 4.7.

## Version 1.2.0 (2020-03-06)

### New feature

- Configure the container's time zone using the `$TIMEZONE` environment
  variable.
  
## Version 1.1.0 (2020-03-06)

### New feature

- Install [wkhtmltopdf](https://wkhtmltopdf.org/index.html) unless the
  environment variable `$NO_WKHTMLTOPDF` is defined.

## Version 1.0.0 (2020-03-06)

Initial release.
