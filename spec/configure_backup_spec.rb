require 'spec_helper'

describe 'duplicity-backup::configure_backup' do
  let (:chef_run) do
    ChefSpec::Runner.new do | node |
      # Set non-standard attributes to check the recipe is using the attributes
      node.set['duplicity']['globbing_file_patterns'] = {'/var/www/uploads' => true,'/var/something' => true}
      node.set['duplicity']['backup_mysql']           = false
      node.set['duplicity']['file_destination']       = 's3+http://ourbackup/filebackup'
      node.set['duplicity']['full_if_older_than']     = '10D'
      node.set['duplicity']['keep_n_full']            = 10
      node.set['duplicity']['backup_passphrase']      = 'passphrase'
    end.converge(described_recipe)
  end
  
  it "creates a duplicity config directory" do
    chef_run.should create_directory("/etc/duplicity").with(
      :owner => "root",
      :group => "root",
      :mode  => 0755
    )
  end
  
  it "writes the file list template with globbing patterns on each line" do
    chef_run.node.set['duplicity']['globbing_file_patterns'] = {'/var/www/uploads' => true,'/var/something' => true}
    chef_run.converge(described_recipe)
    chef_run.should render_file('/etc/duplicity/globbing_file_list').with_content(/\/var\/www\/uploads\n\/var\/something/)
  end
  
  it "writes the file list template with restricted permissions" do
    chef_run.should create_template('/etc/duplicity/globbing_file_list').with(
      :owner => "root", 
      :group => "root", 
      :mode => 0644
    )
  end
  
  it "writes the backup script template with restricted permissions" do
    chef_run.should create_template('/etc/duplicity/backup.sh').with(
      :owner => "root", 
      :group => "root", 
      :mode  => 0744
    )  
  end
  
  context "when generating the backup script" do
    context "when backup_mysql is set" do
      let (:chef_run) do
        ChefSpec::Runner.new do | node |
          node.set['duplicity']['backup_mysql']   = true
          node.set['duplicity']['db_destination'] = 's3+http://ourbackup/mysqlbackup'
        end.converge(described_recipe)
      end
      
      it "performs a mysqldump before running the backup" do
        chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/mysqldump/)
      end
      
      context "when mysql.innodb_only is set" do
        let (:chef_run) do
          ChefSpec::Runner.new do | node |
            node.set['duplicity']['backup_mysql'] = true
            node.set['duplicity']['mysql']['innodb_only'] = true
          end.converge(described_recipe)
        end
  
        it "includes the --single-transaction mysqldump flag" do
          chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/mysqldump.+?--single-transaction/m)
        end
      end   
      
      context "when mysql.innodb_only is false" do
        let (:chef_run) do
          ChefSpec::Runner.new do | node |
            node.set['duplicity']['backup_mysql'] = true
            node.set['duplicity']['mysql']['innodb_only'] = false
          end.converge(described_recipe)
        end
  
        it "does not include the --single-transaction mysqldump flag" do
          chef_run.should_not render_file('/etc/duplicity/backup.sh').with_content(/mysqldump.+?--single-transaction/m)
        end
      end
      
      it "includes backing up the mysqldump as a separate backup job" do
        chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/duplicity.+?"s3\+http:\/\/ourbackup\/mysqlbackup"\n/m)
      end
      
    end
    
    context "when backup_mysql is not set" do
      it "does not include any mysql commands" do
        chef_run.should_not render_file('/etc/duplicity/backup.sh').with_content(/mysql/)    
      end
    end
    
    context "when s3-european-buckets is set false" do
      let (:chef_run) do
        ChefSpec::Runner.new do | node |
          # Set non-standard attributes to check the recipe is using the attributes
          node.set['duplicity']['globbing_file_patterns'] = {'/var/www/uploads' => true,'/var/something' => true}
          node.set['duplicity']['backup_mysql']           = false
          node.set['duplicity']['file_destination']       = 's3+http://ourbackup/filebackup'
          node.set['duplicity']['full_if_older_than']     = '10D'
          node.set['duplicity']['keep_n_full']            = 10
          node.set['duplicity']['s3-european-buckets']    = false
        end.converge(described_recipe)
      end
  
      it "does not include the duplicity flag" do
        chef_run.should_not render_file('/etc/duplicity/backup.sh').with_content(/--s3-european-buckets/)    
      end
    end

    context "when s3-european-buckets is set true" do
      let (:chef_run) do
        ChefSpec::Runner.new do | node |
          # Set non-standard attributes to check the recipe is using the attributes
          node.set['duplicity']['globbing_file_patterns'] = {'/var/www/uploads' => true,'/var/something' => true}
          node.set['duplicity']['backup_mysql']           = false
          node.set['duplicity']['file_destination']       = 's3+http://ourbackup/filebackup'
          node.set['duplicity']['full_if_older_than']     = '10D'
          node.set['duplicity']['keep_n_full']            = 10
          node.set['duplicity']['s3-european-buckets']    = true
        end.converge(described_recipe)
      end
  
      it "includes the duplicity flag" do
        chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/--s3-european-buckets/m)    
      end
    end
    
    it "includes the configured full_if_older_than values" do
      chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/--full-if-older-than 10D/m)    
    end
    
    it "includes the configured keep_n_full values" do
      chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/remove-all-but-n-full 10/m)    
    end
  end
  
  context "when generating the environment file" do
    it "ensures the file is only readable by root" do
      chef_run.should create_template('/etc/duplicity/environment.sh').with(
        :owner => "root", 
        :group => "root", 
        :mode  => 0700
      )  
    end
    
    it "includes the backup passphrase" do
      chef_run.should render_file('/etc/duplicity/environment.sh').with_content('PASSPHRASE="passphrase"')
    end
    
    it "includes any other configured env vars" do
      chef_run.node.set['duplicity']['duplicity_environment']['AWS_KEY'] = 'ourkey'
      chef_run.converge(described_recipe).should render_file('/etc/duplicity/environment.sh').with_content('AWS_KEY="ourkey"')
    end
  end
  
  context "when generating the mysql credential file" do  
    let (:chef_run) do
      ChefSpec::Runner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.set['duplicity']['backup_mysql']           = true
        node.set['duplicity']['mysql']['user']          = 'backup'
        node.set['duplicity']['mysql']['password']      = '12345678'
      end.converge(described_recipe)
    end

    it "ensures the file is only readable by root" do
      chef_run.should create_template('/etc/duplicity/mysql.cnf').with(
        :owner => "root", 
        :group => "root", 
        :mode  => 0600
      )  
    end
    
    it "includes the backup username" do
      chef_run.converge(described_recipe).should render_file('/etc/duplicity/mysql.cnf').with_content('user="backup"')
    end
    
    it "includes the backup password" do
      chef_run.converge(described_recipe).should render_file('/etc/duplicity/mysql.cnf').with_content('password="12345678"')
    end
  end

  
end
