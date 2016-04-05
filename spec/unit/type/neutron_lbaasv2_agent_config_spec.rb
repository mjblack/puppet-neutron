require 'puppet'
require 'puppet/type/neutron_lbaasv2_agent_config'

describe 'Puppet::Type.type(:neutron_lbaasv2_agent_config)' do

  before :each do
    @neutron_lbaasv2_agent_config = Puppet::Type.type(:neutron_lbaasv2_agent_config).new(:name => 'DEFAULT/foo', :value => 'bar')
  end

  it 'should autorequire the package that install the file' do
    catalog = Puppet::Resource::Catalog.new
    package = Puppet::Type.type(:package).new(:name => 'neutron-lbaasv2-agent')
    catalog.add_resource package, @neutron_lbaasv2_agent_config
    dependency = @neutron_lbaasv2_agent_config.autorequire
    expect(dependency.size).to eq(1)
    expect(dependency[0].target).to eq(@neutron_lbaasv2_agent_config)
    expect(dependency[0].source).to eq(package)
  end

end
