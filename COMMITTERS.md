Committers
==========

Merging Pull Requests
---------------------

All changes should be made via pull requests. A committer may merge a pull request if there has been 2 +1s from committers.

How to Release
--------------

 * Make sure a milestone has been created for the version (with name=version) and has issues set to it. Close the milestone when releasing.
 * Create an issue for the release, run the tests, include test evidence on the issue and get 2 +1s from committers.
 * Install everything needed for release by doing `bundle install --without travis --path vendor/bundle`
 * Add your supermarket login information if you haven't already `bundle exec stove login --username [USER] --key [SUPERMARKET_KEY_PATH]`
 * Then run the following command to release the cookbook `bundle exec rake release`

The `release` rake task will,

 * Update the [Change Log](CHANGELOG.md) with the milestone for the release
 * Share the cookbook to [Chef Supermarket](https://supermarket.chef.io)
 * Tag the cookbook with the current version
 * Bump the cookbook's version

Rake Tasks
----------

 * `release`: Releases the cookbook (updates change log, shares to supermarket, creates git tag and updates cookbook version)
 * `publish`: Publishes the cookbook (shares to supermarket and creates git tag)
 * `build_change_log`: Re-builds the entire change log from all closed milestones
