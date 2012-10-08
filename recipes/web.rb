#
# Cookbook Name:: graphite
# Recipe:: web
#
# Copyright 2012, Heavy Water Operations, LLC (OR)
# Copyright 2011, Heavy Water Software Inc.
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

include_recipe "apache2::mod_python"

basedir = node['graphite']['base_dir']
version = node['graphite']['version']
pyver = node['graphite']['python_version']

package "python-cairo-dev"
package "python-django"
package "python-django-tagging"
package "python-memcache"
package "python-rrdtool"

remote_file "/usr/src/graphite-web-#{version}.tar.gz" do
  source node['graphite']['graphite_web']['uri']
  checksum node['graphite']['graphite_web']['checksum']
end

execute "untar graphite-web" do
  command "tar xzf graphite-web-#{version}.tar.gz"
  creates "/usr/src/graphite-web-#{version}"
  cwd "/usr/src"
end

execute "install graphite-web" do
  command "python setup.py install"
  creates "#{node['graphite']['doc_root']}/graphite_web-#{version}-py#{pyver}.egg-info"
  cwd "/usr/src/graphite-web-#{version}"
end

template "/etc/apache2/sites-available/graphite" do
  source "graphite-vhost.conf.erb"
end

apache_site "graphite"

directory "#{basedir}/storage" do
  owner node['apache']['user']
  group node['apache']['group']
end

directory "#{basedir}/storage/log" do
  owner node['apache']['user']
  group node['apache']['group']
end

%w{ webapp whisper }.each do |dir|
  directory "#{basedir}/storage/log/#{dir}" do
    owner node['apache']['user']
    group node['apache']['group']
  end
end

template "#{basedir}/bin/set_admin_passwd.py" do
  source "set_admin_passwd.py.erb"
  mode 00755
end

cookbook_file "#{basedir}/storage/graphite.db" do
  action :create_if_missing
  notifies :run, "execute[set admin password]"
end

execute "set admin password" do
  command "#{basedir}/bin/set_admin_passwd.py root #{node['graphite']['password']}"
  action :nothing
end

file "#{basedir}/storage/graphite.db" do
  owner node['apache']['user']
  group node['apache']['group']
  mode 00644
end
