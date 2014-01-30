inGenerator Backup cookbook
=================================
[![Build Status](https://travis-ci.org/ingenerator/chef-duplicity-backup.png?branch=master)](https://travis-ci.org/ingenerator/chef-duplicity-backup)

`duplicity-backup` installs and configures [duplicity](http://duplicity.nongnu.org/) to handle remote backup of files 
and/or databases on a server. It also installs [lockrun](http://www.unixwiz.net/tools/lockrun.html) and 
uses this to ensure that your duplicity runs never overlap (which can cause resource exhaustion and backup corruption).

Requirements
------------
- Chef 11 or higher
- **Ruby 1.9.3 or higher**

Installation
------------
We recommend adding to your `Berksfile` and using [Berkshelf](http://berkshelf.com/):

```ruby
cookbook 'duplicity-backup', git: 'git://github.com/ingenerator/duplicity-backup', branch: 'master'
```

Have your main project cookbook *depend* on duplicity-backup by editing the `metadata.rb` for your cookbook. 

```ruby
# metadata.rb
depends 'duplicity-backup'
```

Usage
-----

For simple cases, set the required attributes (see below) and add the default recipe to your `run_list`:
```ruby
# In a role
"run_list" : [
  "recipe[duplicity-backup::default]"
]

# In a recipe - note your cookbook must declare a dependency in metadata.rb as above
include_recipe "duplicity-backup::default"
```

The default recipe executes the following steps:

| Recipe            | Action                                                                                              |
|-------------------|-----------------------------------------------------------------------------------------------------|
| install_duplicity | Installs duplicity itself                                                                           |
| install_lockrun   | Installs and builds lockrun                                                                         |
| configure_backup  | Deploys the backup script and file list                                                             |
| backup_mysql_user | Creates a read-only database user for running backups, if database backup is configured             |
| schedule_backup   | Creates the cron task(s) for your backup                                                            |

**Note that including the backup_mysql_user recipe causes chef to include the mysql client recipe, which will run before
  all other recipes in your cookbook.**
  
To customise behaviour, include any or all of these recipes directly rather than relying on the default.

Attributes
----------

There are several attributes that you *must* set before this recipe will work. We recommend using an encrypted data bag to
store these, for obvious reasons.

| Attribute                                    | Set to                                                                                      |
|----------------------------------------------|---------------------------------------------------------------------------------------------|
| `node['duplicity']['backup_passphrase']`     | The GnuPG passphrase to use for your backup                                                 |
| `node['duplicity']['duplicity_environment']` | A hash of environment variables to set for the duplicity backup run (eg for authentication) |
| `node['duplicity']['file_destination']`      | The remote path where your files should be backed up                                        |
| `node['duplicity']['db_destination']`        | The remote path where your database dumps should be backed up                               |
| `node['duplicity']['backup_mysql']`          | True to enable backup of a mysql database                                                   |
| `node['duplicity']['mysql']['user']`         | The mysql user to run backups as - this user will be created and granted full read access   |
| `node['duplicity']['mysql']['password']`     | Password for the mysql user account                                                         |
| `node['duplicity']['full_if_older_than']     | How often to run a full backup - backups in between will be incremental. See http://duplicity.nongnu.org/duplicity.1.html#sect9 |
| `node['duplicity']['keep_n_full']            | The number of full backups to keep - older backups will be purged                           |
| `node['duplicity']['schedule']`              | A cron schedule for your backup task - a hash of {day, hour, minute, month, weekday}        |
| `node['duplicity']['mailto']`                | What the cron MAILTO variable should be set to                                              |

Other attributes are available to provide more control - see the attributes files in the cookbook for more details.

We generally backup to an S3 bucket. To make this work, provide a destination URL like `s3+http://{bucket-name}/{path-in-bucket}`. You will also
need to provide AWS credentials - an AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY - which should be added to the `duplicity_environment` hash. We
suggest creating an IAM user specifically for this job and storing the credentials in an encrypted data bag.

**Note that by default - because we're over this side of the world - the default configuration we use for an S3 destination is for european
  buckets. You may want to set `node['duplicity']['s3-european-buckets']` false to avoid that.**

### Testing
See the [.travis.yml](.travis.yml) file for the current test scripts.

Contributing
------------
1. Fork the project
2. Create a feature branch corresponding to your change
3. Create specs for your change
4. Create your changes
4. Create a Pull Request on github

License & Authors
-----------------
- Author:: Andrew Coulton (andrew@ingenerator.com)

```text
Copyright 2013-2014, inGenerator Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```