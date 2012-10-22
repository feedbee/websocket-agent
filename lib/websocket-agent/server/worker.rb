require 'rubygems'
require 'json'
require File.expand_path('../../../../vendor/em-websocket/lib/em-websocket', __FILE__)

module WebSocketAgent
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
	end
end