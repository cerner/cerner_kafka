Change Log
==========

[2.2.0 - 05-03-2016](https://github.com/cerner/cerner_kafka/issues?milestone=7&state=closed)
--------------------------------------------------------------------------------------------

  * [Feature] [Issue-49](https://github.com/cerner/cerner_kafka/issues/49) : Support any option for offset monitor
  * [Enhancement] [Issue-46](https://github.com/cerner/cerner_kafka/issues/46) : #45: Cleaned up init script and added sleep between stop/start during…
  * [Enhancement] [Issue-45](https://github.com/cerner/cerner_kafka/issues/45) : Add sleep between restart
  * [Bug] [Issue-44](https://github.com/cerner/cerner_kafka/issues/44) : #43: Fixed init math logic
  * [Bug] [Issue-43](https://github.com/cerner/cerner_kafka/issues/43) : Init script number addition incorrect
  * [Enhancement] [Issue-38](https://github.com/cerner/cerner_kafka/issues/38) : Setup travis to run test-kitchen via docker

[2.1.1 - 04-26-2016](https://github.com/cerner/cerner_kafka/issues?milestone=6&state=closed)
--------------------------------------------------------------------------------------------

  * [Bug] [Issue-41](https://github.com/cerner/cerner_kafka/issues/41) : moved kafka user configuration back into default recipe

[2.1.0 - 04-25-2016](https://github.com/cerner/cerner_kafka/issues?milestone=5&state=closed)
--------------------------------------------------------------------------------------------

  * [Enhancement] [Issue-39](https://github.com/cerner/cerner_kafka/issues/39) : separated user and group logic to another recipe

[2.0.0 - 02-12-2016](https://github.com/cerner/cerner_kafka/issues?milestone=4&state=closed)
--------------------------------------------------------------------------------------------

  * [Enhancement] [Issue-33](https://github.com/cerner/cerner_kafka/issues/33) : Default to version 0.9.0 and scala 2.11
  * [Bug] [Issue-29](https://github.com/cerner/cerner_kafka/issues/29) : kafka stdout logs same thing as server.log
  * [Enhancement] [Issue-28](https://github.com/cerner/cerner_kafka/issues/28) : add libraries to find broker id and zookeepers
  * [Enhancement] [Issue-14](https://github.com/cerner/cerner_kafka/issues/14) : Remove broker config defaults

[1.1.0 - 08-14-2015](https://github.com/cerner/cerner_kafka/issues?milestone=2&state=closed)
--------------------------------------------------------------------------------------------

  * [Enhancement] [Issue-24](https://github.com/cerner/cerner_kafka/issues/24) : I've encountered some issues on the shell scripts with this cookbook. Here are my proposed fix and improvements
  * [Enhancement] [Issue-22](https://github.com/cerner/cerner_kafka/issues/22) : lock file cleanup, make kafka user uid configureable
  * [Enhancement] [Issue-18](https://github.com/cerner/cerner_kafka/issues/18) : fix adding nil if hostname isn't set up first
  * [Feature] [Issue-12](https://github.com/cerner/cerner_kafka/issues/12) : Support zookeeper chroot in a first class manner
  * [Bug] [Issue-10](https://github.com/cerner/cerner_kafka/issues/10) : Error executing action `stop` on resource 'service[kafka]'
  * [Enhancement] [Issue-9](https://github.com/cerner/cerner_kafka/issues/9) : Setup repo to use travis ci
  * [Enhancement] [Issue-8](https://github.com/cerner/cerner_kafka/issues/8) : Updated README with release info, created COMMITTERS file for commiter i...
  * [Enhancement] [Issue-7](https://github.com/cerner/cerner_kafka/issues/7) : Cleaned up code to add stderr/stdout logging for kafka start/stop comman...
  * [Enhancement] [Issue-6](https://github.com/cerner/cerner_kafka/issues/6) : Add kafka service stdout and stderr
  * [Enhancement] [Issue-3](https://github.com/cerner/cerner_kafka/issues/3) : Restrict overwriting kafka-server-stop.sh to < 0.8.2
