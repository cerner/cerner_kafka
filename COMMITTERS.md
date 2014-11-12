Committers
==========

Merging Pull Requests
---------------------

All changes should be made via pull requests. A committer may merge a pull request if there has been 2 +1s from committers. 

How to Release
--------------

 * Make sure a milestone has been created for the version (with name=version) and has issues set to it. Close the milestone when releasing.
 * Create an issue for the release and get 2 +1s from committers.
 * Make sure you have everything installed listed on the [README](README.md) listed under testing.
 * Ensure you have the following properties in `~/.chef/knife.rb`
   * `user_name`: The username of your supermarket account
   * `user_key`: The path to the key for the supermarket account

Then run the following command to release the cookbook,

    rake release

This will,

 * Run all tests
 * Update the [Change Log](CHANGELOG.md) with the milestone for the release
 * Share the cookbook to [Chefs Supermarket](https://supermarket.getchef.com/dashboard)
 * Tag the cookbook with the current version
 * Bump the version

Rake Tasks
----------

 * `unit_test`: Runs the unit tests for the cookbook
 * `integration_test`: Runs the integration tests for the cookbook
 * `lint_test`: Runs the lint tests for the cookbook
 * `test`: Runs all tests for the cookbook
 * `release`: Runs all tests and then releases the cookbook. NOTE: If you need to skip tests while releasing set the `SKIP_TESTS` to any value
 * `build_change_log`: Re-builds the entire changelog from all closed milestones