# 2016_security_guide

This is the Chef Cookbook that models all of the server setup based on Inversoft's for the 2016 Security Guide located here:

https://www.inversoft.com/guides/2016-guide-to-user-data-security

To use this Chef Cookbook, all you need to do is configure these required attributes:

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
