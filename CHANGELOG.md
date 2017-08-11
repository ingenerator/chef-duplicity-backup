# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

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
