require 'spec_helper'

describe 'duplicity-backup::configure_backup' do
  let (:default_required_attributes) do
    {
        'backup_passphrase'  => 'pass',
        'db_destination'     => 's3+http://bucket/dbpath',
        'file_destination'   => 's3+http://bucket/filepath',
        'keep_n_full'        => '5',
        'full_if_older_than' => '7D',
        'mysql'             => {
          'user'     => 'backupuser',
          'password' => 'mysqlpass'
        }
    }
  end
  let (:backup_mysql)        { false }
  let (:innodb_only)         { true }
  let (:s3_european_buckets) { true }

  context "when required attributes are set" do
    let (:chef_run) do
      ChefSpec::Runner.new do | node |
        custom_attributes = default_required_attributes
        # Set non-standard attributes to check the recipe is using the attributes
        custom_attributes['globbing_file_patterns'] = {'/var/www/uploads' => true,'/var/something' => true}
        custom_attributes['backup_mysql']           = backup_mysql
        custom_attributes['file_destination']       = 's3+http://ourbackup/filebackup'
        custom_attributes['full_if_older_than']     = '10D'
        custom_attributes['keep_n_full']            = 10
        custom_attributes['backup_passphrase']      = 'passphrase'
        custom_attributes['s3-european-buckets']    = s3_european_buckets
        custom_attributes['mysql']['innodb_only']   = innodb_only
        set_node_duplicity_attributes(node, custom_attributes)
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
        let (:backup_mysql) { true }

        it "performs a mysqldump before running the backup" do
          chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/mysqldump/)
        end

        it "includes backing up the mysqldump as a separate backup job" do
          chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/duplicity.+?"s3\+http:\/\/bucket\/dbpath"\n/m)
        end

        context "when mysql.innodb_only is set" do
          let (:innodb_only) { true }

          it "includes the --single-transaction mysqldump flag" do
            chef_run.should render_file('/etc/duplicity/backup.sh').with_content(/mysqldump.+?--single-transaction/m)
          end
        end

        context "when mysql.innodb_only is false" do
          let (:innodb_only) { false }

          it "does not include the --single-transaction mysqldump flag" do
            chef_run.should_not render_file('/etc/duplicity/backup.sh').with_content(/mysqldump.+?--single-transaction/m)
          end
        end

      end

      context "when backup_mysql is not set" do
        it "does not include any mysql commands" do
          chef_run.should_not render_file('/etc/duplicity/backup.sh').with_content(/mysql/)
        end
      end

      context "when s3-european-buckets is set false" do
        let (:s3_european_buckets) { false }

        it "does not include the duplicity flag" do
          chef_run.should_not render_file('/etc/duplicity/backup.sh').with_content(/--s3-european-buckets/)
        end
      end

      context "when s3-european-buckets is set true" do
        let (:s3_european_buckets) { true }

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

      it "ensures the file is only readable by root" do
        chef_run.should create_template('/etc/duplicity/mysql.cnf').with(
          :owner => "root",
          :group => "root",
          :mode  => 0600
        )
      end

      it "includes the backup username" do
        chef_run.converge(described_recipe).should render_file('/etc/duplicity/mysql.cnf').with_content('user="backupuser"')
      end

      it "includes the backup password" do
        chef_run.converge(described_recipe).should render_file('/etc/duplicity/mysql.cnf').with_content('password="mysqlpass"')
      end
    end
  end

  context "when some required attributes have not been set" do
    let (:backup_mysql) { false }

    it "fails without a backup_passphrase" do
      expect_argument_error_without('backup_passphrase')
    end

    it "fails without a file_destination" do
      expect_argument_error_without('file_destination')
    end

    it "fails without a full_if_older_than attribute" do
      expect_argument_error_without('full_if_older_than')
    end

    it "fails without a keep_n_full attribute" do
      expect_argument_error_without('keep_n_full')
    end

    context "when mysql backup is enabled" do
      let (:backup_mysql) { true }

      it "fails without a db_destination" do
        expect_argument_error_without('db_destination')
      end

      it "fails without a mysql.user" do
        expect_argument_error_without('mysql.user')
      end

      it "fails without a mysql.password" do
        expect_argument_error_without('mysql.password')
      end

    end

    context "when mysql backup is disabled" do
      let (:backup_mysql) { false }

      it "does not require a db_destination" do
        expect_no_argument_error_without('db_destination')
      end

      it "does not require a mysql.user" do
        expect_no_argument_error_without('mysql.user')
      end

      it "does not require a mysql.password" do
        expect_no_argument_error_without('mysql.password')
      end
    end

  end

  def converge_without_attribute(attribute)
    ChefSpec::Runner.new do | node |
      set_node_duplicity_attributes_without(node, default_required_attributes, attribute)
      node.set['duplicity']['backup_mysql'] = backup_mysql
    end.converge(described_recipe)
  end

  def expect_argument_error_without(attribute)
    expect { converge_without_attribute(attribute) }.to raise_error(ArgumentError)
  end

  def expect_no_argument_error_without(attribute)
    expect { converge_without_attribute(attribute) }.not_to raise_error()
  end

  def set_node_duplicity_attributes(node, attr_hash)
    attr_hash.each do | attribute, value |
      node.set['duplicity'][attribute] = value
    end
  end

  def set_node_duplicity_attributes_without(node, attr_hash, key)
    attrs = attr_hash.clone
    if key.include?('.') then
      keys = key.split('.')
      attrs[keys[0]].delete(keys[1])
    else
      attrs.delete(key)
    end
    set_node_duplicity_attributes(node, attrs)
  end

end
