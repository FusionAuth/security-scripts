# Security Scripts

These scripts provided a practical implementation of the steps and practices described in the FusionAuth Security Guide. 
https://fusionauth.io/resources/guide-to-user-data-security

This project contains a set of bash scripts that can be used to secure a new Linux server. The scripts are broken into parts:

  - Configuration
  - Server setup

## Configuration

Before you can use secure your server, you need to run the configuration script. This script is named `configure.sh`. This script will ask you a variety of questions related to your server including:

  - IP Address
  - Alert email
  - SMTP server
  - SMTP port
  - SMTP username
  - SMTP password
  - SMTP encryption (if any)
  - Slack Webhook URL
  - Pushover application and user keys

After the script has asked all the questions, it will output all of the necessary configuration files that the server setup scripts will use. These will be placed in the `output` directory.

## Server Setup

After you run the configure script, you can run the server setup script. This script is named `setup-new-server.sh`. This script will prompt you for the password for the ordinary user account that is created on the server and then it will upload all of the files from the output directory to the server and execute the install script on the server.

## Chef

You can also use the Chef Cookbook instead of the `configure.sh` and `setup-new-server.sh` scripts. The Chef Cookbook is located in the `chef-repo/cookbooks`. You can install this Cookbook in your Chef server by executing these commands:

```
$ cd chef-repo
$ knife cookbook upload security_guide
```

This will add the Cookbook to the Chef server that is configured in your `knife.rb` file. From there, you can use the Cookbook to bootstrap your nodes.

To use this Chef Cookbook, you first need to configure these required attributes:

  * `node['security_guide']['users']` - This is an array that contains the users that the Chef recipe will create on the server. Each user must have these attributes:
    * `username` - The username of the user
    * `password` - The hashed password of the user (this is put directly in the /etc/shadow file)
    * `public_key` - The RSA public key of the user
  * `node['security_guide']['monit']['alert_email]` - The email address where Monit alerts are sent

In addition to the required attributes, the Chef Cookbook also takes these optional attributes:

  * `node['security_guide']['sudo_group']` - The name of the group that grants a user sudo access (defaults to `sudo`)
  * `node['security_guide']['monit']['email_server']` - The name of the SMTP server Monit uses to send emails (defaults to `localhost`)
  * `node['security_guide']['monit']['email_port']` - The SMTP port Monit uses to send emails (defaults to `25`)
  * `node['security_guide']['monit']['email_username']` - The username that Monit uses to connect to the SMTP server
  * `node['security_guide']['monit']['email_password']` - The password that Monit uses to connect to the SMTP server
  * `node['security_guide']['monit']['email_encryption']` - The encryption Monit uses to connect to the SMTP server. This must be `ssl` or `tlsv12` if specified
  * `node['security_guide']['monit']['slack_url']` - The Slack Webhook URL that Monit will use to send Slack notifications (defaults to `''`)
  * `node['security_guide']['monit']['slack_enabled']` - Whether or not Slack notifications are enabled as a String not a boolean (defaults to `'false'`)
  * `node['security_guide']['monit']['pushover_application']` - The Pushover application id Monit uses to send Pushover notifications to (defaults to `''`)
  * `node['security_guide']['monit']['pushover_user']` - The Pushover user id Monit uses to send Pushover notifications to (defaults to `''`)
  * `node['security_guide']['monit']['pushover_enabled']` - Whether or not Pushover notifications are enabled as a String not a boolean (defaults to `'false'`)

You can set these attributes via a node attribute file, role or environment setting. The Chef recipe will verify that you have specified the required attributes and fail if they are absent.
