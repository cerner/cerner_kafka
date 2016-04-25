require 'spec_helper'

describe 'cerner_kafka::_user_group' do

  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
    end.converge(described_recipe)
  end

  it 'creates kafka user and group' do
    expect(chef_run).to create_group('kafka')
    expect(chef_run).to create_user('kafka').with(group: 'kafka',
                                                  shell: '/bin/bash',
                                                  home: '/home/kafka')
  end
end
