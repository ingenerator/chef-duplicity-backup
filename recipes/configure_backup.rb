#
# Configures the backup job - writes the backup script and the file list
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: duplicity-backup
# Recipe:: configure_backup
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

# Validate the attributes (most are now validated in the CommandBuilder helpers)
Ingenerator::DuplicityBackup.require_attribute!(node, 'duplicity.backup_passphrase')

if node['duplicity']['backup_mysql'] then
  Ingenerator::DuplicityBackup.require_attribute!(node, 'duplicity.mysql.user')
  Ingenerator::DuplicityBackup.require_attribute!(node, 'duplicity.mysql.password')
end

if node['duplicity']['backup_postgresql'] then
  Ingenerator::DuplicityBackup.require_attribute!(node, 'duplicity.postgresql.user')
  Ingenerator::DuplicityBackup.require_attribute!(node, 'duplicity.postgresql.password')
end

node['duplicity']['globbing_file_patterns'].each do | pattern, is_active |
  if is_active && (pattern[-1] == '/')
    raise(
      ArgumentError,
      'You must not use a trailing slash on globbing patterns : this would tell duplicity to back up an empty tree with no files'
    )
  end
end

directory "/etc/duplicity" do
  action :create
  mode   0755
  owner  "root"
  group  "root"
end

# The list of files to include or exclude
template "/etc/duplicity/globbing_file_list" do
  action :create
  mode   0644
  owner  "root"
  group  "root"
end

# The backup script itself - this will become the cron target
template "/etc/duplicity/backup.sh" do
  action :create
  mode   0744
  owner  "root"
  group  "root"
  variables({
    commands: Ingenerator::DuplicityBackup::CommandBuilder.new(node)
  })
end

# Environment variables to provide to duplicity (eg AWS keys)
template "/etc/duplicity/environment.sh" do
  action :create
  mode   0700
  owner  "root"
  group  "root"
end

# Mysql credentials for the backup script
template "/etc/duplicity/mysql.cnf" do
  action :create
  mode   0600
  owner  "root"
  group  "root"
end

# PostgreSQL credentials for the backup script
template "/etc/duplicity/.pgpass" do
  source "pgpass.erb"
  action :create
  mode   0600
  owner  "root"
  group  "root"
end
