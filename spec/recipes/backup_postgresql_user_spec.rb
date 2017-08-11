require 'spec_helper'

describe 'duplicity-backup::backup_postgresql_user' do
  context "when postgresql backup is enabled" do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['backup_postgresql']     = true
        node.normal['duplicity']['postgresql']['user']       = 'backup'
        node.normal['duplicity']['postgresql']['password']   = 'backuppass'
        node.normal['postgresql']['password']['postgres']    = 'postgrespass'
      end.converge(described_recipe)
    end

    it "should include the database::postgresql recipe" do
      expect(chef_run).to include_recipe('database::postgresql')
    end

    it "should create a database user for backups" do
      expect(chef_run).to create_postgresql_database_user('backup')
    end

    it "should use the postgres account and postgres password attribute for the connection" do
      expect(chef_run).to create_postgresql_database_user('backup').with(
        :connection => { :host => 'localhost', :port => 5432, :username => 'postgres', :password => 'postgrespass' }
      )
    end

  end

  context "when postgresql backup is disabled" do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['backup_postgresql']   = false
        node.normal['duplicity']['postgresql']['user']  = 'backup'
      end.converge(described_recipe)
    end

    it "should not include the database::postgresql recipe" do
      expect(chef_run).not_to include_recipe('database::postgresql')
    end

    it "should not create a database user" do
      expect(chef_run).not_to create_postgresql_database_user('backup')
    end

  end

end
