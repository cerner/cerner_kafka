name              "cerner_kafka"
maintainer        "Cerner Corp."
maintainer_email  "Bryan.Baugher@cerner.com"
license           "Apache-2.0"
description       "Installs and configures a Kafka"
issues_url        'https://github.com/cerner/cerner_kafka/issues'
source_url        'https://github.com/cerner/cerner_kafka'

supports 'centos'
supports 'redhat'
supports 'ubuntu'
supports 'debian'

depends 'java'
depends 'ulimit'
depends 'logrotate'

version           '2.6.1'

chef_version '>= 12.0' if respond_to?(:chef_version)
