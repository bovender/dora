# dora changelog

### Breaking change

- The app user and group were renamed from 'app' (passenger-docker's default)
  to 'dora' in order to further eliminate confusion. Now there is only one
  directory named 'app', and that is the said directory in a Rails application.
  **Important:** If you relay e-mails into your dora container as described in
  README.md, you will need to adjust the paths in your mail server configuration
  files, e.g. `master.cf` if you use Postfix.

### Fixed

- `rails-console.sh` now invokes `rails` as the `app` user.
- Removed the erroneous `server_name` directive from the Nginx site configuration
  file.

## Version 2.1.0 (2020-09-15)

### Improved

- Added a simple locking mechanism to the `upgrade-app.sh` script. When Git web
  hooks are invoked after a push to the repository, the upgrade script may be
  called twice in quick succession, once for the commits push and once for the
  tags push.

### Fixed

- Use `passenger-ruby27` rather than `passenger-ruby26` as base image.
- Copy the right `rails-console.sh` helper script into the image.
- Fix setting the `PATH` variable to include the path to the `bin` directory.
- The `rails` command in the `rails-console.sh` helper script was missing the
  actual command.
- The nodejs installation script now respects the container's operating
  system's code name.

### Changed

- Various rather cosmetic improvements to script output.

## Version 2.0.1 (2020-09-13)

### Fixed

- Revert setting `$HOME` to `/home/app/rails` as this caused the directory not
  to be empty any more after installing Bundler, which in turn caused `git clone`
  to fail.

## Version 2.0.0 (2020-09-13)

### Breaking change

- The directory structure was changed because `/home/app/app` was too confusing
  in practice, especially considering that a Rails app has an `app` folder
  itself, which results in a path `/home/app/app/app`. That was a bit too
  much. The main user `app` is "inherited" from Phusion's
  [passenger-docker](https://github.com/phusion/passenger-docker) image and
  cannot be changed; but the directory that the repository is cloned into was
  renamed from `app` to `rails`.
  **Important:** If you relay e-mails into your dora container as described in
  README.md, you may need to adjust the paths in your mail server configuration
  files, e.g. `master.cf` if you use Postfix.

### Changed

- `passenger-docker` has been updated from 1.0.9 to 1.0.11 which implies an
  upgrade of the default Ruby to 2.7.1 and and upgrade of Passenger to 6.0.6.

### New

- Added `restart-app.sh` helper script.
- Added `rails-console.sh` helper script.

### Fixed

- Logrotate now uses the `copytruncate` option.

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
