require 'spec_helper'

describe 'duplicity-backup::install_duplicity' do
  let (:chef_run) do
    ChefSpec::SoloRunner.new do | node |
      # Set non-standard attributes to check the recipe is using the attributes
      node.set['duplicity']['src_url'] = 'http://code.launchpad.net/duplicity/0.6-series/0.6.22/+download/duplicity-0.6.22.tar.gz'
      node.set['duplicity']['src_dir'] = '/usr/local/othersrc'
    end.converge(described_recipe)
  end
  
  it "installs pip" do
    chef_run.should include_recipe "python::pip"
  end
  
  it "installs the pip lockfile package" do
    chef_run.should install_python_pip "lockfile"
  end

  it "installs ncftp" do
    chef_run.should install_package "ncftp"
  end

  it "installs python-paramiko" do
    chef_run.should install_package "python-paramiko"
  end  
  
  it "installs python-pycryptopp" do
    chef_run.should install_package "python-pycryptopp"
  end

  it "installs lftp" do
    chef_run.should install_package "lftp"
  end
  
  it "installs python-boto" do
    chef_run.should install_package "python-boto"
  end
  
  it "installs python-dev" do
    chef_run.should install_package "python-dev"
  end
  
  it "installs librsync-dev" do
    chef_run.should install_package "librsync-dev"
  end
  
  it "fetches the remote source if missing" do
    chef_run.should create_remote_file_if_missing("/usr/local/othersrc/duplicity-0.6.22.tar.gz").with(
      :source => "http://code.launchpad.net/duplicity/0.6-series/0.6.22/+download/duplicity-0.6.22.tar.gz"
    )
  end
  
  it "sets the source archive owned by root with 0644" do
    chef_run.should create_remote_file_if_missing("/usr/local/othersrc/duplicity-0.6.22.tar.gz").with(
      :owner => "root",
      :group => "root",
      :mode  => 0644
    )
  end
  
  it "does not take backups of the source archive" do
    chef_run.should create_remote_file_if_missing("/usr/local/othersrc/duplicity-0.6.22.tar.gz").with(
      :backup => false
    )    
  end
  
  context "when a new source file is downloaded" do
    it "triggers an immediate unpack and build" do
      resource = chef_run.remote_file("/usr/local/othersrc/duplicity-0.6.22.tar.gz")
      resource.should notify('execute[install-duplicity]').to(:run).immediately
    end
  end
  
  context "when the source is unchanged and the executable is present" do
    before(:each) do
      Kernel.stub(:system).with('which duplicity > /dev/null').and_return(true)
    end

    it "does not attempt to unpack and build the source" do
      chef_run.should_not run_execute('install-duplicity')
    end
  end
  
  context "when the duplicity executable is not present even if the source is unchanged" do
    before(:each) do
      Kernel.stub(:system).with('which duplicity > /dev/null').and_return(false)
    end
    
    it "compiles and installs from source" do
      chef_run.should run_execute('install-duplicity')
    end
    
    it "uses the correct command to unpack and build" do
      chef_run.should run_execute('install-duplicity').with(
        :command => "tar xf duplicity-0.6.22.tar.gz && cd duplicity-0.6.22 && python setup.py install"
      )
    end
    
    it "builds as root" do
      chef_run.should run_execute('install-duplicity').with(
        :user  => "root",
        :group => "root"
      )
    end
    
    it "executes the build command in the source dir" do
      chef_run.should run_execute('install-duplicity').with(
        :cwd  => "/usr/local/othersrc"
      )
    end    
    
  end  
  
end
