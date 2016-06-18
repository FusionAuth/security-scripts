# 2016-security-scripts

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

You can also use the Chef recipe instead of the `configure.sh` and `setup-new-server.sh` scripts.

To use this Chef recipe, all you need to do is configure the `default.rb` script to specify these settings:

  * Set the password hash for the ordinary user
  * Configure Monit to use your email server
  * Configure Monit to use Slack and/or Pushover

You will find comments in the `default.rb` file that are prefixed with `TODO`. This will let you know the sections of the Chef recipe that you must edit.
