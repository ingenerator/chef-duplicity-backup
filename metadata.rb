name 'duplicity-backup'
maintainer 'Andrew Coulton'
maintainer_email 'andrew@ingenerator.com'
license 'Apache 2.0'
description 'Installs and configures duplicity for remote backup'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

%w(ubuntu).each do |os|
  supports os
end

depends "python"

# For automatic setup of database backup users
depends "database"
depends "mysql"
