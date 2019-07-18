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
  sleep 2
  ps = `ps aux | grep openvpn`
  matched = ps.match(/([\D]{2}[\d]{2,}\.nordvpn\.com\.[\w]+\.ovpn)/i)
  if matched
    matched.captures[0]
  else
    'Not connected'
  end
end

def find_ovpn(a_server)
  openvpn_config = "/etc/openvpn/servers/ovpn_udp/#{a_server}.nordvpn.com.udp1194.ovpn"
  openvpn_config if File.exist? openvpn_config
end

def parse_params(a_param, a_server)
  countries = find_countries
  a_param = 'GB' if a_param.upcase == 'UK'
  if a_param.length == 2 && countries[a_param.upcase]
    result = find_best_server a_param, a_server
  elsif a_param.length > 2
    result = a_param
  else
    result = nil
  end
  result
end

get '/change-server' do
  current_server = current_state
  server = parse_params params[:server], current_state
  if server
    openvpn_auth = '--auth-user-pass /etc/openvpn/auth.txt'
    if (openvpn_config = find_ovpn server)
      kill_pid 'openvpn'
      openvpn_command = "sudo openvpn --config #{openvpn_config} #{openvpn_auth}"
      job1 = fork do
        exec openvpn_command
      end
      Process.detach(job1)
      new_server = current_state
      "Current server is: #{new_server}\nPreviously connected to: #{current_server}"
    else
      "Server info not found #{openvpn_config}\nRemain connected to server: #{current_server}"
    end
  else
    "Invalid server to connect: #{server}\nCurrent server: #{current_server}"
  end
end
