require File.expand_path('../../utils', __FILE__)

module WebSocketAgent
	module Server
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
	end
end