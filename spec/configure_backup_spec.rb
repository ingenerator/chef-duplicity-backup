require 'spec_helper'

describe 'duplicity-backup::configure_backup' do
  let (:chef_run) do
    ChefSpec::Runner.new do | node |
      # Set non-standard attributes to check the recipe is using the attributes
      node.set['duplicity']['globbing_file_patterns'] = {'/var/www/uploads' => true,'/var/something' => true}
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
  
  context "when backup_mysql is set" do
    let (:chef_run) do
      ChefSpec::Runner.new do | node |
        node.set['duplicity']['backup_mysql']   = true
#        node.set['duplicity']['db_destination'] = 's3+http://ourbackup/mysqlbackup'
      end.converge(described_recipe)
    end
    
    it "generates the backup script to perform a mysqldump before running the backup" do
      chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/mysqldump/)
    end
    
    context "when mysql.innodb_only is set" do
      let (:chef_run) do
        ChefSpec::Runner.new do | node |
          node.set['duplicity']['backup_mysql'] = true
          node.set['duplicity']['mysql']['innodb_only'] = true
        end.converge(described_recipe)
      end

      it "generates the backup script with the --single-transaction mysqldump flag" do
        chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/mysqldump[^\n]+--single-transaction/)
      end
    end   
    
    context "when mysql.innodb_only is false" do
      let (:chef_run) do
        ChefSpec::Runner.new do | node |
          node.set['duplicity']['backup_mysql'] = true
          node.set['duplicity']['mysql']['innodb_only'] = false
        end.converge(described_recipe)
      end

      it "generates the backup script without the --single-transaction mysqldump flag" do
        chef_run.should_not render_file('/etc/duplicity/backup.sh').with_content(/mysqldump[^\n]+--single-transaction/)
      end
    end
    
    it "generates the backup script to backup the mysqldump as a separate backup job" do
      chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/duplicity[^\n]+"s3\+http:\/\/ourbackup\/mysqlbackup"$/)
    end
    
  end
  
  context "when backup_mysql is not set" do
  
  end
  
end
