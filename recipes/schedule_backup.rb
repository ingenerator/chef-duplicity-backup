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
if defined_schedule.empty? then
  raise ArgumentError, "You must define at least one schedule attribute for the backup job, or it would run every minute!"
end

cron "duplicity_backup" do
  action  :create
  command node['duplicity']['cron_command']
  mailto  node['duplicity']['mailto']
  minute  node['duplicity']['schedule']['minute']
  hour    node['duplicity']['schedule']['hour']  
  day     node['duplicity']['schedule']['day']   
  weekday node['duplicity']['schedule']['weekday'] 
  month   node['duplicity']['schedule']['month']   
end