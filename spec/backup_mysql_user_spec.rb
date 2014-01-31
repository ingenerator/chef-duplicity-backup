require 'spec_helper'

describe 'duplicity-backup::backup_mysql_user' do
  context "when mysql backup is enabled" do
    let (:chef_run) do
      ChefSpec::Runner.new(platform: 'ubuntu', version: '12.04') do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.set['duplicity']['backup_mysql']     = true
        node.set['duplicity']['mysql']['user']       = 'backup'
        node.set['duplicity']['mysql']['password']   = 'backuppwd'
        node.set['mysql']['server_root_password'] = 'mysql'
      end.converge(described_recipe)
    end
    
    it "should include the database::mysql recipe" do
      chef_run.should include_recipe('database::mysql')
    end
    
    it "should create a database user for backups" do
      chef_run.should grant_mysql_database_user('backup')
    end
    
    it "should use the root account and root password attribute for the connection" do
      chef_run.should grant_mysql_database_user('backup').with(
        :connection => { :host => 'localhost', :username => 'root', :password => 'mysql' }
      )
    end
    
    it "should create the user with the configured password and access only from localhost" do
      chef_run.should grant_mysql_database_user('backup').with(
        :password  => 'backuppwd',
        :host      => 'localhost'
      )
    end
    
    it "should grant global read-only backup privileges to the user" do
      chef_run.should grant_mysql_database_user('backup').with(
        :database_name  => '*',
        :privileges     => ['SELECT', 'SHOW VIEW', 'TRIGGER', 'LOCK TABLES']
      )      
    end
  
  end

  context "when mysql backup is disabled" do
    let (:chef_run) do
      ChefSpec::Runner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.set['duplicity']['backup_mysql']   = false
        node.set['duplicity']['mysql']['user']  = 'backup'
      end.converge(described_recipe)
    end
    
    it "should not include the database::mysql recipe" do
      chef_run.should_not include_recipe('database::mysql')
    end
    
    it "should not create a database user" do
      chef_run.should_not grant_mysql_database_user('backup')
    end
  
  end
  
end
