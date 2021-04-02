# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

# 4.1.3 (2021-04-02)

* [BUG] Pin the pypi get_pip URL for python 2.7 (pypa is evidently now 
  returning a newer / incompatible version by default)

# 4.1.2 (2020-08-01)

* [UPSTREAM BUG] Mysql >= 5.7.31 introduces a new requirement for the backup user to have the `PROCESS` privilege :
  backups will fail without it. https://dev.mysql.com/doc/relnotes/mysql/5.7/en/news-5-7-31.html and 
  https://bugs.mysql.com/bug.php?id=100219.

## 4.1.1 (2019-09-11)

* [UPSTREAM BUG] Workaround for https://github.com/poise/poise-python/issues/146 which causes pip install to fail on
  the current debian python version of 2.7.15+ - as the cookbook is abandoned it's unlikely this will be fixed upstream.

## 4.1.0 (2019-03-12)

* [DEPS] Pin seven_zip to a version that works for Chef12 in our berksfile - this shouldn't
  affect external dependencies, but only apply to testing?
* [DEPS] Mark not compatible with postgresql cookbook 7.0 and above - they deleted
  all the recipes (described in the changelog as 'deprecated' but actually outright gone)
* [BUG] Don't allow the mysql handler to attempt to backup the `sys` schema : 
  it causes problems with permissions

## 4.0.0 (2017-08-15)

* [FEATURE] Provision a simple restore script that allows restoring from
  any arbitrary source, or from one of the current instance backup
  destinations.
* [BREAKING] Consistently use the **same** archive directory for every user.
  Previously we were falling back to the default $HOME/.cache/duplicity but
  this causes hassle when running occasional restore / backup manually. If you
  deploy this to an existing instance, duplicity will have to fully re-sync its
  local cached manifests and signatures on the next run. You can avoid this by
  manually moving /root/.cache/duplicity to /var/duplicity/archive on the first
  deployment.
* [BREAKING] Disable `--allow-source-mismatch` for database backups. Previously
  we set this to allow use of a dynamic temporary directory for each backup.
  However, this also then allows backups to be overwritten from any host with
  the same configuration. Instead, database dumps are now always sent to the
  same path (which will be wiped and recreated each time) and duplicity will
  fail if the backup source (path or host) has changed at a given destination.
* Extracted backup command generation from the template to a custom helper,
  and refactored specs for the configure_backup recipe to stub the helper
  and reflect the new responsibilities. This allows for clearer and more
  rigorous specification of individual commands rather than having all the
  logic in the template rendering
* Some internal refactoring of specs for speed and legibility
* Update to duplicity 0.7.13.1
* Update to poise-python 1.6 for Chef 13 support
* Ignore build-time files from the vendored cookbook
* Update build dependencies and build against Chef 12 and Chef 13 (drops support for < 12.18.31)

# 3.0.0 / 2017-02-17

* [BREAKING] Switch from deprecated `python` cookbook to `poise-python` for
  installing duplicity's python dependencies.
* Support database cookbook 6.x series - the breaking change at 6.0 doesn't
  affect this cookbook.
* [BREAKING] Disables use of a trailing / on globbing file patterns : this
  syntax causes duplicity to back up empty tree structures with no files. Since
  this is potentially very dangerous, I've disabled it.
* [BREAKING] Replaces the standard `cron` resource with `monitored_cron`, and:
  * **deletes** any old `duplicity_backup` cron entry
  * **deletes** the previous `duplicity-backup::install_lockrun` recipe and
    related attributes
  * **removes** the duplicity `cron_command` attribute
  * **removes** the duplicity `mailto` attribute
  * installs a new `monitored-duplicity-backup` cron using the wrapper script
  * adds new optional attributes to configure a notification URL

## 2.0.0 / 2016-09-07

* [BREAKING] Update to latest version of the database cookbook - note you
  *must* now install the mysql2_chef_gem yourself before use - this is no
  longer handled by this cookbook to minimise hard dependencies. See the
  README.

## 1.1.3 / 2016-09-07

* [DEV] Update chefspec/chef dependencies and specs to resolve deprecation
  warnings

## 1.1.2 / 2016-04-05

* [BUG] mysql backup script is still failing due to issues with --events flag

## 1.1.1 / 2016-04-05

* [BUG] mysqldump user requires the `EVENT` privilege to backup events
* [BUG] backup script should fail if mysqldump fails

## 1.1.0 / 2016-03-29

* [DEV] Update to latest berkshelf, chefspec, foodcritic & ruby versions,
        includes various fixes to get specs running (and at acceptable
        speed) again with the new version.
* [BUG] Add --events option to backup mysql.event and suppress warning

## 1.0.1 / 2016-02-19

* [HOTFIX] Update version number in metadata, not properly set in 1.0.0

## 1.0.0 / 2010-02-19

* [FEATURE] First stable release - all the features!
