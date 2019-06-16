# frozen_string_literal: true

require 'sinatra'
require_relative 'best_server.rb'

set :bind, '192.168.1.249'

def kill_pid(cmd)
  pidof = "pidof #{cmd}"
  pid = `#{pidof}`.strip
  if pid
    kill_command = "sudo kill -9 #{pid}"
    `#{kill_command}`
  end
  `#{pidof}`.strip
end

def current_state
  ps = `ps aux | grep openvpn`
  matched = ps.match(/([\D]{2}[\d]{4}\.nordvpn\.com\.[\w]+\.ovpn)/i)
  if matched
    matched.captures[0]
  else
    'Not connected'
  end
end

def parse_params(a_param, a_server)
  countries = find_countries
  if a_param.length == 2 && countries[a_param.upcase]
    a_param = 'GB' if a_param.upcase == 'UK'
    result = find_best_server a_param, a_server
  elsif a_param.length > 2
    result = find_best_server a_param, a_server
  else
    result = nil
  end
  result
end

get '/change-server' do
  server = parse_params params[:server], current_state
  current_server = current_state
  if server
    openvpn_auth = '--auth-user-pass /etc/openvpn/auth.txt'
    openvpn_config = "/etc/openvpn/servers/#{server}.nordvpn.com.udp1194.ovpn"
    if File.exist?(openvpn_config)
      kill_pid 'openvpn'
      openvpn_command = "sudo openvpn --config #{openvpn_config} #{openvpn_auth}"
      job1 = fork do
        exec openvpn_command
      end
      Process.detach(job1)
      sleep 2
      new_server = current_state
      "Current server is: #{new_server}\nPreviously connected to: #{current_server}"
    else
      "Server info not found #{openvpn_config}\nRemain connected to server: #{current_server}"
    end
  else
    "Invalid server to connect: #{server}\nCurrent server: #{current_server}"
  end
end
