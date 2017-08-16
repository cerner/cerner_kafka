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
node.default["kafka"]["offset_monitor"]["install_dir"] = "#{node["kafka"]["base_dir"]}/KafkaOffsetMonitor"

zookeepers = node["kafka"]["zookeepers"].join ","
zookeepers += node["kafka"]["zookeeper_chroot"] unless node["kafka"]["zookeeper_chroot"].nil?

node.default["kafka"]["offset_monitor"]["options"]["--zk"] = zookeepers

log4j_jar_path = File.join(node["kafka"]["offset_monitor"]["install_dir"], 'log4j.jar')

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
  manage_home true
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
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode 00755
  recursive true
end

# Download kafka offset monitor jar
remote_file File.join(node["kafka"]["offset_monitor"]["install_dir"], 'KafkaOffsetMonitor.jar') do
  action :create
  source node["kafka"]["offset_monitor"]["url"]
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  mode 00644
  backup false
  notifies :restart, "service[kafka-offset-monitor]"
end

if node["kafka"]["offset_monitor"]["include_log4j_jar"]
  # Download and include the log4j binding jar for offset monitor
  remote_file log4j_jar_path do
    action :create
    source node["kafka"]["offset_monitor"]["log4j_url"]
    owner node["kafka"]["user"]
    group node["kafka"]["group"]
    mode 00644
    backup false
    notifies :restart, "service[kafka-offset-monitor]"
  end
else
  # Ensure the log4j file is removed
  file log4j_jar_path do
    action :delete
    notifies :restart, "service[kafka-offset-monitor]"
  end
end

# logging config for the offset monitor
template File.join(node["kafka"]["offset_monitor"]["install_dir"], 'offset_monitor_log4j.properties') do
  source "key_equals_value.erb"
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  variables({
    :properties => node["kafka"]["offset_monitor"]["log4j.properties"].to_hash
  })
  mode  00755
  notifies :restart, "service[kafka-offset-monitor]"
end

# Write JAAS configuration file if enabled
if node["kafka"]["kerberos"]["enable"]

  jaas_path = "#{node['kafka']['offset_monitor']['install_dir']}/jaas.conf"

  # add JAAS config location as default JVM parameter
  node.default['kafka']['offset_monitor']['java_options']['-Djava.security.auth.login.config='] = jaas_path

  # Verify required attributes are set
  raise "Kerberos keytab location must be configured" if node["kafka"]["kerberos"]["keytab"].nil?
  raise "Kerberos realm or principal must be configured" if node["kafka"]["kerberos"]["principal"].end_with? '@'

  template jaas_path do
    source "jaas_client_config.erb"
    owner node["kafka"]["user"]
    group node["kafka"]["group"]
    mode  00755
    notifies :restart, "service[kafka-offset-monitor]"
  end
end

# Create init.d script for kafka offset monitor
template "/etc/init.d/kafka-offset-monitor" do
  source "kafka_offset_monitor_initd.erb"
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
