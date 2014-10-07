source "https://api.berkshelf.com"

metadata

group :test do
  # Kafka requires zookeeper to run so our tests need this to work
  cookbook "apache_zookeeper"

  # There is an issue where java won't install correctly without doing an apt-update in our tests
  cookbook "apt", "~> 2.4"
end
