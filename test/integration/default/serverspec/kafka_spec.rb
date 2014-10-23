# coding: UTF-8

require 'spec_helper'

describe user('kafka') do
  it { should exist }
  it { should belong_to_group 'kafka' }
end

describe service('kafka') do
  it { should be_running   }
end

# Kafka Broker API
describe port(6667) do
  it { should be_listening }
end

# Kafka Broker JMX
describe port(9999) do
  it { should be_listening }
end

describe file('/opt/kafka/libs/metrics-logback-3.1.0.jar') do
  it { should be_file }
  it { should be_owned_by 'kafka' }
  it { should be_grouped_into 'kafka' }
end

describe file('/opt/kafka/config/server.properties') do
  it { should be_file }
  it { should be_owned_by 'kafka' }
  it { should be_grouped_into 'kafka' }
  it { should contain 'bogus.for.testing=server' }
end

describe file('/opt/kafka/config/log4j.properties') do
  it { should be_file }
  it { should be_owned_by 'kafka' }
  it { should be_grouped_into 'kafka' }
  it { should contain 'bogus.for.testing=log4j' }
end

describe file('/etc/kafka') do
  it { should be_directory }
  it { should be_linked_to '/opt/kafka/config' }
end

['/var/kafka/data1', '/var/kafka/data2', '/var/kafka/data3'].each do |log_dir|
  describe file(log_dir) do
    it { should be_directory }
    it { should be_owned_by 'kafka' }
    it { should be_grouped_into 'kafka' }
  end
end

describe file('/etc/kafka') do
  it { should be_directory }
  it { should be_linked_to '/opt/kafka/config' }
end

['/var/kafka/data1', '/var/kafka/data2', '/var/kafka/data3'].each do |log_dir|
  describe file(log_dir) do
    it { should be_directory }
    it { should be_owned_by 'kafka' }
    it { should be_grouped_into 'kafka' }
  end
end


describe 'kafka broker' do

  it 'should own all files' do
    # Ensure we reload ruby's usernames/groups
    Etc.endgrent
    Etc.endpwent
    Dir["/opt/kafka/**/*"].each do |filePath|
      expect(Etc.getpwuid(File.stat(filePath).uid).name).to eq("kafka")
      expect(Etc.getgrgid(File.stat(filePath).gid).name).to eq("kafka")
    end
  end

  it 'should export all environment variables' do
    # For some reason having su run echo itself does not pickup the environment variables but it works if run in another shell script
    # This is ok since this is how we start Kafka (via scripts)
    File.open("/tmp/env_jmx.sh", 'w') { |file| file.write("echo \"$JMX_PORT\"") }
    File.open("/tmp/env_bogus.sh", 'w') { |file| file.write("echo \"$BOGUS_VAR\"") }

    # Make the scripts executable
    Kernel.system "chmod 755 /tmp/env_jmx.sh"
    Kernel.system "chmod 755 /tmp/env_bogus.sh"

    output = `su -l kafka -c "/tmp/env_jmx.sh 2> /dev/null"`
    expect(output).to include("9999")

    output = `su -l kafka -c "/tmp/env_bogus.sh 2> /dev/null"`
    expect(output).to include("TEST_VALUE")
  end

  it 'should be able to create a topic' do
    # Pick a random topic so if we re-run the tests on the same VM it won't fail with 'topic already created'
    topicName = "testNewTopic_" + rand(100000).to_s

    createOutput = `/opt/kafka/bin/kafka-topics.sh --create --topic #{topicName} --partitions 1 --replication-factor 1 --zookeeper localhost:2181 2> /dev/null`
    expect(createOutput).to include("Created topic")

    listOutput = `/opt/kafka/bin/kafka-topics.sh --list --zookeeper localhost:2181 2> /dev/null`
    expect(listOutput).to include("#{topicName}")
  end

  it 'should be able to read/write from a topic' do
    topic = "superTopic_" + rand(100000).to_s
    message = "super secret message"

    # Ensure the topic is created before having the consumer listen for it
    Kernel.system "/opt/kafka/bin/kafka-topics.sh --create --topic #{topic} --partitions 1 --replication-factor 1 --zookeeper localhost:2181 2> /dev/null"

    # The consumer command allows a user to 'listen' for messages on the topic and write them to STDOUT as they come in
    # In this case we are re-directing STDOUT to a file so we can read later
    # We also run this as a background process so we can also start the producer
    Kernel.system "/opt/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --whitelist #{topic} >> /tmp/consumer.out 2>&1 &"

    # The producer is a command that allows a user to write input to the console as 'messages' to the topic, separated by new line characters
    # In this case we run the command and write the same message several times over 5s in an attempt to ensure the consumer saw the message
    IO.popen("/opt/kafka/bin/kafka-console-producer.sh --topic #{topic} --broker-list localhost:6667 2> /dev/null", mode='r+') do |io|
      writes = 5
      while writes > 0
        io.write message + "\n"
        writes = writes - 1
        sleep 1
      end
      io.close_write
    end

    # Ensure consumer processes are stopped
    consumerPids = `ps -ef | grep kafka.consumer.ConsoleConsumer | grep -v grep | awk '{print $2}'`
    consumerPids.split("\n").each do |pid|
      Process.kill 9, pid.to_i
    end

    # Read the consumer's STDOUT file
    consumerOutput = IO.read("/tmp/consumer.out")

    # Verify the consumer saw at least 1 message
    expect(consumerOutput).to include(message)

  end

end
