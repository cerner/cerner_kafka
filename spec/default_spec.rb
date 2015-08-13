require 'spec_helper'

describe 'cerner_kafka::default' do

  before do
    Fauxhai.mock(platform:'redhat', version:'6.5')
  end

  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['kafka']['brokers'] = ['chefspec']
      node.set['kafka']['zookeepers'] = ['localhost:2181']
    end
  end

  it 'runs the code block to assure that broker and zookeeper node attributes are set' do
    chef_run.converge(described_recipe)
    expect(chef_run).to run_ruby_block('attribute_assertions')
  end

  it 'use zookeepers and brokers attributes' do
    chef_run.converge(described_recipe)
    expect(chef_run).to start_service('kafka')
  end

  it 'use zookeepers, brokers and chroot attributes' do
    chef = ChefSpec::SoloRunner.new do |node|
      node.set['kafka']['brokers'] = ['chefspec']
      node.set['kafka']['zookeepers'] = ['host1:2181', 'host2:2181', 'host3:2181']
      node.set['kafka']['zookeeper_chroot'] = '/kafka/test'
    end

    chef.converge(described_recipe)
    expect(chef).to start_service('kafka')
  end

  it 'use zookeepers and broker.id attributes' do
    chef = ChefSpec::SoloRunner.new do |node|
      node.set['kafka']['server.properties']['broker.id'] = 1
      node.set['kafka']['zookeepers'] = ['localhost:2181']
    end

    chef.converge(described_recipe)
    expect(chef).to start_service('kafka')
  end

  it 'use brokers and zookeeper.connect attributes' do
    chef = ChefSpec::SoloRunner.new do |node|
      node.set['kafka']['brokers'] = ['chefspec']
      node.set['kafka']['server.properties']['zookeeper.connect'] = 'localhost:2181'
    end

    chef.converge(described_recipe)
    expect(chef).to start_service('kafka')
  end

  it 'use broker.id and zookeeper.connect attributes' do
    chef = ChefSpec::SoloRunner.new do |node|
      node.set['kafka']['server.properties']['broker.id'] = 1
      node.set['kafka']['server.properties']['zookeeper.connect'] = 'localhost:2181'
    end

    chef.converge(described_recipe)
    expect(chef).to start_service('kafka')
  end

  context 'with version set to 0.8.0' do

    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['kafka']['brokers'] = ['chefspec']
        node.set['kafka']['zookeepers'] = ['localhost:2181']
        node.set['kafka']['version'] = '0.8.0'
      end
    end

    before(:each) do
      chef_run.converge(described_recipe)
    end

    it 'should overwrite kafka-server-start.sh' do
      expect(chef_run).to create_template('/opt/kafka/bin/kafka-server-stop.sh')
    end

    it 'should overwrite kafka-server-stop.sh'  do
      expect(chef_run).to create_template('/opt/kafka/bin/kafka-server-stop.sh')
    end

  end

  context 'with version set to 0.8.1' do

    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['kafka']['brokers'] = ['chefspec']
        node.set['kafka']['zookeepers'] = ['localhost:2181']
        node.set['kafka']['version'] = '0.8.1'
      end
    end

    before(:each) do
      chef_run.converge(described_recipe)
    end

    it 'should overwrite kafka-server-start.sh' do
      expect(chef_run).to create_template('/opt/kafka/bin/kafka-server-stop.sh')
    end

    it 'should overwrite kafka-server-stop.sh'  do
      expect(chef_run).to create_template('/opt/kafka/bin/kafka-server-stop.sh')
    end

  end

  context 'with version set to 0.8.2' do

    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['kafka']['brokers'] = ['chefspec']
        node.set['kafka']['zookeepers'] = ['localhost:2181']
        node.set['kafka']['version'] = '0.8.2'
      end
    end

    before(:each) do
      chef_run.converge(described_recipe)
    end

    it 'should not overwrite kafka-server-start.sh' do
      expect(chef_run).not_to create_template('/opt/kafka/bin/kafka-server-stop.sh')
    end

    it 'should not overwrite kafka-server-stop.sh'  do
      expect(chef_run).not_to create_template('/opt/kafka/bin/kafka-server-stop.sh')
    end

  end

end
