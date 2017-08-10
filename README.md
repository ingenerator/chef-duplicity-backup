inGenerator Backup cookbook
=================================
[![Build Status](https://travis-ci.org/ingenerator/chef-duplicity-backup.png?branch=4.0.x)](https://travis-ci.org/ingenerator/chef-duplicity-backup)

`duplicity-backup` installs and configures [duplicity](http://duplicity.nongnu.org/) to handle remote backup of files
and/or databases on a server. It also installs [lockrun](http://www.unixwiz.net/tools/lockrun.html) and
uses this to ensure that your duplicity runs never overlap (which can cause resource exhaustion and backup corruption).

Requirements
------------
- Chef 12.18 or higher
- **Ruby 1.9.3 or higher**

Installation
------------
We recommend adding to your `Berksfile` and using [Berkshelf](http://berkshelf.com/):

```ruby
source 'https://chef-supermarket.ingenerator.com'
cookbook 'duplicity-backup', '~>4.0'
```

Have your main project cookbook *depend* on duplicity-backup by editing the `metadata.rb` for your cookbook.

```ruby
# metadata.rb
depends 'duplicity-backup'
```

If you want to backup a mysql database, you will also need to install the `mysql2` gem -
to allow the cookbook to manage users - this is not handled by the cookbook.

You can do this by depending on the `mysql2_chef_gem` cookbook and adding the following
resource definition to a recipe of your own:

```ruby
# Your own recipe, called before referencing duplicity-backup
mysql2_chef_gem 'default' do
  action :install
end
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

| Recipe                  | Action                                                                                              |
|-------------------------|-----------------------------------------------------------------------------------------------------|
| install_duplicity       | Installs duplicity itself                                                                           |
| configure_backup        | Deploys the backup script and file list                                                             |
| backup_mysql_user       | Creates a read-only database user for running backups, if database backup is configured             |
| backup_postgresql_user  | Creates a PostgreSQL database user for running backups, if database backup is configured            |
| schedule_backup         | Creates the cron task(s) for your backup                                                            |

**Note that including the backup_mysql_user recipe causes chef to include the mysql client recipe, which will run before
  all other recipes in your cookbook.**

Output and any errors will be logged to syslog.

To customise behaviour, include any or all of these recipes directly rather than relying on the default.

Attributes
----------

There are several attributes that you *must* set before this recipe will work. We recommend using an encrypted data bag to
store these, for obvious reasons.

If any of these attributes are not set, the cookbook will raise an ArgumentError.

| Attribute                                    | Set to                                                                                        |
|----------------------------------------------|-----------------------------------------------------------------------------------------------|
| `node['duplicity']['backup_passphrase']`     | The GnuPG passphrase to use for your backup                                                   |
| `node['duplicity']['duplicity_environment']` | A hash of environment variables to set for the duplicity backup run (eg for authentication)   |
| `node['duplicity']['file_destination']`      | The remote path where your files should be backed up                                          |
| `node['duplicity']['db_destination']`        | The remote path where your database dumps should be backed up                                 |
| `node['duplicity']['pg_destination']`        | The remote path where your PostgreSQL database dumps should be backed up                      |
| `node['duplicity']['backup_mysql']`          | True to enable backup of a mysql database                                                     |
| `node['duplicity']['mysql']['password']`     | Password for the mysql user account that will run backups - the username defaults to 'backup' |
| `node['duplicity']['backup_postgresql']`     | True to enable backup of a PostgreSQL database                                                |
| `node['duplicity']['postgresql']['user']`    | User for the postgresql user account that will run backups                                    |
| `node['duplicity']['postgresql']['password']`| Password for the postgresql user account that will run backups                                |
| `node['duplicity']['full_if_older_than']`    | How often to run a full backup - backups in between will be incremental. See http://duplicity.nongnu.org/duplicity.1.html#sect9 |
| `node['duplicity']['keep_n_full']`           | The number of full backups to keep - older backups will be purged                             |
| `node['duplicity']['schedule']`              | A cron schedule for your backup task - a hash of {day, hour, minute, month, weekday}          |


Other attributes are available to provide more control - see the attributes files in the cookbook for more details.

Configuring for backup to S3
----------------------------
Our usual strategy is to backup to an S3 bucket for the project, with separate paths in the bucket for the database and file backups. If there
are multiple servers with file backups then we'll use a different destination path for each role - but usually we're only interested in uploaded
user content, custom instance configuration and databases as everything else on the instance is provisioned from source control.

To get this working:
### Create an S3 bucket for the backups

Create a bucket on EC2 and store the destination in your role attributes. For a bucket `my-app-backup` you'll want to set:

```ruby
node.default['duplicity']['file_destination'] = 's3+http://my-app-backup/files'
node.default['duplicity']['db_destination'] = 's3+http://my-app-backup/database'
node.default['duplicity']['pg_destination'] = 's3+http://my-app-backup/pg_database'
```

**We default to setting the --s3-european-buckets flag for duplicity. This should work with buckets outside the EU as well, but
  if you have issues you can set `node['duplicity']['s3-european-buckets']` to false.**

### Create an IAM user for the application backups

You should create a separate AWS IAM user for the application backups, with only the required S3 permissions. This user's keys will be stored
in plain text on disk, so should be as restricted as possible.

Set a policy like:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Sid": "Stmt1374798157000",
      "Resource": [
        "arn:aws:s3:::my-app-backup"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Sid": "Stmt1374798157001",
      "Resource": [
        "arn:aws:s3:::my-app-backup/*"
      ],
      "Effect": "Allow"
    }
  ]
}
```

Grab the user's access key and secret access key and add them to your role attributes like this:

```ruby
# Note: you almost certainly want to store these in an encrypted data bag, not in plain text in your repo...
node.default['duplicity']['duplicity_environment']['AWS_ACCESS_KEY_ID'] = 'foo'
node.default['duplicity']['duplicity_environment']['AWS_SECRET_ACCESS_KEY'] = 'bar'
```

### Set the general configuration for file backups

```ruby
# -- Configure the list of files to include
# Note we use a hash to make merging more predictable, and to allow you to disable a path in a higher cookbook
# Set the value false and the pattern will be skipped.
node.default['duplicity']['globbing_file_patterns']['/var/www/uploads'] = true

# You can also exclude particular file patterns
node.default['duplicity']['globbing_file_patterns']['- /var/www/uploads/.thumbs'] = true

# Set a passphrase to protect your backup - again, from an encrypted data bag ideally
node.default['duplicity']['backup_passphrase'] = 'abcdefg'

# Configure how often to take a full backup (incremental backups will be performed between these runs)
# This takes a full backup every 5 days
node.default['duplicity']['full_if_older_than'] = '5D'

# Configure how many successful full backups to keep (older ones will be purged)
node.default['duplicity']['keep_n_full'] = 5

# And configure the backup cron schedule - any missing schedule columns will be set to '*'
# This entry (with no other attributes) will run daily at 3am
node.default['duplicity']['schedule']['hour'] = 3
```

### Set the general configuration for database backups
```ruby
# Activate backups
node.default['duplicity']['backup_mysql'] = true

# Choose a password for the database backup user that will be created by this cookbook
node.default['duplicity']['mysql']['password'] = 'from-an-encrypted-data-bag'

# Optionally, if you have tables not using innodb, disable the single-transaction flag to mysqldump
# This is the only reliable way to dump eg MyISAM, but requires a global lock which will impact production performance
# If you're doing this, consider running a replicated slave to backup from instead
node.default['duplicity']['mysql']['innodb_only'] = false

# Activate backup for PostgreSQL
node.default['duplicity']['backup_postgresql'] = true

# Choose a user and password for the PostgreSQL backup user that will be created by this cookbook
# WARNING: will be created SUPERUSER user to do pg_dumpall
node.default['duplicity']['postgresql']['user'] = 'backup_user'
node.default['duplicity']['postgresql']['password'] = 'from-an-encrypted-data-bag'
```

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
