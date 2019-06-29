# frozen_string_literal: true

require 'speedtest'
require 'net/http'
require 'json'

def evaluate_speedtest
  begin
    run = Speedtest::Test.new().run
    result = {
      download: run.pretty_download_rate, upload: run.pretty_upload_rate
    }
  rescue Net::OpenTimeout
    result = {}
  end
  result
end

def evaluate_fast_com
  result = `speed-test`
  regex = /([\d]+[\.\d]+ Mbps)/
  results = result.scan(regex).flatten.map(&:to_f)
  {download: "#{results[-2]} Mbps", upload: "#{results[-1]} Mbps"}
end

def store_data(a_data)
  time = Time.now.strftime '%Y-%m-%d_%H-%M-%S'
  begin
    target_file = File.open("measurement_#{time}.data", 'w')
    target_file.write(a_data)
  rescue StandardError => e
    puts e.to_s
  ensure
    target_file.close
  end
end

def retrieve_data
  file = Dir['**/*.{data}'].max_by {|f| File.mtime(f)}
  result = JSON.parse(File.open(file).read)
rescue StandardError => e
  puts e.to_s
  result
end

def compare(initial, last)
  down = 'download'
  up = 'upload'
  result = {}
  initial.each_key do |key|
    download_rate = last[key][down].to_f / initial[key][down].to_f
    upload_rate = last[key][up].to_f / initial[key][up].to_f
    result.merge!({key =>
      {
        down => download_rate,
        up => upload_rate
      }
    })
  end
  result
end

initial = retrieve_data
speedtest = evaluate_speedtest
fast = evaluate_fast_com
result = ({speedtest: speedtest, fast: fast}).to_json
# puts "speed test: #{speedtest}"
# puts "fast: #{fast}"
puts result.to_s
puts store_data result
puts compare(initial, JSON.parse(result)).to_s
