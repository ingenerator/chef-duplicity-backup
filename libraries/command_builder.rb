# Helper to robustly build the various shell commands required to run the backup
# This isn't my favourite work, but it works in the context of the existing cookbook
module Ingenerator
  module DuplicityBackup
    ##
    # Thrown if attempting to generate commands for a backup that isn't enabled.
    # This is generally a cookbook-level logic error.
    #
    class BackupNotEnabledError < RuntimeError
      def initialize(attr_path)
        super "Attempted to build commands for a backup that is not enabled (set node.#{attr_path} = true)"
      end
    end

    ##
    # Thrown if attempting to generate commands for an undefined backup job name
    # Currently the available jobs are hardcoded in the cookbook, so this is an
    # internal logic error, or an attempt to use the library in an unsupported
    # way.
    class UnknownBackupError < ArgumentError
      def initialize(backup_name)
        super "Backup job #{backup_name} is not defined in this cookbook"
      end
    end

    ##
    # Builds executable commands, with their arguments, for the various stages
    # of the backup.
    class CommandBuilder
      def initialize(node)
        @node = node
      end

      ##
      # Generate command to export a working directory path to a shell variable
      #
      # @param [String] the name of the variable that should be assigned
      # @param [String] the backup name to create the working directory for
      # @return [String]
      #
      def export_dump_dir(assign_varname, backup_name)
        basedir = require_attribute! 'duplicity.dump_base_dir'
        dirname = File.join(basedir, backup_name)
        unless valid_dir? dirname
          raise ArgumentError, "`#{dirname}` is not a valid dump working directory, check your duplicity.dump_base_dir attribute"
        end

        assign_varname+'="'+dirname+'"'
      end

      ##
      # Generate command to ensure the working directory exists and is private
      # - removes and recreates if required
      #
      # @param [String] the bash variable name holding the working directory
      # @return [String]
      #
      def prepare_dump_dir(varname)
        raise ArgumentError, "`#{varname}` not a variable name" unless /\A\$[A-Z_]+\z/ =~ varname
        [
          'rm -rf "'+varname+'"',
          '&&',
          'mkdir -p "'+varname+'"',
          '&&',
          'chmod 0700 "'+varname+'"'
        ].join(' ')
      end

      def remove_dump_dir(varname)
        raise ArgumentError, "`#{varname}` not a variable name" unless /\A\$[A-Z_]+\z/ =~ varname
        'rm -rf "'+varname+'"'
      end

      ##
      # Generate command to mysqldump a single schema to a dump file
      #
      # @param [String] the shell variable pointing to the schema to backup
      # @param [String] the shell variable pointing to the output dump file
      # @return [String]
      #
      def mysqldump(db_var, output_path_var)
        raise BackupNotEnabledError, 'duplicity.backup_mysql' unless @node['duplicity']['backup_mysql']

        format_command(
          [
            'mysqldump --defaults-file=/etc/duplicity/mysql.cnf',
            '$SCHEMA_BACKUP_FLAGS',
            '-h localhost',
            @node['duplicity']['mysql']['innodb_only'] ? '--single-transaction' : '',
            '"' + db_var + '" | gzip -9 > "' + output_path_var + '"'
          ]
        )
      end

      ##
      # Generate command to dump a full postgresql database to an output file
      #
      # @param [String] the shell variable pointing to the output file
      # @return [String]
      #
      def pg_dumpall(output_path_var)
        raise BackupNotEnabledError, 'duplicity.backup_postgresql' unless @node['duplicity']['backup_postgresql']
        user = require_attribute! 'duplicity.postgresql.user'
        host = require_attribute! 'duplicity.postgresql.host'

        format_command(
          [
            'PGPASSFILE="/etc/duplicity/.pgpass" pg_dumpall',
            "-h#{host}",
            "-U#{user}",
            '| gzip -9 > "' + output_path_var + '"'
          ]
        )
      end

      ##
      # Generate command to backup an entire directory as a remote backup
      # - used primarily for database dumps
      #
      # @param [String] shell variable pointing to the source directory
      # @param [String] name of the backup job, internally mapped to a destination
      # @return [String]
      #
      def duplicity_backup_dir(from_dir, backup_name)
        duplicity_backup_cmd(
          from_dir,
          backup_name,
          []
        )
      end

      ##
      # Generate command to backup a partial filelist, all relative to the /,
      # as the file_backup job (to the file_destination)
      #
      # @return [String]
      #
      def duplicity_backup_filelist
        duplicity_backup_cmd(
          '/',
          'file_backup',
          [
            '--include-filelist /etc/duplicity/globbing_file_list',
            '--exclude \'**\''
          ]
        )
      end

      ##
      # Generate command to cleanup old full backups for any known job
      #
      # @param [String] name of the backup job, internally mapped to a destination
      # @return [String]
      #
      def duplicity_remove_all_but_n_full(backup_name)
        keep_n_full = require_attribute!('duplicity.keep_n_full').to_s
        parts = [
          "/usr/local/bin/duplicity remove-all-but-n-full #{keep_n_full}",
          '--force',
          "--name #{backup_name}"
        ]
        parts.concat(duplicity_common_options)
        parts.push('"' + job_destination(backup_name) + '"')
        format_command(parts)
      end

      private

      ##
      # Format a command from parts to a multi-line indented command and arguments
      #
      # @param [Array<String>] individual lines of the command
      # @return [String]
      #
      def format_command(parts)
        parts.reject(&:empty?).join(" \\\n  ")
      end

      ##
      # Get the configured destination of a known job, or throw
      #
      # @param [String] backup job name
      # @return [String] S3 bucket job destination
      #
      def job_destination(backup_name)
        attr_name = {
          'mysql_backup' => 'duplicity.db_destination',
          'pg_backup'    => 'duplicity.pg_destination',
          'file_backup'  => 'duplicity.file_destination'
        }[backup_name]

        raise UnknownBackupError, backup_name unless attr_name
        require_attribute! attr_name
      end

      ##
      # Get the value of an attribute from .-separated path, throw if missing
      #
      # @param [String] dot-separated path to node attribute required
      # @return [String]
      #
      def require_attribute!(attribute_path)
        Ingenerator::DuplicityBackup.require_attribute! @node, attribute_path
      end

      ##
      # Build a generic duplicity backup command with extra parts provided
      #
      # @param [String] base directory to backup from
      # @param [String] internal backup job name to map to destination
      # @param [Array<String>] extra arguments / options
      # @return [String]
      #
      def duplicity_backup_cmd(source_path, backup_name, extra_options)
        full_if_older_than = require_attribute!('duplicity.full_if_older_than')
        parts = [
          '/usr/local/bin/duplicity',
          "--full-if-older-than #{full_if_older_than}",
          "--name #{backup_name}"
        ]
        parts.concat(duplicity_common_options)
        parts.concat(extra_options)
        parts.push('"' + source_path + '"')
        parts.push('"' + job_destination(backup_name) + '"')
        format_command(parts)
      end

      ##
      # The options relevant to all duplicity commands
      #
      # @return [String]
      #
      def duplicity_common_options
        options = [
          '--archive-dir="'+require_attribute!('duplicity.archive_dir')+'"',
          '--s3-use-new-style'
        ]
        if @node['duplicity']['s3-european-buckets']
          options << '--s3-european-buckets'
        end
        options
      end

      ##
      # Is this a valid path?
      #
      # Must be alphanumeric/-_ and be off the root, not relative
      #
      # @return [String]
      def valid_dir?(path)
        /\A\/[a-zA-Z0-9z\/\-\_]+\z/ =~ path
      end

    end unless defined?(Ingenerator::DuplicityBackup::CommandBuilder)
    # The conditional declaration is required so that chef doesn't overwrite the
    # class during converge if we've already stubbed it from chefspec
  end
end
