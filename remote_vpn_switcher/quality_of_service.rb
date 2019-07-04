# frozen_string_literal: true

require 'speedtest'
require 'net/http'
require 'json'

def evaluate_speedtest
  begin
    run = Speedtest::Test.new.run
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
  { download: "#{results[-2]} Mbps", upload: "#{results[-1]} Mbps" }
end

def store_data(a_data)
  time = Time.now.strftime '%Y-%m-%d_%H-%M-%S'
  begin
    target_file = File.open("measurement_#{time}.data", 'w')
    target_file.write(JSON.generate(a_data))
  rescue StandardError => e
    puts e.to_s
  ensure
    target_file.close
  end
end

def retrieve_data
  result = nil
  begin
    file = Dir['**/*.{data}'].max_by { |f| File.mtime(f) }
    result = JSON.parse(File.open(file).read, symbolize_names: true)
  rescue StandardError => e
    puts e.to_s
  end
  result
end

def compare(initial, last)
  result = {}
  initial.keys.each do |key|
    initial_obj = initial[key]
    last_obj = last[key]
    download_rate = last_obj[:download].to_f / initial_obj[:download].to_f
    upload_rate = last_obj[:upload].to_f / initial_obj[:upload].to_f
    result.merge!(key => { download: download_rate, upload: upload_rate })
  end
  result
end

initial = retrieve_data
speedtest = evaluate_speedtest
fast = evaluate_fast_com
result = { speedtest: speedtest, fast: fast }
initial = result if initial.nil?
puts result.to_s
puts store_data result
puts compare(initial, result).to_s
