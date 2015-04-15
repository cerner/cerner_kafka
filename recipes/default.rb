# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Recipe:: default

# Create an array for storing errors we should verify before doing anything
errors = Array.new

# Verify either node["kafka"]["brokers"] or node["kafka"]["server.properties"]["broker.id"] is set properly
if (node["kafka"]["brokers"].nil? || !(node["kafka"]["brokers"].is_a? Array) || node["kafka"]["brokers"].empty?) && !node["kafka"]["server.properties"].has_key?("broker.id")
  errors.push "node[:kafka][:brokers] or node[:kafka][:server.properties][:broker.id] must be set properly"
elsif !node["kafka"]["server.properties"].has_key?("broker.id")
  # Generate brokerId for Kafka (uses the index of the brokers list to figure out which ID this broker should have). We add 1 to ensure
  # we have a positive (non zero) number
  brokerId = (node["kafka"]["brokers"].index{|broker| broker == node["fqdn"] || broker == node["ipaddress"] || broker == node["hostname"]} ) + 1
  if brokerId.nil?
    errors.push "Unable to find node in node[:kafka][:brokers] : #{node["kafka"]["brokers"]}"
  end
  node.default["kafka"]["server.properties"]["broker.id"] = brokerId
end

# Verify we have a list of zookeeper instances
if (node["kafka"]["zookeepers"].nil? || (!node["kafka"]["zookeepers"].is_a? Array) || node["kafka"]["zookeepers"].empty?) && !node["kafka"]["server.properties"].has_key?("zookeeper.connect")
  errors.push "node[:kafka][:zookeepers] or node[:kafka][:server.properties][:zookeeper.connect] was not set properly"
elsif !node["kafka"]["server.properties"].has_key?("zookeeper.connect")
  servers = node["kafka"]["zookeepers"].join ","
  if node["kafka"]["zookeeper_chroot"].nil?
    node.default["kafka"]["server.properties"]["zookeeper.connect"] = servers
  else
    node.default["kafka"]["server.properties"]["zookeeper.connect"] = servers + node["kafka"]["zookeeper_chroot"]
  end
end

# Raise an exception if there are any problems
raise "Unable to run kafka::default : [#{errors.join ", "}]" unless errors.empty?

# Set all default attributes that are built from other attributes
node.default["kafka"]["install_dir"] = "#{node["kafka"]["base_dir"]}/kafka"

# Tells log4j to write logs into the /var/log/kafka directory
node.default["kafka"]["log4j.properties"]["log4j.appender.kafkaAppender.File"] = File.join node["kafka"]["log_dir"], "server.log"
node.default["kafka"]["log4j.properties"]["log4j.appender.stateChangeAppender.File"] = File.join node["kafka"]["log_dir"], "state-change.log"
node.default["kafka"]["log4j.properties"]["log4j.appender.requestAppender.File"] = File.join node["kafka"]["log_dir"], "kafka-request.log"
node.default["kafka"]["log4j.properties"]["log4j.appender.controllerAppender.File"] = File.join node["kafka"]["log_dir"], "controller.log"

# Set default limits
node.default["ulimit"]["users"][node["kafka"]["user"]]["filehandle_limit"] = 32768
node.default["ulimit"]["users"][node["kafka"]["user"]]["process_limit"] = 1024

# Build the binary_url from download_url, scala_version and version. This url is what we actually use to download the binary file
node.default["kafka"]["binary_url"] = "#{node["kafka"]["download_url"]}/#{node["kafka"]["version"]}/kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}.tgz"
binaryFileName = File.basename(node["kafka"]["binary_url"])
kafkaFullDirectoryName = "kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}"

log "Installing kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}"
log "Binary URL : #{node["kafka"]["binary_url"]}"

include_recipe "java"
include_recipe "ulimit"

# Create kafka chroot in Zookeeper
unless node["kafka"]["zookeeper_chroot"].nil?
  # Installs everything needed for the zookeeper gem including the gem itself
  include_recipe "zookeeper::install"

  ruby_block "create zookeeper chroot for kafka" do
    block do
      require 'zookeeper'

      # Get zookeeper quorum (without chroot)
      zk_connect = node["kafka"]["server.properties"]["zookeeper.connect"].to_s.clone
      zk_connect.slice!(node["kafka"]["zookeeper_chroot"])

      zk = ::Zookeeper.new(zk_connect)

      # We have to create each directory individually
      current_dir = ""
      node["kafka"]["zookeeper_chroot"].split('/').delete_if{|x| x.empty?}.each do |dir|
        current_dir = current_dir + "/" + dir
        unless zk.stat(:path => current_dir)[:stat].exists?
          zk.create(:path => current_dir)
        end
      end

    end
  end

end


# setup kafka group
group node["kafka"]["group"] do
  action :create
end

# setup kafka user
user node["kafka"]["user"] do
  comment "Kafka user"
  gid node["kafka"]["group"]
  shell "/bin/bash"
  home "/home/#{node["kafka"]["user"]}"
  supports :manage_home => true
end

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
    variables({
                :properties => node["kafka"][template_file].to_hash
    })
    notifies :restart, "service[kafka]"
  end
end

# Link kafka config to /etc/kafka
link "/etc/kafka" do
  to "#{node["kafka"]["install_dir"]}/config"
end

# Start/Enable Kafka
service "kafka" do
  action [:enable, :start]
end
