# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Recipe:: zookeeper_status


execute 'check zookeeper' do
  action :run
  command " nc -z #{node["kafka"]["zookeepers"].first} 2181 "
  returns [0]
end
