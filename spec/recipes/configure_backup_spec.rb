require 'spec_helper'
require_relative '../../libraries/attribute_helper.rb'

describe 'duplicity-backup::configure_backup' do
  let(:chef_runner)         { ChefSpec::SoloRunner.new }
  let(:backup_mysql)        { false }
  let(:backup_postgresql)   { false }

  before(:each) do
    chef_runner.node.normal['duplicity']['backup_passphrase'] = 'passphrase'
    chef_runner.node.normal['duplicity']['file_destination']  = 's3+http://ourbackup/filebackup'
    chef_runner.node.normal['duplicity']['keep_n_full']        = '10'
    chef_runner.node.normal['duplicity']['full_if_older_than'] = '10D'
    chef_runner.node.normal['duplicity']['globbing_file_patterns'] = {
      '/var/www/uploads' => true,
      '/var/something' => true
    }
  end

  cached(:chef_run) { chef_runner.converge(described_recipe) }

  it 'creates a duplicity config directory' do
    expect(chef_run).to create_directory('/etc/duplicity').with(
      owner: 'root',
      group: 'root',
      mode: 0o755
    )
  end

  it 'creates a private duplicity archive directory' do
    expect(chef_run).to create_directory('/var/duplicity/archive').with(
      owner: 'root',
      group: 'root',
      recursive: true,
      mode: 0o700
    )
  end

  describe 'creates a backup file list' do
    it 'writes the filelist with restricted permissions' do
      expect(chef_run).to create_template('/etc/duplicity/globbing_file_list').with(
        owner: 'root',
        group: 'root',
        mode: 0o644
      )
    end

    it 'renders active globbing patterns on each line' do
      expect(chef_run).to render_file('/etc/duplicity/globbing_file_list')
        .with_content("/var/www/uploads\n/var/something")
    end

    it 'does not include inactive globbing patterns' do
      chef_runner.node.normal['duplicity']['globbing_file_patterns'] = {
        '/var/www/uploads' => true,
        '/var/something' => false
      }
      expect(converge).to_not render_file('/etc/duplicity/globbing_file_list')
        .with_content(/\/var\/something/)
    end

    # Refs https://bugs.launchpad.net/duplicity/+bug/1586032 and
    # https://bugs.launchpad.net/duplicity/+bug/1479545
    # This behaviour is confusing so disable it
    it 'throws if any globbing pattern uses a trailing /' do
      chef_runner.node.normal['duplicity']['globbing_file_patterns'] = {
        '/var/www/uploads' => true,
        '/var/something/' => true
      }
      expect { converge }.to raise_error(ArgumentError, /trailing slash/)
    end
  end

  describe 'creates a backup script' do
    it 'writes the backup script with restricted permissions' do
      expect(chef_run).to create_template('/etc/duplicity/backup.sh').with(
        owner: 'root',
        group: 'root',
        mode: 0o744
      )
    end

    it 'generates commands OK with the real helper' do
      expect(chef_run).to render_file('/etc/duplicity/backup.sh')
        .with_content("/usr/local/bin/duplicity \\\n  --full-if-older-than")
    end

    context 'with stubbed command builder' do
      before(:each) do
        stub_command_builder
      end

      cached(:chef_run) { chef_runner.converge(described_recipe) }

      it 'includes the file backup command' do
        expect(chef_run).to render_file('/etc/duplicity/backup.sh')
          .with_content(/^STUBCMD-duplicity_backup_filelist$/m)
      end

      it 'cleans old full file backups' do
        expect(chef_run).to render_file('/etc/duplicity/backup.sh')
          .with_content(/^STUBCMD-duplicity_remove_all_but_n_full file_backup$/m)
      end

      it 'does not include any db backup commands by default' do
        expect(chef_run).to_not render_file('/etc/duplicity/backup.sh')
          .with_content(/mysql/i)
        expect(chef_run).to_not render_file('/etc/duplicity/backup.sh')
          .with_content(/postgresql/i)
      end

      it 'does not export a working directory by default' do
        expect(chef_run).to_not render_file('/etc/duplicity/backup.sh')
          .with_content(/export_dump_dir/i)
      end

      context 'when mysql_backup is enabled' do
        before(:each) do
          chef_runner.node.normal['duplicity']['backup_mysql'] = true
          chef_runner.node.normal['duplicity']['mysql']['password'] = '12345678'
          chef_runner.node.normal['duplicity']['db_destination'] = 's3://my.bucket'
        end

        cached(:chef_run) { chef_runner.converge(described_recipe) }

        it 'exports the working directory path' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\STUBCMD-export_dump_dir MYSQL_DUMP_DIR mysql_backup$/m)
        end

        it 'includes a prepare working directory command before the backup' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\STUBCMD-prepare_dump_dir \$MYSQL_DUMP_DIR$/m)
        end

        it 'includes a clean working directory command after the backup' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\STUBCMD-remove_dump_dir \$MYSQL_DUMP_DIR$/m)
        end

        it 'includes a mysqldump command in the backup script' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\s*STUBCMD-mysqldump \$db \$MYSQL_DUMP_DIR\/mysql-\$db.sql.gz$/m)
        end

        it 'backs up the mysqldump directory' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\s*STUBCMD-duplicity_backup_dir \$MYSQL_DUMP_DIR mysql_backup$/m)
        end

        it 'cleans old full mysql backups' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\s*STUBCMD-duplicity_remove_all_but_n_full mysql_backup$/m)
        end
      end

      context 'when backup_postgresql is enabled' do
        before(:each) do
          chef_runner.node.normal['duplicity']['backup_postgresql'] = true
          chef_runner.node.normal['duplicity']['postgresql']['user'] = 'backup'
          chef_runner.node.normal['duplicity']['postgresql']['password'] = '12345678'
          chef_runner.node.normal['duplicity']['pg_destination'] = 's3://my.bucket'
        end

        cached(:chef_run) { chef_runner.converge(described_recipe) }

        it 'exports the working directory path' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\STUBCMD-export_dump_dir PG_DUMP_DIR pg_backup$/m)
        end

        it 'includes a prepare working directory command before the backup' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\STUBCMD-prepare_dump_dir \$PG_DUMP_DIR$/m)
        end

        it 'includes a pg_dumpall command in the backup script' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\s*STUBCMD-pg_dumpall \$PG_DUMP_DIR\/pgdump.sql.gz$/m)
        end

        it 'backs up the postgresql directory' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\s*STUBCMD-duplicity_backup_dir \$PG_DUMP_DIR pg_backup$/m)
        end

        it 'includes a clean working directory command after the backup' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\s*STUBCMD-remove_dump_dir \$PG_DUMP_DIR$/m)
        end

        it 'cleans old full postgresql backups' do
          expect(chef_run).to render_file('/etc/duplicity/backup.sh')
            .with_content(/^\s*STUBCMD-duplicity_remove_all_but_n_full pg_backup$/m)
        end
      end
    end
  end

  describe 'creates an environment file' do
    it 'only allows root to read the environment file' do
      expect(chef_run).to create_template('/etc/duplicity/environment.sh').with(
        owner: 'root',
        group: 'root',
        mode: 0o700
      )
    end

    it 'includes the backup passphrase' do
      expect(chef_run).to render_file('/etc/duplicity/environment.sh')
        .with_content('PASSPHRASE="passphrase"')
    end

    it 'throws if no passphrase is provided' do
      chef_runner.node.rm('duplicity', 'backup_passphrase')
      expect { converge }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.backup_passphrase/)
    end

    it 'includes any other configured env vars' do
      chef_runner.node.normal['duplicity']['duplicity_environment']['AWS_KEY'] = 'ourkey'
      expect(converge).to render_file('/etc/duplicity/environment.sh')
        .with_content('AWS_KEY="ourkey"')
    end
  end

  context 'when mysql backup is enabled' do
    before(:each) do
      chef_runner.node.normal['duplicity']['backup_mysql']      = true
      chef_runner.node.normal['duplicity']['mysql']['user']     = 'backupuser'
      chef_runner.node.normal['duplicity']['mysql']['password'] = 'mysqlpass'
    end

    cached(:chef_run) { chef_runner.converge(described_recipe) }

    describe 'generates a mysql credential file' do
      it 'creates credential file only readable by root' do
        expect(chef_run).to create_template('/etc/duplicity/mysql.cnf').with(
          owner: 'root',
          group: 'root',
          mode: 0o600
        )
      end

      it 'includes the backup username in the mysql credential file' do
        expect(chef_run).to render_file('/etc/duplicity/mysql.cnf').with_content('user="backupuser"')
      end

      it 'includes the backup user password in the mysql credential file' do
        expect(chef_run).to render_file('/etc/duplicity/mysql.cnf').with_content('password="mysqlpass"')
      end

      it 'throws if no mysql password is provided' do
        chef_runner.node.rm('duplicity', 'mysql', 'password')
        expect { converge }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /duplicity.mysql.password/)
      end
    end
  end

  context 'when postgres backup is enabled' do
    before(:each) do
      chef_runner.node.normal['duplicity']['backup_postgresql']      = true
      chef_runner.node.normal['duplicity']['postgresql']['user']     = 'backuppg'
      chef_runner.node.normal['duplicity']['postgresql']['password'] = 'pgpass'
    end

    cached(:chef_run) { chef_runner.converge(described_recipe) }

    it 'generates pgpass file only readably by root' do
      expect(chef_run).to create_template('/etc/duplicity/.pgpass').with(
        owner: 'root',
        group: 'root',
        mode: 0o600
      )
    end

    it 'includes the configured postgres user and password' do
      expect(chef_run).to render_file('/etc/duplicity/.pgpass')
        .with_content(/backuppg:pgpass\z/)
    end

    it 'throws if no postgres password is provided' do
      chef_runner.node.rm('duplicity', 'postgresql', 'password')
      expect { converge }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /duplicity.postgresql.password/)
    end
  end

  def converge
    chef_runner.converge(described_recipe)
  end

  def stub_command_builder
    all_methods = Ingenerator::DuplicityBackup::CommandBuilder.instance_methods(false)
    all_methods.each do |method|
      allow_any_instance_of(Ingenerator::DuplicityBackup::CommandBuilder)
        .to receive(method) { |_inst, *args| args.unshift("STUBCMD-#{method}").join(' ') }
    end
  end
end
