# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Recipe:: offset_monitor

# Create an array for storing errors we should verify before doing anything
errors = Array.new

# Verify we have a list of zookeeper instances
if node["kafka"]["zookeepers"].nil? || (!node["kafka"]["zookeepers"].is_a? Array) || node["kafka"]["zookeepers"].empty?
  errors.push "node[:kafka][:zookeepers] was not set properly. It was either nil, not an Array, or empty."
end

# Raise an exception if there are any problems
raise "Unable to run kafka::offsetmonitor : [#{errors.join ", "}]" unless errors.empty?

# Set all default attributes that are built from other attributes
node.default["kafka"]["offset_monitor"]["install_dir"] = "#{node["kafka"]["base_dir"]}/kafka-offset-monitor"

zookeepers = node["kafka"]["zookeepers"].join ","
zookeepers += node["kafka"]["zookeeper_chroot"] unless node["kafka"]["zookeeper_chroot"].nil?

node.default["kafka"]["offset_monitor"]["options"]["--zk"] = zookeepers

offsetMonitorFileName = File.basename(node["kafka"]["offset_monitor"]["url"])
fullOffsetMonitorFileName = File.join node["kafka"]["offset_monitor"]["install_dir"], offsetMonitorFileName

log "Installing #{node["kafka"]["offset_monitor"]["url"]} to #{node["kafka"]["offset_monitor"]["install_dir"]}"

include_recipe "java"

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

# Ensure the Kafka log directory exists
directory node["kafka"]["log_dir"] do
  action :create
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode 00755
  recursive true
end

# Ensure the install directory exists
directory node["kafka"]["offset_monitor"]["install_dir"] do
  action :create
  mode 00755
  recursive true
end

# Download kafka offset monitor jar if it does not exist already
remote_file "#{Chef::Config[:file_cache_path]}/#{offsetMonitorFileName}" do
  action :create_if_missing
  source node["kafka"]["offset_monitor"]["url"]
  mode 00644
  backup false
end

# Copy kafka offset monitor file into its install directory
execute "copy offset monitor file" do
  command "cp #{Chef::Config[:file_cache_path]}/#{offsetMonitorFileName} #{node["kafka"]["offset_monitor"]["install_dir"]}"
  not_if do
    File.exists? fullOffsetMonitorFileName
  end

  # In case kafka offset monitor is running we need to stop it before we upgrade/change installations
  notifies :stop, "service[kafka-offset-monitor]", :immediately
end

# Ensure everything is owned by the kafka user/group
execute "chown #{node["kafka"]["user"]}:#{node["kafka"]["group"]} -R #{node["kafka"]["offset_monitor"]["install_dir"]}" do
  action :run
end

# Create init.d script for kafka offset monitor
template "/etc/init.d/kafka-offset-monitor" do
  source "kafka_offset_monitor_initd.erb"
  variables({
    :jar_file => fullOffsetMonitorFileName
  })
  owner "root"
  group "root"
  mode  00755
  notifies :restart, "service[kafka-offset-monitor]"
end

# Start/Enable kafka offset monitor service
service "kafka-offset-monitor" do
  action [:enable, :start]
  supports :restart => true
end
