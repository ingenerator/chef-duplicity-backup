require 'spec_helper'

describe 'duplicity-backup::backup_mysql_user' do
  context "when mysql backup is enabled" do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['backup_mysql']     = true
        node.normal['duplicity']['mysql']['user']       = 'backup'
        node.normal['duplicity']['mysql']['password']   = 'backuppwd'
        node.normal['mysql']['server_root_password'] = 'mysql'
      end.converge(described_recipe)
    end

    it "should create a database user for backups" do
      expect(chef_run).to grant_mysql_database_user('backup')
    end

    it "should use the root account and root password attribute for the connection" do
      expect(chef_run).to grant_mysql_database_user('backup').with(
        :connection => { :host => 'localhost', :username => 'root', :password => 'mysql' }
      )
    end

    it "should create the user with the configured password and access only from localhost" do
      expect(chef_run).to grant_mysql_database_user('backup').with(
        :password  => 'backuppwd',
        :host      => 'localhost'
      )
    end

    it "should grant global read-only backup privileges to the user" do
      expect(chef_run).to grant_mysql_database_user('backup').with(
        :database_name  => nil,
        :privileges     => ['SELECT', 'SHOW VIEW', 'TRIGGER', 'LOCK TABLES', 'EVENT']
      )
    end

  end

  context "when mysql backup is disabled" do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['backup_mysql']   = false
        node.normal['duplicity']['mysql']['user']  = 'backup'
      end.converge(described_recipe)
    end

    it "should not include the database::mysql recipe" do
      expect(chef_run).not_to include_recipe('database::mysql')
    end

    it "should not create a database user" do
      expect(chef_run).not_to grant_mysql_database_user('backup')
    end

  end

end
