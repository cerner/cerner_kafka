# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Recipe:: mirror_maker

# Create an array for storing errors we should verify before doing anything
errors = Array.new

# Verify node["kafka"]["mirror_maker"] is setup properly
ruby_block 'assert mirror maker config is correct' do # ~FC014
  block_name 'attribute_mirrormaker_assertions'
  block do
    # Sources
    if node['kafka']['mirror_maker']['mirror_sources'].to_a.empty?
      errors.push 'node[:mirror_maker][:mirror_sources]  must not be empty'
    else
      node['kafka']['mirror_maker']['mirror_sources'].each do |c|
        #if node['kafka']['mirror_maker'][c].nil?
        if !node['kafka']['mirror_maker'].has_key?(c)
          errors.push 'node[:kafka][:mirror_maker][:' + c + '] entry in mirror_sources, but does not exist'
        else 
          if !node['kafka']['mirror_maker'][c].has_key?('zookeeper.connect')
            errors.push 'node[:kafka][:mirror_maker][:' + c + '] entry must have zookeeper.connect attribute'
          end
          if !node['kafka']['mirror_maker'][c].has_key?('group.id')
            errors.push 'node[:kafka][:mirror_maker][:' + c + '] entry must have group.id attribute'
          end
        end
      end
    end

    # Target
    if !node["kafka"]["mirror_maker"]["mirror_target.properties"].has_key?('metadata.broker.list')
          errors.push 'node[:kafka][:mirror_maker][:mirror_target.properties] entry must have metadata.broker.list attribute'
    end

    # Raise an exception if there are any problems
    raise "Unable to run kafka::default : \n  -#{errors.join "\n  -"}]\n" unless errors.empty?
  end
end

# Tells log4j to write logs into the /var/log/kafka directory
node.default["kafka"]['mirror_maker']["mirror-log4j.properties"]["log4j.appender.kafkaAppender.File"] = File.join node["kafka"]["log_dir"], "mirror-server.log"
node.default["kafka"]['mirror_maker']["mirror-log4j.properties"]["log4j.appender.stateChangeAppender.File"] = File.join node["kafka"]["log_dir"], "mirror-state-change.log"
node.default["kafka"]['mirror_maker']["mirror-log4j.properties"]["log4j.appender.requestAppender.File"] = File.join node["kafka"]["log_dir"], "mirror-kafka-request.log"
node.default["kafka"]['mirror_maker']["mirror-log4j.properties"]["log4j.appender.controllerAppender.File"] = File.join node["kafka"]["log_dir"], "mirror-controller.log"

include_recipe "cerner_kafka::install"

# Configure kafka mirror maker properties
node['kafka']['mirror_maker']['mirror_sources'].concat(%w[mirror_target.properties mirror-log4j.properties]).each do |template_file|
  template "#{node["kafka"]["install_dir"]}/config/#{template_file}" do
    source  "key_equals_value.erb"
    owner node["kafka"]["user"]
    group node["kafka"]["group"]
    mode  00755
    variables(
      lazy {
        { :properties => node["kafka"]['mirror_maker'][template_file].to_hash }
      }
    )
    notifies :restart, "service[kafka-mirror-maker]"
  end
end

template "#{node["kafka"]["install_dir"]}/bin/kafka-mirror-stop.sh" do
  source  "kafka-mirror-stop.sh.erb"
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode  00755
end

template "#{node["kafka"]["install_dir"]}/bin/kafka-mirror-start.sh" do
  source  "kafka-mirror-start.sh.erb"
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode  00755
end

# Create init.d script for kafka mirror maker
# We need to land this early on in case our resources attempt to notify the service resource to stop/start/restart immediately
template "/etc/init.d/kafka-mirror-maker" do
  source "kafka_mirror_maker_initd.erb"
  owner "root"
  group "root"
  mode  00755
  notifies :restart, "service[kafka-mirror-maker]"
end

# Start/Enable Kafka
service "kafka-mirror-maker" do
  action [:enable, :start]
end
