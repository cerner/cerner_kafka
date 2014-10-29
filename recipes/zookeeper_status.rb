# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Recipe:: zookeeper_status

<<-comment
execute 'check zookeeper' do
  action :run
  command " nc -z #{node["kafka"]["zookeepers"].first} 2181 "
  returns [0]
end
comment



ruby_block "Zookeeper Status Check" do
    block do
      fail "Zookeeper not Running"
    end
    not_if  "nc -z #{node['kafka']['zookeepers'].first} 2181" 
end
