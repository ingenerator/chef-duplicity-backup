#
# Installs duplicity from source
#
# Author::  Andrew Coulton (<andrew@ingenerator.com>)
# Cookbook Name:: duplicity-backup
# Recipe:: install_duplicity
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

# Install the dependencies for build and for all the various backends
include_recipe "python::pip"
python_pip "lockfile"
package "ncftp"
package "python-paramiko"
package "python-pycryptopp"
package "lftp"
package "python-boto"
package "python-dev"
package "librsync-dev"

src_name = File.basename(node['duplicity']['src_url'])
src_path = File.join(node['duplicity']['src_dir'], src_name)

remote_file src_path do
  action   :create_if_missing
  source   node['duplicity']['src_url']
  owner    "root"
  group    "root"
  mode     0644
  backup   false
  notifies :run, "execute[install-duplicity]", :immediately
end

# Always build if the executable isn't there - could be a previous failed provision
default_action = Kernel.system('which duplicity > /dev/null') ? :nothing : :run
unpack_dir_name = File.basename(src_name, '.tar.gz')

execute "install-duplicity" do
  action   default_action
  command  "tar xf #{src_name} && cd #{unpack_dir_name} && python setup.py install"
  user     "root"
  group    "root"
  cwd      node['duplicity']['src_dir']  
end