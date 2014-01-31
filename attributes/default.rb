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

# The URL for the duplicity source
default['duplicity']['src_url'] = 'http://code.launchpad.net/duplicity/0.6-series/0.6.23/+download/duplicity-0.6.23.tar.gz'

# The local directory to place the source
default['duplicity']['src_dir'] = '/usr/local/src'

# The globbing patterns for file backup
default['duplicity']['globbing_file_patterns'] = node['duplicity']['globbing_file_patterns'] || {}


# Configuration for a mysql dump to be run before backing up
default['duplicity']['backup_mysql']   = false
default['duplicity']['mysql_user']     = nil
default['duplicity']['mysql_password'] = nil
# Set innodb_only false if you are using any tables with other storage engines
# This will disable the use of the --single-transaction mysqldump mode which will otherwise allow you to backup innodb without long locks
default['duplicity']['mysql']['innodb_only'] = true


# Remote backup destinations - see the duplicity documentation for options
default['duplicity']['db_destination']   = nil
default['duplicity']['file_destination'] = nil
