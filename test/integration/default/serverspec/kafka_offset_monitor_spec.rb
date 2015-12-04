# coding: UTF-8

require 'spec_helper'

describe service('kafka-offset-monitor') do
  it { should be_running   }
end

# Kafka Offset Monitor API
describe port(8088) do
  it { should be_listening }
end

describe 'kafka offset monitor' do

  it 'should own all files' do
    # Ensure we reload ruby's usernames/groups
    Etc.endgrent
    Etc.endpwent
    Dir["/opt/kafka-offset-monitor/**/*"].each do |filePath|
      expect(Etc.getpwuid(File.stat(filePath).uid).name).to eq("kafka")
      expect(Etc.getgrgid(File.stat(filePath).gid).name).to eq("kafka")
    end
  end

  it 'should be able to connect to offset monitor and get home page' do
    wgetOutput = `wget http://localhost:8088 2>&1 | grep response`
    expect(wgetOutput).to include("200 OK")
  end

  it 'should be able to get monitoring details page for a topic' do
    # Generate a random topic
    topicName = "testNewTopic-" + rand(100000).to_s

    createOutput = `/opt/kafka/bin/kafka-topics.sh --create --topic #{topicName} --partitions 1 --replication-factor 1 --zookeeper localhost:2181 2> /dev/null`
    expect(createOutput).to include("Created topic")
    sleep 1

    wgetOutput = `wget http://localhost:8088/#/topicdetail/#{topicName} 2>&1 | grep response`
    expect(wgetOutput).to include("200 OK")
  end

  it 'should be able to get monitoring details page for a consumer group' do
    # Generate a random topic and group
    topicName = "testNewTopic-" + rand(100000).to_s
    groupName = "testNewGroup-" + rand(100000).to_s

    createOutput = `/opt/kafka/bin/kafka-topics.sh --create --topic #{topicName} --partitions 1 --replication-factor 1 --zookeeper localhost:2181 2> /dev/null`
    expect(createOutput).to include("Created topic")

    File.write('/tmp/consumer.properties', "group.id = #{groupName}")
    consumerOutput = `/opt/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --consumer.config /tmp/consumer.properties --topic #{topicName} --timeout-ms 500 2>&1`
    expect(consumerOutput).to include("kafka.consumer.ConsumerTimeoutException")

    wgetOutput = `wget http://localhost:8088/#/group/#{groupName} 2>&1 | grep response`
    expect(wgetOutput).to include("200 OK")
  end

end
