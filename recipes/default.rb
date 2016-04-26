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

# Set all default attributes that are built from other attributes
node.default["kafka"]["install_dir"] = "#{node["kafka"]["base_dir"]}/kafka"

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

# Build the binary_url from download_url, scala_version and version. This url is what we actually use to download the binary file
node.default["kafka"]["binary_url"] = "#{node["kafka"]["download_url"]}/#{node["kafka"]["version"]}/kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}.tgz"
binaryFileName = File.basename(node["kafka"]["binary_url"])
kafkaFullDirectoryName = "kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}"

log "Installing kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}"
log "Binary URL : #{node["kafka"]["binary_url"]}"

include_recipe "java"
include_recipe "ulimit"

# manage user and group
include_recipe "cerner_kafka::_user_group"

# Configure kafka user
template "/home/#{node["kafka"]["user"]}/.bash_profile" do
  source  "bash_profile.erb"
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode  00755
  notifies :restart, "service[kafka]"
end

# Ensure the Kafka base directory exists
directory node["kafka"]["base_dir"] do
  action :create
  mode 00755
  recursive true
end

# Ensure the Kafka log directory exists
directory node["kafka"]["log_dir"] do
  action :create
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode 00755
  recursive true
end

# Ensure the Kafka broker log (kafka data) directories exist
if node["kafka"]["server.properties"].has_key? 'log.dirs'
  node["kafka"]["server.properties"]["log.dirs"].split(",").each do |log_dir|
    directory log_dir do
      action :create
      owner node["kafka"]["user"]
      group node["kafka"]["group"]
      mode 00700
      recursive true
    end
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

# Download kafka binary file if it does not exist already
remote_file "#{Chef::Config[:file_cache_path]}/#{binaryFileName}" do
  action :create_if_missing
  source node["kafka"]["binary_url"]
  mode 00644
  backup false
end

# Untar kafka binary file (this will only run if the real kafka directory /opt/kafka_1.2.3 does not exist)
# We actually untar the file into /opt (not /opt/kafka)
execute "untar kafka binary" do
  cwd node["kafka"]["base_dir"]
  command "tar zxf #{Chef::Config[:file_cache_path]}/#{binaryFileName}"
  not_if do
    File.exists? File.join node["kafka"]["base_dir"], kafkaFullDirectoryName
  end

  # In case kafka is running we need to stop it before we upgrade/change installations
  notifies :stop, "service[kafka]", :immediately
end

# Link the actual installation with the install_dir (/opt/kafka_1.0.0 -> /opt/kafka)
link node["kafka"]["install_dir"] do
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  to File.join node["kafka"]["base_dir"], kafkaFullDirectoryName
end

# Download any configured lib jars
node["kafka"]["lib_jars"].each do | lib_jar_url |

  file_name = File.basename lib_jar_url

  remote_file "#{node["kafka"]["install_dir"]}/libs/#{file_name}" do
    source lib_jar_url
    action :create
    backup false
  end
end

# Ensure everything is owned by the kafka user/group
execute "chown #{node["kafka"]["user"]}:#{node["kafka"]["group"]} -R #{File.join(node["kafka"]["base_dir"], kafkaFullDirectoryName)}" do
  action :run
end

# Overwrite kafka-server-stop.sh script since it has a bug in 0.8.0/0.8.1 (KAFKA-1189).
template "#{node["kafka"]["install_dir"]}/bin/kafka-server-stop.sh" do
  source  "kafka-server-stop.sh.erb"
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode  00755
  # Overwrite kafka-server-start.sh script since it has a bug in 0.8.0/0.8.1 (KAFKA-1189). This is fixed in 0.8.2
  # We use start_with? instead of == to handle the case of 0.8.0.X or 0.8.1.X releases.
  only_if { node["kafka"]["version"].start_with? "0.8.0" or node["kafka"]["version"].start_with? "0.8.1" }
end

template "#{node["kafka"]["install_dir"]}/bin/kafka-server-start.sh" do
  source  "kafka-server-start.sh.erb"
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode  00755
  # Overwrite kafka-server-start.sh script since it has a bug in 0.8.0/0.8.1 (KAFKA-1278). This is fixed in 0.8.2
  # We use start_with? instead of == to handle the case of 0.8.0.X or 0.8.1.X releases.
  only_if { node["kafka"]["version"].start_with? "0.8.0" or node["kafka"]["version"].start_with? "0.8.1" }
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

# Link kafka config to /etc/kafka
link "/etc/kafka" do
  to "#{node["kafka"]["install_dir"]}/config"
end

# Start/Enable Kafka
service "kafka" do
  action [:enable, :start]
  supports :status => true, :restart => true
end
