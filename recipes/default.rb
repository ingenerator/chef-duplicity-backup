#
# Installs all requirements, configures and schedules the backup script
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: duplicity-backup
# Recipe:: default
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

include_recipe "duplicity-backup::install_duplicity"
include_recipe "duplicity-backup::install_lockrun"
include_recipe "duplicity-backup::configure_backup"
include_recipe "duplicity-backup::backup_mysql_user"
include_recipe "duplicity-backup::backup_postgresql_user"
include_recipe "duplicity-backup::schedule_backup"