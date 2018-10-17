name 'security_guide'
maintainer 'Inversoft'
maintainer_email 'brian@inversoft.com'
license 'all_rights'
description 'Installs/Configures security_guide'
long_description 'Installs/Configures security_guide'
version '0.1.0'
attribute 'security_guide/users',
          :display_name => 'Users',
          :description => 'List of the users to create on the server',
          :type => 'array',
          :required => 'required'
attribute 'security_guide/monit/alert_email',
          :display_name => 'Monit Alert Email',
          :description => 'The email where Monit sends alerts',
          :type => 'string',
          :required => 'required'
