
Chocolatey server and ccm cookbook
===================================
This is a cookbook that will install chocolatey simple-server and chocolatey central management console

Requirments
-----------------------------------
This has been written for server 2016 and tested on a domain joined server

Does use: 
chocolatey cookbook - https://github.com/chocolatey/chocolatey-cookbook.git
iis cookbook - https://github.com/chef-cookbooks/iis.git

#### cookbooks

- `default` - installs chocolatey simple-server
- `ccm` - installs chocolatey central management server *must be installed on own server

Attributes
-----------------------------------
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['chocolatey-server']['license']</tt></td>
    <td></td>
    <td>Your license file for Chocolatey for Business (C4B)</td>
    <td><tt>chocolatey.license.xml</tt></td>
  </tr>
  <tr>
    <td><tt>['chocolatey-server']['sqlsource']</tt></td>
    <td></td>
    <td>URL SQL Server 2017 Developer Trial</td>
    <td><tt>https://go.microsoft.com/fwlink/?linkid=853016</tt></td>
  </tr> 
    <tr>
    <td><tt>['chocolatey-server']['database-options']</tt></td>
    <td>string</td>
    <td><tt>https://chocolatey.org/docs/features-chocolatey-central-management#installing-chocolatey-management-database <tt></td>
    <td><tt>-y</tt></td>
  </tr> 
    <tr>
    <td><tt>['chocolatey-server']['service-options']</tt></td>
    <td>string</td>
    <td><tt>https://chocolatey.org/docs/features-chocolatey-central-management#installing-chocolatey-management-service<tt></td>
    <td><tt>-y</tt></td>
  </tr> 
    <tr>
    <td><tt>['chocolatey-server']['web-options']</tt></td>
    <td>string</td>
    <td><tt>https://chocolatey.org/docs/features-chocolatey-central-management#installing-chocolatey-management-web<tt></td>
    <td><tt>-y</tt></td>
  </tr> 
</table>


Certificate
--------------------------------
chocolatey-management-service: auto creates a self signed certificate. 
- If you are using a domain joined computer and want to use the self cert then use the `/CertificateDNSName` parameter. 
- If you are using a 3rd party certificate then use the `/CertificateThumbprint` parameter
