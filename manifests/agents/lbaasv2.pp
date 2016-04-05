# == Class: neutron::agents:lbaasv2:
#
# Setups Neutron Load Balancing v2 agent.
#
# === Parameters
#
# [*package_ensure*]
#   (optional) Ensure state for package. Defaults to 'present'.
#
# [*enabled*]
#   (optional) Enable state for service. Defaults to 'true'.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*debug*]
#   (optional) Show debugging output in log. Defaults to $::os_service_default.
#
# [*interface_driver*]
#   (optional) Defaults to 'neutron.agent.linux.interface.OVSInterfaceDriver'.
#
# [*service_providers*]
#   (optional) Array of allowed service types or '<SERVICE DEFAULT>'.
#   Note: The default upstream value is empty.
#         If you plan to activate LBaaS service, you'll need to set this
#         parameter otherwise neutron-server won't start correctly.
#         See https://bugs.launchpad.net/puppet-neutron/+bug/1535382/comments/1
#   Must be in form <service_type>:<name>:<driver>[:default].
#   Defaults to $::os_service_default
#
# [*loadbalancer_scheduler_driver*]
#  (optional) The scheduler to use for the load balancer agent
#  Defaults to $::os_service_default
#
class neutron::agents::lbaasv2 (
  $package_ensure                = present,
  $enabled                       = true,
  $manage_service                = true,
  $debug                         = $::os_service_default,
  $interface_driver              = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $service_providers             = $::os_service_default,
  $loadbalancer_scheduler_driver = $::os_service_default
) {

  include ::neutron::params

  Neutron_config<||>               ~> Service['neutron-lbaasv2-service']
  Neutron_lbaasv2_agent_config<||> ~> Service['neutron-lbaasv2-service']
  Neutron_lbaas_service_config<||> ~> Service['neutron-lbaasv2-service']

  # The LBaaS agent loads both neutron.ini and its own file.
  # This only lists config specific to the agent.  neutron.ini supplies
  # the rest.
  neutron_lbaasv2_agent_config {
    'DEFAULT/debug':                         value => $debug;
    'DEFAULT/interface_driver':              value => $interface_driver;
    'DEFAULT/loadbalancer_scheduler_driver': value => $loadbalancer_scheduler_driver;
  }

  if !is_service_default($service_providers) {
    # default value is uncommented setting, so we should not touch it at all
    neutron_lbaas_service_config { 'service_providers/service_provider':
      value => $service_providers,
    }
  }

  Package['neutron'] -> Package['neutron-lbaasv2-agent']
  ensure_resource( 'package', 'neutron-lbaasv2-agent', {
    ensure => $package_ensure,
    name   => $::neutron::params::lbaasv2_agent_package,
    tag    => ['openstack', 'neutron-package'],
  })
  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
    Package['neutron'] ~> Service['neutron-lbaasv2-service']
    Package['neutron-lbaasv2-agent'] ~> Service['neutron-lbaasv2-service']
  }

  service { 'neutron-lbaasv2-service':
    ensure  => $service_ensure,
    name    => $::neutron::params::lbaasv2_agent_service,
    enable  => $enabled,
    require => Class['neutron'],
    tag     => 'neutron-service',
  }
}
