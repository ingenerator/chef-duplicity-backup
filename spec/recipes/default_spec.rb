require 'spec_helper'

describe 'duplicity-backup::default' do
  cached (:chef_run) do
    ChefSpec::SoloRunner.new do | node |
      # Define the required attributes that we'll fail without
      node.normal['duplicity']['backup_passphrase']  = 'pass'
      node.normal['duplicity']['db_destination']     = 's3+http://bucket/dbpath'
      node.normal['duplicity']['file_destination']   = 's3+http://bucket/filepath'
      node.normal['duplicity']['keep_n_full']        = '5'
      node.normal['duplicity']['full_if_older_than'] = '7D'
      node.normal['duplicity']['mysql']['user']      = 'backup'
      node.normal['duplicity']['schedule']     = {
        'minute'  => 1,
        'hour'    => 2,
        'day'     => 3,
        'weekday' => 4,
        'month'   => 5
      }
    end.converge(described_recipe)
  end

  before(:each) do
    stub_command('which lockrun').and_return('')
  end

  it "installs duplicity" do
    expect(chef_run).to include_recipe("duplicity-backup::install_duplicity")
  end
    
  it "configures the backup scripts and credentials" do
    expect(chef_run).to include_recipe("duplicity-backup::configure_backup")
  end

  it "creates a mysql user for backup" do
    expect(chef_run).to include_recipe("duplicity-backup::backup_mysql_user")
  end

  it "schedules the backup cron" do
    expect(chef_run).to include_recipe("duplicity-backup::schedule_backup")
  end

end
