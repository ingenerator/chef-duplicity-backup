require 'spec_helper'

describe 'duplicity-backup::backup_postgresql_user' do
  context "when postgresql backup is enabled" do
    let (:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '12.04') do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.set['duplicity']['backup_postgresql']     = true
        node.set['duplicity']['postgresql']['user']       = 'backup'
        node.set['duplicity']['postgresql']['password']   = 'backuppass'
        node.set['postgresql']['password']['postgres']    = 'postgrespass'
      end.converge(described_recipe)
    end

    it "should include the database::postgresql recipe" do
      chef_run.should include_recipe('database::postgresql')
    end

    it "should create a database user for backups" do
      chef_run.should create_postgresql_database_user('backup')
    end

    it "should use the postgres account and postgres password attribute for the connection" do
      chef_run.should create_postgresql_database_user('backup').with(
        :connection => { :host => 'localhost', :port => 5432, :username => 'postgres', :password => 'postgrespass' }
      )
    end

  end

  context "when postgresql backup is disabled" do
    let (:chef_run) do
      ChefSpec::SoloRunner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.set['duplicity']['backup_postgresql']   = false
        node.set['duplicity']['postgresql']['user']  = 'backup'
      end.converge(described_recipe)
    end

    it "should not include the database::postgresql recipe" do
      chef_run.should_not include_recipe('database::postgresql')
    end

    it "should not create a database user" do
      chef_run.should_not create_postgresql_database_user('backup')
    end

  end

end
