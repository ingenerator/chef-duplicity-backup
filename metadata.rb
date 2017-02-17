name 'duplicity-backup'
maintainer 'Andrew Coulton'
maintainer_email 'andrew@ingenerator.com'
license 'Apache 2.0'
description 'Installs and configures duplicity for remote backup'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.0.0'
issues_url 'https://github.com/ingenerator/chef-duplicity-backup/issues'
source_url 'https://github.com/ingenerator/chef-duplicity-backup'

%w(ubuntu).each do |os|
  supports os
end

depends 'poise-python', '~> 1.5.1'
# Note: this should currently be >= 5.1, < 7.0 but it seems there's no way to
# express that at the moment per https://github.com/berkshelf/semverse/issues/10
depends 'database', '> 5.1'
depends 'monitored-cron', '~> 0.1'
depends 'postgresql'
