# Inspec test for recipe chocolatey-server::ccm

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('ChocolateyLocalAdmin'), do
    it { should exist }
end

describe service('chocolatey-agent') do
  it { should be_installed }
  it { should be_running }
  its ('startmode') { should eq 'Auto' }
end

describe service('chocolatey-central-management') do
    it { should be_installed }
    it { should be_running }
    its ('startmode') { should eq 'Auto' }
end

describe service('W3SVC') do
  it { should be_installed }
  it { should be_running }
  its ('startmode') { should eq 'Auto' }
end

describe iis_site('Default Web Site') do
  it { should_not be_running }
end

describe iis_site('ChocolateyCentralManagement') do
  it { should exist }
  it { should be_running }
  it { should have_app_pool('ChocolateyCentralManagement') }
end