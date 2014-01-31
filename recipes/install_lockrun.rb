#
# Installs duplicity from source
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: duplicity-backup
# Recipe:: install_lockrun
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

src_dir = File.join(node['duplicity']['src_dir'], 'lockrun')
directory src_dir do
  action    :create
  owner     "root"
  group     "root"
  mode      0755
  recursive true
end

cookbook_file "#{src_dir}/lockrun.c" do
  action    :create
  owner     "root"
  group     "root"
  mode      0644  
end

execute "gcc lockrun.c -o lockrun" do
  action    :run
  cwd       src_dir
  user      "root"
  not_if    "which lockrun"
end

link "/usr/local/bin/lockrun" do
  action :create
  to     "#{src_dir}/lockrun"
end
