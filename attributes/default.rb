#
# Author:: Andrew Coulton(<andrew@ingenerator.com>)
# Cookbook Name:: duplicity-backup
# Attribute:: default
#
# Copyright 2013-14, inGenerator Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# URL for the duplicity source
default['duplicity']['src_url'] = 'https://code.launchpad.net/duplicity/0.7-series/0.7.13.1/+download/duplicity-0.7.13.1.tar.gz'

# local directory to place the source in
default['duplicity']['src_dir'] = '/usr/local/src'

# Local directory path to the local archives for each job used to manage local signatures etc
default['duplicity']['archive_dir'] = '/var/duplicity/archive'

# Local directory path to dump database files for backup
default['duplicity']['dump_base_dir'] = '/var/duplicity/sources'

# globbing patterns for file backup
default['duplicity']['globbing_file_patterns'] = node['duplicity']['globbing_file_patterns'] || {}

# backup passphrase
default['duplicity']['backup_passphrase'] = nil

# Other environment variables to set for the backup process - will be placed in a secure script
default['duplicity']['duplicity_environment'] = node['duplicity']['duplicity_environment'] || {}

# Configuration for a mysql dump to be run before backing up
default['duplicity']['backup_mysql']      = false
default['duplicity']['mysql']['user']     = 'backup'
default['duplicity']['mysql']['password'] = nil
# Set innodb_only false if you are using any tables with other storage engines
# This will disable the use of the --single-transaction mysqldump mode which will otherwise allow you to backup innodb without long locks
default['duplicity']['mysql']['innodb_only'] = true

# Configuration for a postgresql dump to be run before backing up
default['duplicity']['backup_postgresql']       = false
default['duplicity']['postgresql']['host']      = 'localhost'
default['duplicity']['postgresql']['port']      = 5432
default['duplicity']['postgresql']['user']      = nil
default['duplicity']['postgresql']['password']  = nil


# Remote backup destinations - see the duplicity documentation for options
default['duplicity']['db_destination']   = nil
default['duplicity']['pg_destination']   = nil
default['duplicity']['file_destination'] = nil

# Set how often a full backup (rather than incremental) should be run
default['duplicity']['full_if_older_than'] = nil

# Set how many full backup sets should be kept
default['duplicity']['keep_n_full']        = nil

# Use S3 european buckets
default['duplicity']['s3-european-buckets'] = true

# Set the schedule - missing values will be set to '*'
default['duplicity']['schedule']['minute']  = nil
default['duplicity']['schedule']['hour']    = nil
default['duplicity']['schedule']['day']     = nil
default['duplicity']['schedule']['weekday'] = nil
default['duplicity']['schedule']['month']   = nil

# A URL to ping (get) with a notification when the backup completes
# Optionally include :runtime: anywhere in it to have it replaced with the backup
# runtime in seconds
default['duplicity']['success_notify_url'] = nil
