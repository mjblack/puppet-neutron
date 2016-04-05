require 'spec_helper'

describe 'neutron::agents::lbaasv2' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure                => 'present',
      :enabled                       => true,
      :interface_driver              => 'neutron.agent.linux.interface.OVSInterfaceDriver',
    }
  end

  let :test_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end


  shared_examples_for 'neutron lbaasv2 agent' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('neutron::params') }

    it 'configures neutron_lbaas.conf' do
      is_expected.to contain_neutron_lbaasv2_agent_config('DEFAULT/debug').with_value('<SERVICE DEFAULT>');
      is_expected.to contain_neutron_lbaasv2_agent_config('DEFAULT/interface_driver').with_value(p[:interface_driver]);
    end

    it 'installs neutron lbaasv2 agent package' do
      is_expected.to contain_package('neutron-lbaasv2-agent').with(
        :name   => platform_params[:lbaasv2_agent_package],
        :ensure => p[:package_ensure],
        :tag    => ['openstack', 'neutron-package'],
      )
      is_expected.to contain_package('neutron').with_before(/Package\[neutron-lbaasv2-agent\]/)
    end

    it 'configures neutron lbaasv2 agent service' do
      is_expected.to contain_service('neutron-lbaasv2-service').with(
        :name    => platform_params[:lbaasv2_agent_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]',
        :tag     => 'neutron-service',
      )
      is_expected.to contain_service('neutron-lbaasv2-service').that_subscribes_to( [ 'Package[neutron]', 'Package[neutron-lbaasv2-agent]' ] )
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        is_expected.to contain_service('neutron-lbaasv2-service').without_ensure
      end
    end

    context 'with multiple service providers' do
      let :params do
        default_params.merge(
          { :service_providers => ['provider1', 'provider2'] }
        )
      end

      it 'configures neutron_lbaas.conf' do
        is_expected.to contain_neutron_lbaas_service_config(
          'service_providers/service_provider'
        ).with_value(['provider1', 'provider2'])
      end
    end

    context 'with loadbalancer scheduler driver' do
      let :params do
        default_params.merge(
          { :loadbalancer_scheduler_driver => 'schedulerdriver' }
        )
      end

      it 'configures neutron_lbaas.conf' do
        is_expected.to contain_neutron_lbaasv2_agent_config('DEFAULT/loadbalancer_scheduler_driver').with_value(p[:loadbalancer_scheduler_driver]);
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge(test_facts.merge(
        { :osfamily => 'Debian',
          :concat_basedir => '/dne'
        }
      ))
    end

    let :platform_params do
      { :lbaasv2_agent_package => 'neutron-lbaasv2-agent',
        :lbaasv2_agent_service => 'neutron-lbaasv2-agent' }
    end

    it_configures 'neutron lbaasv2 agent'
  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge(test_facts.merge(
         { :osfamily               => 'RedHat',
           :operatingsystemrelease => '7',
           :concat_basedir         => '/dne'
         }
      ))
    end

    let :platform_params do
      { :lbaasv2_agent_package => 'openstack-neutron-lbaas',
        :lbaasv2_agent_service => 'neutron-lbaasv2-agent' }
    end

    it_configures 'neutron lbaasv2 agent'
  end
end
