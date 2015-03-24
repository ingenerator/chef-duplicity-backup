#
# Installs duplicity from source
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: duplicity-backup
# Recipe:: backup_mysql_user
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

if node['duplicity']['backup_mysql'] then
  
  include_recipe('database::mysql')
  
  root_connection = { 
    :host     => 'localhost', 
    :username => 'root', 
    :password => node['mysql']['server_root_password'] 
  }
  
  mysql_database_user node['duplicity']['mysql']['user'] do
    action        :grant
    connection    root_connection
    host          'localhost'
    password      node['duplicity']['mysql']['password']
    privileges    ['SELECT', 'SHOW VIEW', 'TRIGGER', 'LOCK TABLES']
  end
  
end
