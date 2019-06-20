# frozen_string_literal: true

require 'rest-client'
require 'json'

def load_countries_from_file
  begin
    @file_name = 'servers_ids.txt'
    countries = instance_eval(File.read(@file_name))
  rescue StandardError
    puts 'Countries file not found!!'
    puts "File name: #{@file_name}"
    countries = {}
  end
  countries
end

def store_countries_to_file(a_countries)
  File.write(@file_name, a_countries)
end

def retrieve_countries
  countries = {}
  (1..260).each do |id|
    @base_url = 'https://nordvpn.com/wp-admin/admin-ajax.php'
    @base_query = '?action=servers_recommendations&filters={"country_id":'
    resp = RestClient.get(@base_url + @base_query + "#{id}}")
    next unless resp.body.length > 50

    servers = JSON.parse(resp.body)
    countries.merge!(servers[0]['locations'][0]['country']['code'] => id)
  end
  countries
end

def find_countries
  countries = load_countries_from_file
  if countries.empty?
    countries = retrieve_countries
    store_countries_to_file(countries)
  end
  puts countries.to_s
  countries
end

def network_call(a_country_code)
  begin
    @base_url = 'https://nordvpn.com/wp-admin/admin-ajax.php'
    @base_query = '?action=servers_recommendations&filters={"country_id":'
    resp = RestClient.get("#{@base_url}#{@base_query}#{a_country_code}}")
    servers = JSON.parse(resp.body)
  rescue RestClient::Exception => e
    puts "Access denied\n#{e.response}"
    servers = {}
  end
  servers
end

def find_best_server(a_country_code = 'US', a_current_server = nil)
  country_code = find_countries[a_country_code.upcase]
  servers = network_call(country_code)
  puts 'current server ' + a_current_server.to_s
  target_server = servers[0]['hostname']
  if a_current_server
    target_server = match_current_server(servers, a_current_server)
  end
  target_server.slice! '.nordvpn.com'
  target_server
end

def match_current_server(a_server_list, a_current_server)
  result = a_server_list[0]['hostname']
  best_server_load = a_server_list[0]['load']
  a_server_list.each do |server|
    server_load = server['load']
    hostname = server['hostname']
    if (hostname.include? a_current_server) && (server_load <= best_server_load)
      result = a_current_server
    end
  end
  result
end
