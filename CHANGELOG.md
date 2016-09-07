# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

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
