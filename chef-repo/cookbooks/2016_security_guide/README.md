# 2016_security_guide

This is the Chef recipe that models all of the server setup based on Inversoft's for the 2016 Security Guide located here:

https://www.inversoft.com/guides/2016-guide-to-user-data-security

To use this Chef recipe, all you need to do is configure the `default.rb` script to specify these settings:

  * Set the password hash for the ordinary user
  * Configure Monit to use your email server
  * Configure Monit to use Slack and/or Pushover

You will find comments in the `default.rb` file that are prefixed with `TODO`. This will let you know the sections of the Chef recipe that you must edit.

