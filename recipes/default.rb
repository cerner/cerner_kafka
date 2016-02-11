# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Recipe:: default

ruby_block 'set kafka broker id and zookeeper connect' do # ~FC014
  block do
    # Set broker id
    CernerKafkaHelper.set_broker_id node

    # Set the zookeeper connect config
    CernerKafkaHelper.set_zookeeper_connect node
  end
end

# Tells log4j to write logs into the /var/log/kafka directory
node.default["kafka"]["log4j.properties"]["log4j.appender.kafkaAppender.File"] = File.join node["kafka"]["log_dir"], "server.log"
node.default["kafka"]["log4j.properties"]["log4j.appender.stateChangeAppender.File"] = File.join node["kafka"]["log_dir"], "state-change.log"
node.default["kafka"]["log4j.properties"]["log4j.appender.requestAppender.File"] = File.join node["kafka"]["log_dir"], "kafka-request.log"
node.default["kafka"]["log4j.properties"]["log4j.appender.controllerAppender.File"] = File.join node["kafka"]["log_dir"], "controller.log"

# Set default limits

# We currently ignore FC047 - http://www.foodcritic.io/#FC047) due to a bug in foodcritic giving false
# positives (https://github.com/acrmp/foodcritic/issues/225)
node.default["ulimit"]["users"][node["kafka"]["user"]]["filehandle_limit"] = 32768 # ~FC047
node.default["ulimit"]["users"][node["kafka"]["user"]]["process_limit"] = 1024 # ~FC047

include_recipe "ulimit"

include_recipe "cerner_kafka::install"

# Ensure the Kafka broker log (kafka data) directories exist
node["kafka"]["server.properties"]["log.dirs"].split(",").each do |log_dir|
  directory log_dir do
    action :create
    owner node["kafka"]["user"]
    group node["kafka"]["group"]
    mode 00700
    recursive true
  end
end

# Create init.d script for kafka
# We need to land this early on in case our resources attempt to notify the service resource to stop/start/restart immediately
template "/etc/init.d/kafka" do
  source "kafka_initd.erb"
  owner "root"
  group "root"
  mode  00755
  notifies :restart, "service[kafka]"
end

# Configure kafka properties
%w[server.properties log4j.properties].each do |template_file|
  template "#{node["kafka"]["install_dir"]}/config/#{template_file}" do
    source  "key_equals_value.erb"
    owner node["kafka"]["user"]
    group node["kafka"]["group"]
    mode  00755
    variables(
      lazy {
        { :properties => node["kafka"][template_file].to_hash }
      }
    )
    notifies :restart, "service[kafka]"
  end
end

logrotate_app 'kafka' do
  node["kafka"]["logrotate"].each do |k, v|
    send k, v
  end
end

# Start/Enable Kafka
service "kafka" do
  action [:enable, :start]
end
