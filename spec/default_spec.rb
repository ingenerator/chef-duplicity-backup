require 'spec_helper'

describe 'duplicity-backup::default' do
  let (:chef_run) do
    ChefSpec::Runner.new do | node |
      # Define the required attributes that we'll fail without
      node.set['duplicity']['schedule']     = {
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
    chef_run.should include_recipe("duplicity-backup::install_duplicity")
  end
  
  it "installs lockrun" do
    chef_run.should include_recipe("duplicity-backup::install_lockrun")
  end
  
  it "configures the backup scripts and credentials" do
    chef_run.should include_recipe("duplicity-backup::configure_backup")
  end
  
  it "creates a mysql user for backup" do
    chef_run.should include_recipe("duplicity-backup::backup_mysql_user")
  end
  
  it "schedules the backup cron" do
    chef_run.should include_recipe("duplicity-backup::schedule_backup")
  end

end
