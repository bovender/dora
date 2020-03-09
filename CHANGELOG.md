# dora changelog

## UNRELEASED

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
