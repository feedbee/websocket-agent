require 'rubygems'
require 'json'
require File.expand_path('../../../vendor/em-websocket/lib/em-websocket', __FILE__)
require File.expand_path('../utils', __FILE__)

module WebSocketAgent
	VERSION = '001'
	NAME = 'WebSocketAgent'

	module Server

		class Worker

			def initialize (ws, plugins)
				@ws = ws
				@plugins = plugins
				@interval = 1
				@push_timer
			end

			def open
				@ws.send "Welcome::" + WebSocketAgent::NAME + " v." + WebSocketAgent::VERSION

				@ws.onmessage { |msg| self.process(msg) }
			    @ws.onclose { self.stop }
			end

			def start_timer
				@push_timer = EM.add_periodic_timer(@interval) { self.push }
			end

			def stop_timer
				EM.cancel_timer(@push_timer)
				@push_timer = nil
			end

			def push
				response = {}

				@plugins.each do |el|
					response[el.name] = el.data
				end

				@ws.send('Push::' + response.to_json)
			end

			def start
				stop_timer if @push_timer
				start_timer
			end

			def stop
				stop_timer
			end

			def set_interval (arg)
				@interval = arg
				stop_timer
				start_timer
			end

			def process (msg)
				if (msg.length < 1)
					send_error "Unknown message"
					return
				end

				parts = msg.split '::'
				message = parts[0]
				case message
					when 'start'
						start
					when 'stop'
						stop
					when 'interval'
						if (parts.length < 2)
							send_error "Interval message require has 1 required parameter: int interval (not set)"
							return
						end
						begin
							arg = parts[1].to_i
						rescue
							send_error "Interval message require has 1 required parameter: int interval (not int)"
							return
						end
						set_interval arg
					else
						send_error "Unknown message"
				end
			end

			def send_error (msg)
				@ws.send "Error::" + msg
			end

			private :send_error, :start_timer, :stop_timer
		end

		module Plugin
			class ShellCmd
				def data
					parse(output)
				end
				def output
					`#{@command}`
				end
				def parse (data)
					data
				end
			end
			class Uptime < ShellCmd
				def name
					"uptime"
				end
				def initialize
					@command = 'uptime'
				end
				def parse (data)
					matches = data.match(/ (.*) up  (.*),  (\d+) users,  load average: (.*), (.*), (.*)/)
					{:time => matches[1], :uptime => matches[2], :users => matches[3],
						:la1 => matches[4], :la5 => matches[5], :la15 => matches[6]}
				end
			end
			class CpuUsage
				def initialize
					@last_data = WebSocketAgent::Server::Utils::ProcStat.cpu_stat
				end
				def name
					"cpu_stat"
				end
				def data
					new_data = WebSocketAgent::Server::Utils::ProcStat.cpu_stat
					
					cpu_usage = {}
					new_data.each_pair do |cpu_index, cpu_data|
						deltas = []
						cpu_data.each_with_index { |value, value_index| deltas.push value - @last_data[cpu_index][value_index] }

						diff_total = deltas.inject(:+)
						diff_idle = deltas[3]

						diff_usage = (diff_total - diff_idle) / diff_total.to_f
						cpu_usage[cpu_index] = diff_usage
					end
					
					@last_data = new_data
					cpu_usage
				end
			end
		end

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
				WebSocketAgent::Server::Plugin::CpuUsage.new
			]
		end
	end
end