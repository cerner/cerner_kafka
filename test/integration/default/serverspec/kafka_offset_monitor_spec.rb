# coding: UTF-8

require 'spec_helper'

# We can't use service serverspec resource as ubuntu's service command (init)
# doesn't seem to understand our init.d script
describe command('/etc/init.d/kafka-offset-monitor status') do
  its(:stdout) { should contain('Kafka offset monitor is running') }
  its(:exit_status) { should eq 0 }
end

# Kafka Offset Monitor API
describe port(8088) do
  it { should be_listening }
end

describe command('ps aux | grep kafka-offset-monitor') do
  its(:stdout) { should contain('java -cp /opt/kafka-offset-monitor/KafkaOffsetMonitor-assembly-0.2.1.jar com.quantifind.kafka.offsetapp.OffsetGetterWeb --port 8088 --dbName offset_monitor --refresh 15.minutes --retain 7.days --zk localhost:2181 --zkSessionTimeout 30.seconds') }
  its(:exit_status) { should eq 0 }
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

  describe command('curl -f http://localhost:8088') do
    its(:exit_status) { should eq 0 }
  end

  it 'should be able to get monitoring details page for a topic' do
    # Generate a random topic
    topicName = "testNewTopic-" + rand(100000).to_s

    createOutput = `/opt/kafka/bin/kafka-topics.sh --create --topic #{topicName} --partitions 1 --replication-factor 1 --zookeeper localhost:2181 2> /dev/null`
    expect(createOutput).to include("Created topic")
    sleep 1

    wgetOutput = `curl -f http://localhost:8088/#/topicdetail/#{topicName}`
    expect($?.success?).to eq(true)
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

    wgetOutput = `curl -f http://localhost:8088/#/group/#{groupName}`
    expect($?.success?).to eq(true)
  end

end
