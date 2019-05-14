# Cookbook:: chocolatey-server
# Recipe:: ccm
#
# Copyright:: 2019, Laura Melton
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

# https://chocolatey.org/docs/features-chocolatey-central-management

return unless platform?('windows')

include_recipe 'chocolatey::default'

directory 'C:\\ProgramData\\chocolatey\\license' do
  action :create
  not_if { ::File.directory?('C:\\ProgramData\\chocolatey\\license') }
end

cookbook_file 'C:\\ProgramData\\chocolatey\\license\\chocolatey.license.xml' do
  source node['chocolatey-server']['license']
  action :create
end

chocolatey_package 'IIS-WebServer' do
  source 'windowsfeatures'
  action :install
end

include_recipe 'iis::remove_default_site'

windows_zipfile 'c:/chef/cache' do
  source node['chocolatey-server']['sqlsource']
  action :unzip
  not_if { ::File.exist?('c:\\chef\\cache\\sql_svr_stnd_2017\\setup.exe') }
end

powershell_script 'sql' do
  cwd 'C:/chef/cache/sql_svr_stnd_2017/'
  code <<-EOH
  .\\setup.exe /ConfigurationFile=.\\configurationfile.ini /IAcceptSQLServerLicenseTerms=True
    EOH
  not_if { ::File.exist?('C:/Program Files/Microsoft SQL Server/140/DTS/Binn/dtutil.exe') }
end

chocolatey_package 'sql-server-management-studio' do
  action :install
end

chocolatey_package 'chocolatey-agent' do
  options '-y'
  action :install
end
chocolatey_package 'chocolatey.extension' do
  options '-y'
  action :install
end

chocolatey_config 'cachelocation' do
  action :set
  value 'c:\\temp\\choco'
end

powershell_script 'centralmanagement' do
  code <<-EOH
  choco feature enable -n useChocolateyCentralManagement
  EOH
end

chocolatey_package 'aspnetcore-runtimepackagestore' do
  options '-y'
  action :install
end

chocolatey_package 'dotnetcore-windowshosting' do
  options '-y'
  action :upgrade
end

chocolatey_package 'chocolatey-management-database' do
  version node['chocolatey-server']['database-version']
  options node['chocolatey-server']['database-options']
  action :install
end

chocolatey_package 'chocolatey-management-service' do
  version node['chocolatey-server']['service-version']
  options node['chocolatey-server']['service-options']
  action :install
end

chocolatey_package 'chocolatey-management-web' do
  version node['chocolatey-server']['web-version']
  options node['chocolatey-server']['web-options']
  action :install
end
