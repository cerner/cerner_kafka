# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Recipe:: install

# Create an array for storing errors we should verify before doing anything
errors = Array.new

# Set all default attributes that are built from other attributes
node.default["kafka"]["install_dir"] = "#{node["kafka"]["base_dir"]}/kafka"

# Build the binary_url from download_url, scala_version and version. This url is what we actually use to download the binary file
node.default["kafka"]["binary_url"] = "#{node["kafka"]["download_url"]}/#{node["kafka"]["version"]}/kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}.tgz"
binaryFileName = File.basename(node["kafka"]["binary_url"])
kafkaFullDirectoryName = "kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}"

log "Installing kafka_#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}"
log "Binary URL : #{node["kafka"]["binary_url"]}"

include_recipe "java"
include_recipe "cerner_kafka::_common"

# Ensure the Kafka base directory exists
directory node["kafka"]["base_dir"] do
  action :create
  mode 00755
  recursive true
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

# Link kafka config to /etc/kafka
link "/etc/kafka" do
  to "#{node["kafka"]["install_dir"]}/config"
end

