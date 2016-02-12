class CernerKafkaHelper
  def self.set_broker_id node
    if node['kafka']['server.properties'].key?('broker.id')
      Chef::Log.debug(
        "broker hard set to #{node['kafka']['server.properties']['broker.id']} "\
        'in server.properties node object'
      )
      return
    end

    brokers = Array(node['kafka']['brokers'])

    if brokers.nil?
      Chef::Log.error(
        "node['kafka']['brokers'] or "\
        "node['kafka']['server.properties']['broker.id'] must be set properly"
      )
    else
      broker_id = brokers.index do |broker|
        broker == node['fqdn'] ||
        broker == node['ipaddress'] ||
        broker == node['hostname']
      end

      if broker_id.nil?
        if node['kafka']['version'].start_with? '0.8'
          Chef::Log.error("Unable to find #{node['fqdn']}, #{node['ipaddress']} or "\
                          "#{node['hostname']} in node['kafka']['brokers'] : #{node['kafka']['brokers']}")
        else
          Chef::Log.debug('Using Kafka broker id auto assign')
          return
        end
      else
        node.default['kafka']['server.properties']['broker.id'] = broker_id + 1
        Chef::Log.debug("BROKER SET: #{node['kafka']['server.properties']['broker.id']}")
        return
      end
    end

    raise 'Unable to run kafka::default unable to determine broker ID'
  end

  def self.set_zookeeper_connect node
    if node['kafka']['server.properties'].key?('zookeeper.connect')
      Chef::Log.debug(
        "broker hard set to '#{node['kafka']['server.properties']['zookeeper.connect']}' "\
        'in server.properties node object'
      )
      return
    end

    if node['kafka']['zookeepers'].nil?
      Chef::Log.error(
        "node['kafka']['zookeepers'] or "\
        "node['kafka']['server.properties']['zookeepers.connect'] must be set properly"
      )
    else
      zk_connect = Array(node['kafka']['zookeepers']).join ','
      zk_connect += node['kafka']['zookeeper_chroot'] if node['kafka']['zookeeper_chroot']
      node.default['kafka']['server.properties']['zookeeper.connect'] = zk_connect
      return
    end

    raise 'Unable to run kafka::default unable to determine zookeeper hosts'
  end
end
