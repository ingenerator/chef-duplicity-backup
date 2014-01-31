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

directory "/etc/duplicity" do
  action :create
  mode   0755
  owner  "root"
  group  "root"
end

template "/etc/duplicity/globbing_file_list" do
  action :create
  mode   0644
  owner  "root"
  group  "root"
end

template "/etc/duplicity/backup.sh" do
  action :create
  mode   0744
  owner  "root"
  group  "root"
end