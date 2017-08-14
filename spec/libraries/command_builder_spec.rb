require 'spec_helper'
require_relative '../../libraries/command_builder.rb'

describe Ingenerator::DuplicityBackup::CommandBuilder do
  let(:node)     { Chef::Node.new }
  let(:subject)  { Ingenerator::DuplicityBackup::CommandBuilder.new(node) }
  let(:commands) { Ingenerator::DuplicityBackup::CommandBuilder.new(node) }

  before(:each) do
    node.normal['duplicity']['archive_dir'] = '/var/dup/arch'
    node.normal['duplicity']['mysql']       = {}
  end

  shared_examples 'duplicity command with common options' do
    it 'uses new-style s3 buckets' do
      expect_valid_command(subject).to include ' --s3-use-new-style '
    end

    it 'does not use s3-european-buckets if not in node attributes' do
      node.normal['duplicity']['s3-european-buckets'] = false
      expect_valid_command(subject).not_to include '--s3-european-buckets'
    end

    it 'uses s3-european-buckets if configured in node attributes' do
      node.normal['duplicity']['s3-european-buckets'] = true
      expect_valid_command(subject).to include ' --s3-european-buckets '
    end

    it 'specifies the archive-dir' do
      node.normal['duplicity']['archive_dir'] = '/var/duplicity/archives'
      expect_valid_command(subject).to include ' --archive-dir="/var/duplicity/archives" '
    end

    it 'throws if the archive directory is not configured' do
      node.rm('duplicity', 'archive_dir')
      expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.archive_dir/)
    end

  end

  shared_examples 'basic duplicity backup command' do |expect_source|
    context 'with invalid configuration' do
      it 'fails if there is no destination for the backup name' do
        node.rm('duplicity', dest_attr)
        expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.\w+_destination/)
      end

      it 'fails if full_if_older_than not specified' do
        node.rm('duplicity', 'full_if_older_than')
        expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.full_if_older_than/)
      end
    end

    context 'with valid config' do
      it 'produces a duplicity backup command' do
        expect_valid_command(subject).to start_with '/usr/local/bin/duplicity'
      end

      it 'specifies the expected full_if_older_than value' do
        node.normal['duplicity']['full_if_older_than'] = '15D'
        expect_valid_command(subject).to include ' --full-if-older-than 15D '
      end

      it_behaves_like 'duplicity command with common options'

      it 'specifies the backup name' do
        expect_valid_command(subject).to include " --name #{backup_name} "
      end

      it 'specifies the expected backup source directory' do
        expect_valid_command(subject).to include ' "' + expect_source + '" \\'
      end

      it 'specifies the expected backup destination' do
        node.normal['duplicity'][dest_attr] = 's3://some.bucket/path'
        expect_valid_command(subject).to end_with ' "s3://some.bucket/path"'
      end
    end
  end

  shared_examples 'remove_all_but_n_full for known backup' do
    context 'with invalid configuration' do
      it 'fails if there is no destination for the backup name' do
        node.rm('duplicity', dest_attr)
        expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.\w+_destination/)
      end

      it 'fails if keep_n_full is not configured' do
        node.rm('duplicity', 'keep_n_full')
        expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.keep_n_full/)
      end
    end

    context 'with minimum valid configuration' do
      before(:each) do
        node.normal['duplicity']['keep_n_full'] = 5
        node.normal['duplicity'][dest_attr] = 's3://my.bucket/path'
      end

      it 'produces a duplicity remove-all-but-n-full command with expected number' do
        expect_valid_command(subject).to start_with '/usr/local/bin/duplicity remove-all-but-n-full 5 '
      end

      it 'forces the removal' do
        expect_valid_command(subject).to include ' --force '
      end

      it 'specifies the backup name' do
        expect_valid_command(subject).to include " --name #{backup_name} "
      end

      it 'specifies the expected db backup destination' do
        node.normal['duplicity'][dest_attr] = 's3://some.bucket/path'
        expect_valid_command(subject).to end_with ' "s3://some.bucket/path"'
      end

      it_behaves_like 'duplicity command with common options'
    end
  end

  shared_examples 'backup_dir for known backup' do
    before(:each) do
      node.normal['duplicity']['full_if_older_than'] = '3D'
      node.normal['duplicity'][dest_attr] = 's3://a.bucket'
    end

    it_behaves_like 'basic duplicity backup command', '$anywhere'

    it 'does not allow source mismatch' do
      expect_valid_command(subject).not_to include ' --allow-source-mismatch '
    end
  end

  describe '#duplicity_backup_dir' do
    let(:from_dir) { '$anywhere' }
    let(:subject)  { commands.duplicity_backup_dir(from_dir, backup_name) }

    before(:each) do
      node.normal['duplicity']['full_if_older_than'] = '5D'
    end

    context 'with unknown backup name' do
      let(:backup_name) { 'unspecified' }

      it 'throws an exception' do
        expect { subject }.to raise_error Ingenerator::DuplicityBackup::UnknownBackupError
      end
    end

    context 'for mysql_backup' do
      let(:backup_name) { 'mysql_backup' }
      let(:dest_attr)   { 'db_destination' }

      it_behaves_like 'backup_dir for known backup'
    end

    context 'for pg_backup' do
      let(:backup_name) { 'pg_backup' }
      let(:dest_attr)   { 'pg_destination' }

      it_behaves_like 'backup_dir for known backup'
    end
  end

  describe '#duplicity_backup_filelist' do
    let(:subject)     { commands.duplicity_backup_filelist }
    let(:backup_name) { 'file_backup' }
    let(:dest_attr)   { 'file_destination' }

    before(:each) do
      node.normal['duplicity']['full_if_older_than'] = '3D'
      node.normal['duplicity'][dest_attr] = 's3://a.bucket'
    end

    it 'does not allow source mismatch' do
      expect_valid_command(subject).not_to include ' --allow-source-mismatch '
    end

    it 'includes the reference to the globbing file list' do
      expect_valid_command(subject).to include ' --include-filelist /etc/duplicity/globbing_file_list '
    end

    it 'excludes all files by default' do
      expect_valid_command(subject).to include " --exclude '**' "
    end

    it_behaves_like 'basic duplicity backup command', '/'
  end

  describe '#duplicity_remove_all_but_n_full' do
    let(:subject) { commands.duplicity_remove_all_but_n_full(backup_name) }

    before(:each) do
      node.normal['duplicity']['keep_n_full'] = '5D'
    end

    context 'with unknown backup name' do
      let(:backup_name) { 'foobar' }

      it 'throws an exception' do
        expect { subject }.to raise_error Ingenerator::DuplicityBackup::UnknownBackupError
      end
    end

    context 'for mysql_backup' do
      let(:backup_name) { 'mysql_backup' }
      let(:dest_attr)   { 'db_destination' }

      it_behaves_like 'remove_all_but_n_full for known backup'
    end

    context 'for pg_backup' do
      let(:backup_name) { 'pg_backup' }
      let(:dest_attr)   { 'pg_destination' }

      it_behaves_like 'remove_all_but_n_full for known backup'
    end

    context 'for file_backup' do
      let(:backup_name) { 'file_backup' }
      let(:dest_attr)   { 'file_destination' }

      it_behaves_like 'remove_all_but_n_full for known backup'
    end
  end

  describe '#export_dump_dir' do
    let(:varname) { 'WORKDIR' }
    let(:backup_name) { 'mysql_backup' }
    let(:subject) { commands.export_dump_dir(varname, backup_name) }

    context 'with invalid configuration' do
      it 'fails if dump source directory is not configured' do
        expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.dump_base_dir/)
      end

      ['relative', 'white space', 'end-whitespace '].each do |invalid|
        it "fails if dump source directory is not valid eg `#{invalid}`" do
          node.normal['duplicity']['dump_base_dir'] = invalid
          expect { subject }.to raise_error ArgumentError, /not a valid dump/
        end
      end
    end

    context 'with valid configuration' do
      it 'provides a path for the job name in the sources directory' do
        node.normal['duplicity']['dump_base_dir'] = '/var/duplicity/sources'
        expect(subject).to eq('WORKDIR="/var/duplicity/sources/mysql_backup"')
      end
    end
  end

  describe '#prepare_dump_dir' do
    let(:varname)     { '$WORKDIR' }
    let(:subject)     { commands.prepare_dump_dir(varname) }

    it 'throws with invalid varname' do
      expect { commands.prepare_dump_dir('NO_STRING') }.to raise_error ArgumentError, /not a variable name/
    end

    it 'force-removes an existing directory, recursively recreates and makes private' do
      expect_valid_command(subject).to eq 'rm -rf "$WORKDIR" && mkdir -p "$WORKDIR" && chmod 0700 "$WORKDIR"'
    end
  end

  describe '#remove_dump_dir' do
    let(:varname)     { '$WORKDIR' }
    let(:subject)     { commands.remove_dump_dir(varname) }

    it 'throws with invalid varname' do
      expect { commands.remove_dump_dir('NO_STRING') }.to raise_error ArgumentError, /not a variable name/
    end

    it 'force-removes the directory' do
      expect_valid_command(subject).to eq 'rm -rf "$WORKDIR"'
    end
  end

  describe '#mysqldump' do
    let(:db_var)     { '$dbname' }
    let(:output_var) { '$DIR/mysql-$db.sql.gz' }
    let(:subject)    { commands.mysqldump(db_var, output_var) }

    context 'with invalid configuration' do
      it 'fails if mysql backup is not enabled' do
        node.normal['duplicity']['backup_mysql'] = false
        expect { subject }.to raise_error Ingenerator::DuplicityBackup::BackupNotEnabledError
      end
    end

    context 'with minimum valid attributes' do
      before(:each) do
        node.normal['duplicity']['backup_mysql'] = true
      end

      it 'produces a mysqldump command with the expected defaults file' do
        expect_valid_command(subject).to start_with 'mysqldump --defaults-file=/etc/duplicity/mysql.cnf '
      end

      it 'dumps the specified database, gzips and sends to output path' do
        expect_valid_command(subject).to end_with '  "$dbname" | gzip -9 > "$DIR/mysql-$db.sql.gz"'
      end

      it 'does not include the single transaction flag if innodb_only is cleared' do
        expect_valid_command(subject).not_to include '--single-transaction'
      end

      context 'with additional configuration' do
        it 'backs up in a single transaction if innodb_only set' do
          node.default['duplicity']['mysql']['innodb_only'] = true
          expect_valid_command(subject).to include '  --single-transaction '
        end
      end
    end
  end

  describe '#pg_dumpall' do
    let(:output_var) { '$SOMEDIR/pgd.sql.gz' }
    let(:subject)    { commands.pg_dumpall(output_var) }

    before(:each) do
      node.normal['duplicity']['backup_postgresql']  = true
      node.normal['duplicity']['postgresql']['user'] = 'fred'
      node.normal['duplicity']['postgresql']['host'] = 'localhost'
    end

    context 'with invalid configuration' do
      it 'fails if postgresql backup is not enabled' do
        node.normal['duplicity']['backup_postgresql'] = false
        expect { subject }.to raise_error Ingenerator::DuplicityBackup::BackupNotEnabledError
      end

      it 'fails if no host is specified' do
        node.rm('duplicity', 'postgresql', 'host')
        expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.postgresql.host/)
      end

      it 'fails if no user is specified' do
        node.rm('duplicity', 'postgresql', 'user')
        expect { subject }.to raise_error(Ingenerator::DuplicityBackup::IncompleteConfigError, /node.duplicity.postgresql.user/)
      end
    end

    context 'with minimum valid attributes' do
      it 'produces a pgdumpall command with the expected PGPASSFILE' do
        expect_valid_command(subject).to start_with 'PGPASSFILE="/etc/duplicity/.pgpass" pg_dumpall '
      end

      it 'specifies the expected host' do
        node.normal['duplicity']['postgresql']['host'] = '134.142.232.242'
        expect_valid_command(subject).to include ' -h134.142.232.242 '
      end

      it 'specifies the expected user' do
        node.normal['duplicity']['postgresql']['user'] = 'billy'
        expect_valid_command(subject).to include ' -Ubilly '
      end

      it 'dumps all databases, gzips and sends to output path' do
        expect_valid_command(subject).to end_with ' | gzip -9 > "$SOMEDIR/pgd.sql.gz"'
      end
    end
  end

  def expect_valid_command(command)
    raise "Trailing newline escape in `#{command}`" if /\\\s*\z/ =~ command
    raise "Unescaped newline in `#{command}`" if /(?<! \\)\n/ =~ command
    raise "Invalid empty lines in `#{command}`" if /^\s+\\?$/m =~ command
    raise "Unindented continuation line in `#{command}`" if /\n(?!  )/ =~ command

    expect(command)
  end
end
