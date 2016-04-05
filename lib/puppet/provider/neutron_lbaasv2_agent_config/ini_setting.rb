Puppet::Type.type(:neutron_lbaasv2_agent_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:openstack_config).provider(:ini_setting)
) do

  def file_path
    '/etc/neutron/neutron_lbaas.conf'
  end

end
