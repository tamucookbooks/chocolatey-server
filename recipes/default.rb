#
# Cookbook:: chocolatey-server
# Recipe:: default
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

return unless platform?('windows')  

include_recipe 'chocolatey::default'

directory 'C:\\ProgramData\\chocolatey\\license' do
    action :create
    not_if {::File.directory?("C:\\ProgramData\\chocolatey\\license")}
end

cookbook_file 'C:\\ProgramData\\chocolatey\\license\\chocolatey.license.xml' do
    source node['chocolatey-server']['license']
    action :create
end

directory 'C:\\choco-setup' do
    action :create
    not_if {::File.directory?("C:\\choco-setup")}
end

directory 'C:\\choco-setup\\files' do
    action :create
    not_if {::File.directory?("C:\\choco-setup\\files")}
end

directory 'C:\\choco-setup\\packages' do
    action :create
    not_if {::File.directory?("C:\\choco-setup\\packages")}
end

chocolatey_config 'virusScannerType' do
    value 'VirusTotal'
    action :set
end

chocolatey_package 'chocolatey-agent' do
    options '-y'
    source 'https://licensedpackages.chocolatey.org/api/v2/'
    action :install
end

chocolatey_package 'chocolatey.server' do
    action :install
end

chocolatey_package 'chocolatey.extension' do
    action :install
end

chocolatey_package 'ChocolateyGUI' do
    action :install
end

chocolatey_config 'cachelocation' do
    value "c:\\programdata\\choco-cache"
    action :set
end

powershell_script 'refresh' do
    code <<-EOH
    c:\\ProgramData\\chocolatey\\bin\\RefreshEnv.cmd
    EOH
end


powershell_script 'choco' do
    cwd 'c:\\ProgramData\\chocolatey'
    code <<-EOH
    choco feature enable --name="'internalizeAppendUseOriginalLocation'"
    choco feature enable --name="'reduceInstalledPackageSpaceUsage'"
    choco feature enable -n virusCheck
    choco feature enable -n allowPreviewFeatures
    choco feature enable -n internalizeAppendUseOriginalLocation
    choco feature enable -n reduceInstalledPackageSpaceUsage
    EOH
end

chocolatey_package 'KB2919355' do
    action :install
end

chocolatey_package 'KB2919442' do
    action :install
end

windows_feature ['web-server', 'Web-Asp-Net45', 'Web-AppInit' ] do
    action :install
    management_tools true
    install_method :windows_feature_powershell
    not_if "(Get-WindowsFeature -Name Web-Server).Installed"
end

powershell_script 'iis' do
    code <<-EOH
    $siteName = 'chocolatey'
    $appPoolName = 'chocoAppPool'
    $sitePath = 'c:\\tools\\chocolatey.server'
    #Import-Module WebAdministrations
    Get-Website -Name 'Default Web Site' | Stop-Website
    Set-ItemProperty "IIS:\\Sites\Default Web Site" serverAutoStart False
    New-WebAppPool -Name $appPoolName -Force
    Set-ItemProperty IIS:\\AppPools\\$appPoolName enable32BitAppOnWin64 True
    Set-ItemProperty IIS:\\AppPools\\$appPoolName managedRuntimeVersion v4.0
    Set-ItemProperty IIS:\\AppPools\\$appPoolName managedPipelineMode Integrated
    Restart-WebAppPool -Name $appPoolName
    EOH
    only_if { powershell_out("get-website | where-object { $_.name -eq  'chocolatey' }").stdout.empty? }
end

powershell_script 'addsite' do
    code <<-EOH
    $siteName = 'chocolatey'
    $appPoolName = 'chocoAppPool'
    $sitePath = 'c:\\tools\\chocolatey.server'
    New-Website -Name $siteName -ApplicationPool $appPoolName -PhysicalPath $sitePath
    EOH
    only_if { powershell_out("get-website | where-object { $_.name -eq  'chocolatey' }").stdout.empty? }
end

include_recipe 'iis::remove_default_site'

powershell_script 'folderpermissions' do
    code <<-EOH
    function Add-Acl {
    [CmdletBinding()]
    Param (
        [string]$Path,
        [System.Security.AccessControl.FileSystemAccessRule]$AceObject
    )

    Write-Verbose "Retrieving existing ACL from $Path"
    $objACL = Get-ACL -Path $Path
    $objACL.AddAccessRule($AceObject)
    Write-Verbose "Setting ACL on $Path"
    Set-ACL -Path $Path -AclObject $objACL
    }

    function New-AclObject {
    [CmdletBinding()]
    Param (
        [string]$SamAccountName,
        [System.Security.AccessControl.FileSystemRights]$Permission,
        [System.Security.AccessControl.AccessControlType]$AccessControl = 'Allow',
        [System.Security.AccessControl.InheritanceFlags]$Inheritance = 'None',
        [System.Security.AccessControl.PropagationFlags]$Propagation = 'None'
    )

    New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule($SamAccountName, $Permission, $Inheritance, $Propagation, $AccessControl)
    }

    $siteName = 'chocolatey'
    $appPoolName = 'chocoAppPool'
    $sitePath = 'c:\\tools\\chocolatey.server'

    'IIS_IUSRS', 'IUSR', "IIS APPPOOL\\$appPoolName" | ForEach-Object {
    $obj = New-AclObject -SamAccountName $_ -Permission 'ReadAndExecute' -Inheritance 'ContainerInherit','ObjectInherit'
    Add-Acl -Path $sitePath -AceObject $obj
    }

    $appdataPath = Join-Path -Path $sitePath -ChildPath 'App_Data'

    'IIS_IUSRS', "IIS APPPOOL\\$appPoolName" | ForEach-Object {
    $obj = New-AclObject -SamAccountName $_ -Permission 'Modify' -Inheritance 'ContainerInherit', 'ObjectInherit'
    Add-Acl -Path $appdataPath -AceObject $obj
    }
    EOH
end
