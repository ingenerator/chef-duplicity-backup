#
# Creates the cron entry to run the backup
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: duplicity-backup
# Recipe:: schedule_backup
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

defined_schedule = node['duplicity']['schedule'].select { | period, value | ! value.nil? }

include_recipe 'monitored-cron::default'

monitored_cron 'duplicity-backup' do
  action       :create
  command      '/etc/duplicity/backup.sh'
  schedule     defined_schedule
  require_lock true
  notify_url   node['duplicity']['success_notify_url'] if node['duplicity']['success_notify_url']
end

# If there still a legacy (<2.x) cron job provisioned, get rid of it
cron "duplicity_backup" do
  action  :delete
end
