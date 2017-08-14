require 'spec_helper'

describe 'duplicity-backup::install_duplicity' do
  let (:chef_runner) do
    ChefSpec::SoloRunner.new do | node |
      # Set non-standard attributes to check the recipe is using the attributes
      node.normal['duplicity']['src_url'] = 'http://code.launchpad.net/duplicity/0.6-series/0.6.22/+download/duplicity-0.6.22.tar.gz'
      node.normal['duplicity']['src_dir'] = '/usr/local/othersrc'
    end
  end

  cached (:chef_run) { chef_runner.converge(described_recipe) }

  it "installs python 2 with pip" do
    expect(chef_run).to install_python_runtime('2.7').with(
      pip_version: true,
      setuptools_version: true
    )
  end

  it "installs the pip lockfile package" do
    expect(chef_run).to install_python_package 'lockfile'
  end

  it "installs the pip fasteners package" do
    expect(chef_run).to install_python_package 'fasteners'
  end

  it "installs ncftp" do
    expect(chef_run).to install_package "ncftp"
  end

  it "installs python-paramiko" do
    expect(chef_run).to install_package "python-paramiko"
  end

  it "installs python-pycryptopp" do
    expect(chef_run).to install_package "python-pycryptopp"
  end

  it "installs lftp" do
    expect(chef_run).to install_package "lftp"
  end

  it "installs python-boto" do
    expect(chef_run).to install_package "python-boto"
  end

  it "installs python-dev" do
    expect(chef_run).to install_package "python-dev"
  end

  it "installs librsync-dev" do
    expect(chef_run).to install_package "librsync-dev"
  end

  it "fetches the remote source if missing" do
    expect(chef_run).to create_remote_file_if_missing("/usr/local/othersrc/duplicity-0.6.22.tar.gz").with(
      :source => "http://code.launchpad.net/duplicity/0.6-series/0.6.22/+download/duplicity-0.6.22.tar.gz"
    )
  end

  it "sets the source archive owned by root with 0644" do
    expect(chef_run).to create_remote_file_if_missing("/usr/local/othersrc/duplicity-0.6.22.tar.gz").with(
      :owner => "root",
      :group => "root",
      :mode  => 0644
    )
  end

  it "does not take backups of the source archive" do
    expect(chef_run).to create_remote_file_if_missing("/usr/local/othersrc/duplicity-0.6.22.tar.gz").with(
      :backup => false
    )
  end

  context "when a new source file is downloaded" do
    it "triggers an immediate unpack and build" do
      resource = chef_run.remote_file("/usr/local/othersrc/duplicity-0.6.22.tar.gz")
      expect(resource).to notify('execute[install-duplicity]').to(:run).immediately
    end
  end

  context "when the source is unchanged and the executable is present" do
    before(:each) do
      allow(Kernel).to receive(:system).with('which duplicity > /dev/null').and_return(true)
    end

    cached (:chef_run) { chef_runner.converge(described_recipe) }

    it "does not attempt to unpack and build the source" do
      expect(chef_runner.converge(described_recipe)).not_to run_execute('install-duplicity')
    end
  end

  context "when the duplicity executable is not present even if the source is unchanged" do
    before(:each) do
      allow(Kernel).to receive(:system).with('which duplicity > /dev/null').and_return(false)
    end

    cached (:chef_run) { chef_runner.converge(described_recipe) }

    it "compiles and installs from source" do
      expect(chef_run).to run_execute('install-duplicity')
    end

    it "uses the correct command to unpack and build" do
      expect(chef_run).to run_execute('install-duplicity').with(
        :command => "tar xf duplicity-0.6.22.tar.gz && cd duplicity-0.6.22 && python setup.py install"
      )
    end

    it "builds as root" do
      expect(chef_run).to run_execute('install-duplicity').with(
        :user  => "root",
        :group => "root"
      )
    end

    it "executes the build command in the source dir" do
      expect(chef_run).to run_execute('install-duplicity').with(
        :cwd  => "/usr/local/othersrc"
      )
    end

  end

end
