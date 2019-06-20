# Openvpn server switch support
Simple backend server that supports changing a local vpn client to a different server, either a specific server or the best server from NordVPN.
The code is based on ruby-2.6.3 and sinatra 
Some extra libraries:
  - https://github.com/petemyron/speedtest
  - https://github.com/banteg/fast

Those extra libraries are used for the QOS (quality_of_service.rb) future implementation, which the goal is to measure the bandwidth from X time and automatically change to a different server.
