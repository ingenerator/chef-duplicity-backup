require 'spec_helper'

describe 'duplicity-backup::install_lockrun' do
  cached (:chef_run) do
    ChefSpec::SoloRunner.new do | node |
      # Set non-standard attributes to check the recipe is using the attributes
      node.normal['duplicity']['src_dir'] = '/usr/local/othersrc'
    end.converge(described_recipe)
  end    

  before(:each) do
    stub_command("which lockrun").and_return(true)
  end

  it "creates a lockrun directory in the configured source dir" do
    chef_run.should create_directory("/usr/local/othersrc/lockrun").with(
      :owner     => "root",
      :group     => "root",
      :mode      => 0755,
      :recursive => true      
    )
  end
  
  it "copies the lockrun.c source file to the source dir" do
    chef_run.should create_cookbook_file("/usr/local/othersrc/lockrun/lockrun.c").with(
      :owner  => "root",
      :group  => "root", 
      :mode    => 0644
    )
  end
  
  context "when lockrun is installed already" do
    before(:each) do
      stub_command("which lockrun").and_return(true)
    end

    it "does not compile" do
      chef_run.should_not run_execute("gcc lockrun.c -o lockrun")
    end
  end
  
  context "when lockrun is not installed" do
    before(:each) do
      stub_command("which lockrun").and_return(false)
    end
    
    cached (:chef_run) do
      ChefSpec::SoloRunner.new do | node |
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['src_dir'] = '/usr/local/othersrc'
      end.converge(described_recipe)
    end 

    it "compiles lockrun from source" do
      chef_run.should run_execute("gcc lockrun.c -o lockrun").with(
        :cwd  => "/usr/local/othersrc/lockrun",
        :user => "root"        
      )
    end
  end
  
  it "links the executable from /usr/local/bin" do
    chef_run.should create_link("/usr/local/bin/lockrun").with(
      :to => "/usr/local/othersrc/lockrun/lockrun"
    )
  end
  
end
