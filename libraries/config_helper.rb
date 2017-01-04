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

  def self.broker_id node
    if node['kafka']['server.properties']['broker.id']
      return node['kafka']['server.properties']['broker.id']
    end
    
    dirs = nil

    if node["kafka"]["server.properties"]["log.dir"]
      dirs = [node["kafka"]["server.properties"]["log.dir"]]
    elsif node["kafka"]["server.properties"]["log.dirs"]
      dirs = node["kafka"]["server.properties"]["log.dirs"].split(",")
    else node["kafka"]["server.properties"]["log.dirs"]
      Chef::Log.error('No log.dir(s) properties set in chef, unable to find broker.id')
      return nil
    end

    dirs.each do |dir|
      meta_file = ::File.join(dir, 'meta.properties')
      if ::File.exists? meta_file
        broker_id_lines = IO.read(meta_file).split("\n").select{|line| line.start_with?('broker.id=') }

        if broker_id_lines.empty?
          Chef::Log.info("Unable to find broker.id in meta file [#{meta_file}]")
          next
        end

        broker_id_line = broker_id_lines.first
        broker_id = broker_id_line['broker.id='.size, broker_id_line.size - 'broker.id='.size]

        Chef::Log.info("Found broker.id [#{broker_id}] in [#{meta_file}]")

        return broker_id

      else
        Chef::Log.info("No meta.properties file in log dir [#{dir}]")
      end
    end

    Chef::Log.warn('Unable to find broker.id property in meta.properties file')

    nil
  end
end
