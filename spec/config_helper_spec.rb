require 'spec_helper'

describe CernerKafkaHelper do
  let(:node) do
    node = Chef::Node.new
    node.default['kafka']['server.properties'] = {}
    node.default['hostname'] = 'broker1'
    node.default['kafka']['version'] = '0.8.2.1'
    node.default['kafka']['brokers'] = ['broker1', 'broker2', 'broker3']
    node.default['kafka']['zookeepers'] = ['zoo1:2181', 'zoo2:2181', 'zoo3:2181']
    node
  end

  describe '#set_broker_id' do

    context 'brokers is provided and includes node' do
      it 'sets server.properties broker.id' do
        CernerKafkaHelper.set_broker_id node
        expect(node['kafka']['server.properties']['broker.id']).to eq(1)
      end
    end

    context 'brokers is provided and does not include node' do
      let(:bad_node) do
        bad_node = node
        bad_node.default['hostname'] = 'other_broker'
        bad_node
      end

      it 'raises an error' do
        expect { CernerKafkaHelper.set_broker_id bad_node }.to raise_error(RuntimeError)
      end
    end

    context 'brokers is not provided but broker.id is set' do
      let(:other_node) do
        other_node = node
        other_node.default['kafka']['brokers'] = nil
        other_node.default['kafka']['server.properties']['broker.id'] = 1
        other_node
      end

      it 'does nothing' do
        CernerKafkaHelper.set_broker_id other_node
        expect(other_node['kafka']['server.properties']['broker.id']).to eq(1)
      end
    end

    context 'brokers is not provided and broker.id is not set' do
      let(:bad_node) do
        bad_node = node
        bad_node.default['kafka']['brokers'] = nil
        bad_node
      end

      it 'raises an error' do
        expect { CernerKafkaHelper.set_broker_id bad_node }.to raise_error(RuntimeError)
      end
    end

    context 'brokers is not provided, broker.id is not set and version is 0.9.0.0' do
      let(:other_node) do
        other_node = node
        other_node.default['kafka']['version'] = '0.9.0.0'
        other_node.default['kafka']['brokers'] = nil
        other_node
      end

      it 'does nothing' do
        CernerKafkaHelper.set_broker_id other_node
        expect(other_node['kafka']['server.properties']['broker.id']).to eq(nil)
      end
    end

  end

  describe '#set_zookeeper_connect' do

    context 'zookeepers is provided' do
      it 'sets server.properties zookeeper.connect' do
        CernerKafkaHelper.set_zookeeper_connect node
        expect(node['kafka']['server.properties']['zookeeper.connect']).to eq('zoo1:2181,zoo2:2181,zoo3:2181')
      end
    end

    context 'zookeepers and chroot is provided' do
      let(:other_node) do
        other_node = node
        other_node.default['kafka']['zookeeper_chroot'] = '/my_chroot'
        other_node
      end

      it 'sets server.properties zookeeper.connect' do
        CernerKafkaHelper.set_zookeeper_connect other_node
        expect(other_node['kafka']['server.properties']['zookeeper.connect']).to eq('zoo1:2181,zoo2:2181,zoo3:2181/my_chroot')
      end
    end

    context 'zookeeper is not provided but includes zookeeper.connect' do
      let(:other_node) do
        other_node = node
        other_node.default['kafka']['zookeepers'] = nil
        other_node.default['kafka']['server.properties']['zookeeper.connect'] = 'zoo4:2181,zoo5:2181,zoo6:2181'
        other_node
      end

      it 'does nothing' do
        CernerKafkaHelper.set_zookeeper_connect other_node
        expect(other_node['kafka']['server.properties']['zookeeper.connect']).to eq('zoo4:2181,zoo5:2181,zoo6:2181')
      end
    end

    context 'zookeeper is not provided and does not include zookeeper.connect' do
      let(:bad_node) do
        bad_node = node
        bad_node.default['kafka']['zookeepers'] = nil
        bad_node
      end

      it 'raises an error' do
        expect { CernerKafkaHelper.set_zookeeper_connect bad_node }.to raise_error(RuntimeError)
      end
    end

  end

  describe '#broker_id' do
    let(:meta_with_broker_id) do
      [
        '# a comment',
        'version=0',
        'broker.id=1'
      ].join("\n")
    end

    let(:meta_without_broker_id) do
      [
        '# a comment',
        'version=0'
      ].join("\n")
    end

    context 'log.dir is set' do
      before(:each) do
        node.default['kafka']['server.properties']['broker.id'] = '123'
      end

      it 'should return broker id' do
        expect(CernerKafkaHelper.broker_id(node)).to eq('123')
      end
    end

    context 'log.dir is set' do
      before(:each) do
        node.default['kafka']['server.properties']['log.dir'] = '/var/kafka'
        allow(File).to receive(:exists?).with('/var/kafka/meta.properties').and_return(true)
        allow(IO).to receive(:read).with('/var/kafka/meta.properties').and_return(meta_with_broker_id)
      end

      it 'should return broker_id' do
        expect(CernerKafkaHelper.broker_id(node)).to eq('1')
      end
    end

    context 'log.dirs is set' do
      before(:each) do
        node.default['kafka']['server.properties']['log.dirs'] = '/var/kafka1,/var/kafka2'
        allow(File).to receive(:exists?).with('/var/kafka1/meta.properties').and_return(false)
        allow(File).to receive(:exists?).with('/var/kafka2/meta.properties').and_return(true)
        allow(IO).to receive(:read).with('/var/kafka2/meta.properties').and_return(meta_with_broker_id)
      end

      it 'should return broker_id' do
        expect(CernerKafkaHelper.broker_id(node)).to eq('1')
      end
    end

    context 'no log.dir(s) property is set' do
      it 'should return nil' do
        expect(CernerKafkaHelper.broker_id(node)).to eq(nil)
      end
    end

    context 'meta.properties file do not exist' do
      before(:each) do
        node.default['kafka']['server.properties']['log.dirs'] = '/var/kafka1,/var/kafka2'
        allow(File).to receive(:exists?).with('/var/kafka1/meta.properties').and_return(false)
        allow(File).to receive(:exists?).with('/var/kafka2/meta.properties').and_return(false)
      end

      it 'should return broker_id' do
        expect(CernerKafkaHelper.broker_id(node)).to eq(nil)
      end
    end

    context 'no broker.id in any meta.properties files' do
      before(:each) do
        node.default['kafka']['server.properties']['log.dirs'] = '/var/kafka1,/var/kafka2'
        allow(File).to receive(:exists?).with('/var/kafka1/meta.properties').and_return(false)
        allow(File).to receive(:exists?).with('/var/kafka2/meta.properties').and_return(true)
        allow(IO).to receive(:read).with('/var/kafka2/meta.properties').and_return(meta_without_broker_id)
      end

      it 'should return broker_id' do
        expect(CernerKafkaHelper.broker_id(node)).to eq(nil)
      end
    end
  end
end
