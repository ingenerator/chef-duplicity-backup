require 'spec_helper'

describe 'duplicity-backup::schedule_backup' do
  cached (:chef_run) do
    ChefSpec::SoloRunner.new do | node |
      # Set non-standard attributes to check the recipe is using the attributes
      node.normal['duplicity']['cron_command'] = 'configurable_command'
      node.normal['duplicity']['mailto']       = 'someone@local'
      node.normal['duplicity']['schedule']     = {
        'minute'  => 1,
        'hour'    => 2,
        'day'     => 3,
        'weekday' => 4,
        'month'   => 5
      }
    end.converge(described_recipe)
  end    

  it "creates a cron for the backup job" do
    expect(chef_run).to create_cron("duplicity_backup")
  end
  
  it "uses the configurable command for the cron task to execute" do
    expect(chef_run).to create_cron("duplicity_backup").with({
      :command => 'configurable_command'
    })
  end
  
  it "sets the configured mailto address for the cron task" do
    expect(chef_run).to create_cron("duplicity_backup").with({
      :mailto => 'someone@local'
    })
  end
  
  it "sets the configured schedule for the cron task" do
    expect(chef_run).to create_cron("duplicity_backup").with({
      :minute  => '1',
      :hour    => '2',
      :day     => '3',
      :weekday => '4',
      :month   => '5'
    })
  end
  
  context "with some schedule attributes configured" do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['schedule']['hour'] = 3
      end.converge(described_recipe)
    end    

    it "sets other options to *" do
      expect(chef_run).to create_cron("duplicity_backup").with({
        :minute  => '*',
        :hour    => '3',
        :day     => '*',
        :weekday => '*',
        :month   => '*'
      })
    end
  end
  
  context "with default options and one schedule attribute configured" do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['schedule']['hour'] = 3
      end.converge(described_recipe)
    end    
    
    it "runs duplicity inside lockrun to prevent collisions" do
      expect(chef_run).to create_cron("duplicity_backup").with({
        :command => '/usr/local/bin/lockrun --lockfile=/var/run/duplicity_backup.lockrun -- /etc/duplicity/backup.sh'
      })
    end
        
    it "does not set a mailto address" do
      expect(chef_run).to create_cron("duplicity_backup").with({
        :mailto => nil
      })    
    end
  end
  
  context "if no schedule attributes are configured" do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new.converge(described_recipe)
    end    
    
    it "fails rather than schedule for every minute" do
      expect {
        chef_run
      }.to raise_error(ArgumentError)
    end
  
  end
end
