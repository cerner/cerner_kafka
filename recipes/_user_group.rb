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
