require 'spec_helper'

describe 'duplicity-backup::schedule_backup' do
  let (:chef_runner) { ChefSpec::SoloRunner.new }
  let (:chef_run)    { chef_runner.converge(described_recipe) }

  before(:each) do
    #todo - fix the lockrun recipe so we don't need to stub this
    stub_command("which lockrun").and_return('/bin/lockrun')
  end

  context 'by default' do
    it 'throws that no schedule is defined' do
      expect { chef_run }.to raise_error Chef::Exceptions::ValidationFailed
    end
  end

  context 'with minimum valid config' do
    before (:each) do
      chef_runner.node.normal['duplicity']['schedule']['hour'] = 3
    end

    context 'by default' do
      cached(:chef_run) { chef_runner.converge(described_recipe) }
      it 'deletes any legacy `duplicity_backup` raw cron' do
        expect(chef_run).to delete_cron('duplicity_backup')
      end

      it 'includes the monitored-cron::default recipe' do
        expect(chef_run).to include_recipe 'monitored-cron::default'
      end

      it 'creates a monitored_cron for the backup job' do
        expect(chef_run).to create_monitored_cron('duplicity-backup').with(
          command: '/etc/duplicity/backup.sh'
        )
      end

      it 'specifies that the backup job requires a lock' do
        expect(chef_run).to create_monitored_cron('duplicity-backup').with(
          require_lock: true
        )
      end

      it 'configures only the specified schedule values *' do
        # takes the value from the setup above
        expect(chef_run).to create_monitored_cron('duplicity-backup').with(schedule: { 'hour' => 3 })
      end

      it 'does not configure a notify url' do
        expect(chef_run).to create_monitored_cron('duplicity-backup').with(notify_url: nil)
      end
    end

    context 'with additional custom config' do

      it 'configures a notify url' do
        chef_runner.node.normal['duplicity']['success_notify_url'] = 'http://foo.bar/:runtime:'
        expect(chef_run).to create_monitored_cron('duplicity-backup').with(
          notify_url: 'http://foo.bar/:runtime:'
        )
      end

      it 'sets a complete backup schedule from node attributes' do
        chef_runner.node.normal['duplicity']['schedule'] = {
          'minute'  => 1,
          'hour'    => 2,
          'day'     => 3,
          'weekday' => 4,
          'month'   => 5
        }

        expect(chef_run).to create_monitored_cron('duplicity-backup').with(
          schedule: {
            'minute'  => 1,
            'hour'    => 2,
            'day'     => 3,
            'weekday' => 4,
            'month'   => 5
          }
        )
      end
    end
  end
end
