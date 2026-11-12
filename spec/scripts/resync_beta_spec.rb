require 'spec_helper'
require 'open3'
require 'tmpdir'

describe 'script/resync-beta.sh' do # rubocop:disable RSpec/DescribeClass
  around do |example|
    Dir.mktmpdir('resync-spec') do |dir|
      @dir = dir
      File.write("#{dir}/ssh", <<~SH)
        #!/bin/bash
        if [ "$1" = -G ]; then
          echo "hostname ${2#root@}"
          exit 0
        fi
        command="${@: -1}"
        echo "$command" >> "$CALL_LOG"
        case "$command" in
          *blackbook-live*) exit "$MARKER_STATUS" ;;
          *cat\\ /etc/machine-id*)
            if [[ "$*" == *root@production.test* ]]; then
              printf '%032d\\n' 1
            else
              printf '%032d\\n' 2
            fi
            ;;
          *systemctl*) echo inactive ;;
          DB=*)
            [[ "$*" == *root@production.test* ]] && export COUNT_HOST=production || export COUNT_HOST=beta
            [ "$FAILURE" = "${COUNT_HOST}_ssh" ] && exit 255
            exec bash -c "$command"
            ;;
          *mysqldump*) printf '' ;;
          *gunzip*) cat >/dev/null ;;
        esac
      SH
      File.write("#{dir}/mysql", <<~'SH')
        #!/bin/bash
        case "$*" in
          *information_schema*)
            [ "$FAILURE" = "${COUNT_HOST}_tables" ] && exit 1
            printf 'tags\nusers\n'
            ;;
          *)
            [ "$FAILURE" = "${COUNT_HOST}_count" ] && exit 1
            echo 2
            ;;
        esac
      SH
      File.chmod(0o700, "#{dir}/ssh", "#{dir}/mysql")
      example.run
    end
  end

  def run_sync(marker_status: 0, failure: '')
    output, status = Open3.capture2e(
      {
        'PATH' => "#{@dir}:#{ENV.fetch('PATH')}",
        'PROD_HOST' => 'production.test', 'BETA_HOST' => 'beta.test',
        'CALL_LOG' => "#{@dir}/calls", 'MARKER_STATUS' => marker_status.to_s,
        'FAILURE' => failure
      },
      'bash', File.expand_path('../../script/resync-beta.sh', __dir__),
      stdin_data: "beta.test\n"
    )
    [output, status, File.read("#{@dir}/calls")]
  end

  [1, 255].each do |status|
    it "does not drop the database when the marker check exits #{status}" do
      output, result, calls = run_sync(marker_status: status)
      expect(result).not_to be_success
      expect(calls).not_to include('DROP DATABASE', 'rsync -a')
      expect(output).to include('live-marker check failed')
    end
  end

  %w[production beta].each do |host|
    %w[ssh tables count].each do |failure|
      it "stops before mirroring files when #{host} #{failure} fails" do
        output, result, calls = run_sync(failure: "#{host}_#{failure}")
        expect(result).not_to be_success
        expect(calls).not_to include('rsync -a')
        expect(calls).to include("DB='")
        expect(output).not_to include('loaded: table row counts match')
      end
    end
  end

  it 'mirrors files after successful checks and matching counts' do
    output, result, calls = run_sync
    expect(result).to be_success
    expect(output).to include('loaded: table row counts match')
    expect(calls).to include('rsync -a')
  end
end
