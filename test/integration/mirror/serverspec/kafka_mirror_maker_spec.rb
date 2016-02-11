# coding: UTF-8

require 'spec_helper'

describe user('kafka') do
  it { should exist }
  it { should belong_to_group 'kafka' }
end

describe service('kafka-mirror-maker') do
  it { should be_running   }
end

# Kafka mirror JMX
describe port(9998) do
  it { should be_listening }
end

describe file('/opt/kafka/config/mirror_target.properties') do
  it { should be_file }
  it { should be_owned_by 'kafka' }
  it { should be_grouped_into 'kafka' }
  #it { should contain 'bogus.for.testing=server' }
end

describe file('/opt/kafka/config/mirror_source1.properties') do
  it { should be_file }
  it { should be_owned_by 'kafka' }
  it { should be_grouped_into 'kafka' }
  #it { should contain 'bogus.for.testing=server' }
end

describe file('/opt/kafka/config/mirror-log4j.properties') do
  it { should be_file }
  it { should be_owned_by 'kafka' }
  it { should be_grouped_into 'kafka' }
  #it { should contain 'bogus.for.testing=log4j' }
end

describe 'kafka mirror' do

  it 'should own all files' do
    # Ensure we reload ruby's usernames/groups
    Etc.endgrent
    Etc.endpwent
    Dir["/opt/kafka/**/*"].each do |filePath|
      expect(Etc.getpwuid(File.stat(filePath).uid).name).to eq("kafka")
      expect(Etc.getgrgid(File.stat(filePath).gid).name).to eq("kafka")
    end
  end

  it 'should be able to read/write from a topic through a mirror' do
    topic = "superTopic_" + rand(100000).to_s
    message = "super secret message " + rand(100000).to_s

    # Ensure the topic is created before having the consumer listen for it
    # Remote
    Kernel.system "/opt/kafka/bin/kafka-topics.sh --create --topic #{topic} --partitions 1 --replication-factor 1 --zookeeper 10.10.10.10:2181 2> /dev/null"
    # Local
    #Kernel.system "/opt/kafka/bin/kafka-topics.sh --create --topic #{topic} --partitions 1 --replication-factor 1 --zookeeper localhost:2181 2> /dev/null"

    # The consumer command allows a user to 'listen' for messages on the topic and write them to STDOUT as they come in
    # In this case we are re-directing STDOUT to a file so we can read later
    # We also run this as a background process so we can also start the producer
    Kernel.system "/opt/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --whitelist #{topic} >> /tmp/consumer.out 2>&1 &"

    # The producer is a command that allows a user to write input to the console as 'messages' to the topic, separated by new line characters
    # In this case we run the command and write the same message several times over 5s in an attempt to ensure the consumer saw the message
    IO.popen("/opt/kafka/bin/kafka-console-producer.sh --topic #{topic} --broker-list 10.10.10.10:6667 2> /dev/null", mode='r+') do |io|
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
