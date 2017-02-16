require 'spec_helper'

describe 'duplicity-backup::schedule_backup' do
  cached (:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      # Set non-standard attributes to check the recipe is using the attributes
      node.normal['duplicity']['schedule'] = {
        'minute'  => 1,
        'hour'    => 2,
        'day'     => 3,
        'weekday' => 4,
        'month'   => 5
      }
      node.normal['duplicity']['success_notify_url'] = 'http://foo.bar/:runtime:'
    end.converge(described_recipe)
  end

  it 'deletes any legacy `duplicity_backup` raw cron' do
    expect(chef_run).to delete_cron('duplicity_backup')
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

  it 'sets the configured schedule for the backup' do
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

  it 'configures an optional notify url' do
    expect(chef_run).to create_monitored_cron('duplicity-backup').with(
      notify_url: 'http://foo.bar/:runtime:'
    )
  end

  context 'with some schedule attributes configured' do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['schedule']['hour'] = 3
      end.converge(described_recipe)
    end

    it 'configures only the specified schedule values *' do
      expect(chef_run).to create_monitored_cron('duplicity-backup').with(schedule: { 'hour' => 3 })
    end
  end

  context 'with default options and at least one schedule option' do
    cached (:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        # Set non-standard attributes to check the recipe is using the attributes
        node.normal['duplicity']['schedule']['hour'] = 3
      end.converge(described_recipe)
    end
    it 'does not set a notify_url' do
      expect(chef_run).to create_monitored_cron('duplicity-backup').with(notify_url: nil)
    end
  end
end
