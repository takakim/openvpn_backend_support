# frozen_string_literal: true

require 'speedtest'
require 'net/http'

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
  result = `fast`
  regex = /([\d]+\.[\d]+)/
  results = result.scan(regex).flatten.map(&:to_f)
  "#{results.reduce(:+).to_f / results.size} mpbs"
end

puts evaluate_speedtest
puts evaluate_fast_com
