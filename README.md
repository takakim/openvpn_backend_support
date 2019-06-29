# Openvpn server switch support
Simple backend server that supports changing a local vpn client to a different server, either a specific server or the best server from NordVPN.
The code is based on ruby-2.6.3 and sinatra 
For a QoS feature it's required to to have extra libaries:
  - https://github.com/petemyron/speedtest -> ruby gem
  - https://github.com/sindresorhus/speed-test -> node.js

The goal of QoS is to measure the bandwidth from X time and automatically change to a different server.
