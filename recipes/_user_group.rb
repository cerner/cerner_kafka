# setup kafka group
group node["kafka"]["group"] do
  action :create
end

# setup kafka user
user node["kafka"]["user"] do
  comment "Kafka user"
  uid node["kafka"]["uid"] if node["kafka"]["uid"]
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
