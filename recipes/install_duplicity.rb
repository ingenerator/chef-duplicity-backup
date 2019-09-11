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
python_runtime '2.7' do
  # This is a workaround for https://github.com/poise/poise-python/issues/146, by using a custom get_pip_url we skip
  # the internal check to see if the url needs to be switched to a python 2.6 compatible one. That in turn avoids
  # poise-python attempting to parse an operating system package version as a gem version string, which currently
  # throws an exception as the debian python version 2.7.15+ is not a valid gem version.
  get_pip_url 'https://bootstrap.pypa.io/get-pip.py#skip-poise-python-2.6-check'
end
python_package 'lockfile'
python_package 'fasteners'
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
