default['security_guide'] = {
  :users => [],
  :sudo_group => 'sudo',
  :monit => {
    :email_server => 'localhost',
    :email_port => '25',
    #:email_username => 'username',
    #:email_password => 'password',
    #:email_encryption => 'tlsv12',
    #:alert_email => 'alerts@example.com',

    :slack_url => '',
    :slack_enabled => 'false',
    :pushover_application => '',
    :pushover_user => '',
    :pushover_enabled => 'false'
  }
}
