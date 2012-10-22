require 'rubygems'
require 'json'
require File.expand_path('../../../vendor/em-websocket/lib/em-websocket', __FILE__)
require File.expand_path('../server/worker', __FILE__)
require File.expand_path('../server/plugin', __FILE__)
require File.expand_path('../utils', __FILE__)

module WebSocketAgent
	module Server
		def self.start (configHash = {})

			configHash = {} if configHash.class != Hash
			configHash[:host] = "0.0.0.0" if !configHash[:host]
			configHash[:port] = "8080" if !configHash[:port]
			configHash[:debug] = false if !configHash[:debug]
			configHash[:plugins] = self.getDefaultPlugins if !configHash[:plugins]

			EventMachine::WebSocket.start(configHash) do |ws|
				ws.onopen do
					puts "WebSocket opened" if configHash[:debug]
					ss = WebSocketAgent::Server::Worker.new(ws, configHash[:plugins]);
					ss.open
				end

				if configHash[:debug]
					ws.onmessage { |msg| puts "WebSocket message #{msg}" }
					ws.onclose   { puts "WebSocket closed" }
					ws.onerror   { |e| puts "Error: #{e.message}" }
				end
			end
		end

		def self.stop
			EventMachine::WebSocket.stop
		end

		def self.getDefaultPlugins
			[
				WebSocketAgent::Server::Plugin::Uptime.new,
				WebSocketAgent::Server::Plugin::CpuUsage.new,
				WebSocketAgent::Server::Plugin::Processes.new,
				WebSocketAgent::Server::Plugin::MemInfo.new
			]
		end
	end
end