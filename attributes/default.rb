# coding: UTF-8
# Cookbook Name:: cerner_kafka
# Attributes:: default

default["kafka"]["user"] = "kafka"
default["kafka"]["group"] = "kafka"

default["kafka"]["scala_version"] = "2.11"
default["kafka"]["version"] = "0.9.0.0"
default["kafka"]["download_url"] = "https://archive.apache.org/dist/kafka"

default["kafka"]["base_dir"]  = "/opt"
default["kafka"]["log_dir"] = "/var/log/kafka"

# Set Log file for kafka init script stdout/stderr
default["kafka"]["service"]["stdout"] = File.join node["kafka"]["log_dir"], "kafka_init_stdout.log"
default["kafka"]["service"]["stderr"] = File.join node["kafka"]["log_dir"], "kafka_init_stderr.log"

# These are required to be supplied by the consumer so setting to nil
default["kafka"]["brokers"] = nil
default["kafka"]["zookeepers"] = nil
default["kafka"]["zookeeper_chroot"] = nil

# This is our old attribute, kept here for compatability
default["kafka"]["shutdown_timeout"] = 30
# How long we should wait before failing if Kafka won't stop
default["kafka"]["init"]["shutdown_timeout"] = node["kafka"]["shutdown_timeout"]
# How long we should sleep between stop and start during restart
default["kafka"]["init"]["sleep_between_restart"] = 0
# The name of the Kafka process we should look for
default["kafka"]["init"]["kafka_main"] = "kafka.Kafka"
# How long we should sleep in stop before checking if kafka is still running
default["kafka"]["init"]["stop_sleep_time"] = 5

default["kafka"]["env_vars"]["JMX_PORT"] = "9999"
default["kafka"]["env_vars"]["KAFKA_HEAP_OPTS"] = "\"-Xmx4G -Xms4G\""
default["kafka"]["env_vars"]["KAFKA_JVM_PERFORMANCE_OPTS"] = "\"-XX:PermSize=48m -XX:MaxPermSize=48m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35\""
default["kafka"]["lib_jars"] = []

default["kafka"]["logrotate"]["path"] = [node["kafka"]["service"]["stdout"], node["kafka"]["service"]["stderr"]]
default["kafka"]["logrotate"]["frequency"] = 'daily'
default["kafka"]["logrotate"]["rotate"] = 5

default["kafka"]["server.properties"] = {}

# Log4J config
default["kafka"]["log4j.properties"]["log4j.rootLogger"] = "INFO"
default["kafka"]["log4j.properties"]["log4j.appender.kafkaAppender"] = "org.apache.log4j.RollingFileAppender"
default["kafka"]["log4j.properties"]["log4j.appender.kafkaAppender.MaxBackupIndex"] = "20"
default["kafka"]["log4j.properties"]["log4j.appender.kafkaAppender.layout"] = "org.apache.log4j.PatternLayout"
default["kafka"]["log4j.properties"]["log4j.appender.kafkaAppender.layout.ConversionPattern"] = "%d{ISO8601} %p %c: %m%n"
default["kafka"]["log4j.properties"]["log4j.appender.stateChangeAppender"] = "org.apache.log4j.RollingFileAppender"
default["kafka"]["log4j.properties"]["log4j.appender.stateChangeAppender.MaxBackupIndex"] = "20"
default["kafka"]["log4j.properties"]["log4j.appender.stateChangeAppender.layout"] = "org.apache.log4j.PatternLayout"
default["kafka"]["log4j.properties"]["log4j.appender.stateChangeAppender.layout.ConversionPattern"] = "%d{ISO8601} %p %c: %m%n"
default["kafka"]["log4j.properties"]["log4j.appender.requestAppender"] = "org.apache.log4j.RollingFileAppender"
default["kafka"]["log4j.properties"]["log4j.appender.requestAppender.MaxBackupIndex"] = "20"
default["kafka"]["log4j.properties"]["log4j.appender.requestAppender.layout"] = "org.apache.log4j.PatternLayout"
default["kafka"]["log4j.properties"]["log4j.appender.requestAppender.layout.ConversionPattern"] = "%d{ISO8601} %p %c: %m%n"
default["kafka"]["log4j.properties"]["log4j.appender.controllerAppender"] = "org.apache.log4j.RollingFileAppender"
default["kafka"]["log4j.properties"]["log4j.appender.controllerAppender.MaxBackupIndex"] = "20"
default["kafka"]["log4j.properties"]["log4j.appender.controllerAppender.layout"] = "org.apache.log4j.PatternLayout"
default["kafka"]["log4j.properties"]["log4j.appender.controllerAppender.layout.ConversionPattern"] = "%d{ISO8601} %p %c: %m%n"
default["kafka"]["log4j.properties"]["log4j.logger.kafka"] = "INFO, kafkaAppender"
default["kafka"]["log4j.properties"]["log4j.logger.kafka.network.RequestChannel$"] = "INFO, requestAppender"
default["kafka"]["log4j.properties"]["log4j.additivity.kafka.network.RequestChannel$"] = "false"
default["kafka"]["log4j.properties"]["log4j.logger.kafka.request.logger"] = "INFO, requestAppender"
default["kafka"]["log4j.properties"]["log4j.additivity.kafka.request.logger"] = "false"
default["kafka"]["log4j.properties"]["log4j.logger.kafka.controller"] = "INFO, controllerAppender"
default["kafka"]["log4j.properties"]["log4j.additivity.kafka.controller"] = "false"
default["kafka"]["log4j.properties"]["log4j.logger.state.change.logger"] = "INFO, stateChangeAppender"
default["kafka"]["log4j.properties"]["log4j.additivity.state.change.logger"] = "false"

#Offset monitor config
default["kafka"]["offset_monitor"]["url"] = "https://github.com/quantifind/KafkaOffsetMonitor/releases/download/v0.2.1/KafkaOffsetMonitor-assembly-0.2.1.jar"
default["kafka"]["offset_monitor"]["main_class"] = "com.quantifind.kafka.offsetapp.OffsetGetterWeb"
default["kafka"]["offset_monitor"]["port"] = "8080"
default["kafka"]["offset_monitor"]["db_name"] = "offset_monitor"
default["kafka"]["offset_monitor"]["refresh"] = "15.minutes"
default["kafka"]["offset_monitor"]["retain"] = "7.days"

default["kafka"]["offset_monitor"]["options"]["--port"] = node["kafka"]["offset_monitor"]["port"]
default["kafka"]["offset_monitor"]["options"]["--dbName"] = node["kafka"]["offset_monitor"]["db_name"]
default["kafka"]["offset_monitor"]["options"]["--refresh"] = node["kafka"]["offset_monitor"]["refresh"]
default["kafka"]["offset_monitor"]["options"]["--retain"] = node["kafka"]["offset_monitor"]["retain"]
