#
# Installs duplicity from source
#
# Author::  Alexey Vasyliev (<leopard.not.a@gmail.com>)
# Cookbook Name:: duplicity-backup
# Recipe:: backup_postgresqluser
#
# Copyright 2014-12, inGenerator Ltd
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

if node['duplicity']['backup_postgresql'] then

  include_recipe "database::postgresql"

  postgresql_connection_info = {
    :host => node['duplicity']['postgresql']['host'],
    :port => node['duplicity']['postgresql']['port'],
    :username => 'postgres',
    :password => node['postgresql']['password']['postgres']
  }

  postgresql_database_user node['duplicity']['postgresql']['user'] do
    connection postgresql_connection_info
    password node['duplicity']['postgresql']['password']
    action :create
  end

  postgresql_database 'alter pg user' do
    connection      postgresql_connection_info
    database_name   'postgres'
    sql "ALTER USER #{node['duplicity']['postgresql']['user']} WITH SUPERUSER;"
    action :query
  end

end