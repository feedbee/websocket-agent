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
						deltas = {}
						cpu_data.each_pair { |key, value| deltas[key] = value - @last_data[cpu_index][key] }

						diff_total = deltas.values.inject(:+)
						diff_idle = deltas[:idle]
						diff_all_user = deltas[:user] + deltas[:nice]
						diff_all_system = deltas[:system] + deltas[:irq] + deltas[:softirq]
						diff_iowait = deltas[:iowait] + deltas[:irq] + deltas[:softirq]

						usage = (diff_total - diff_idle) / diff_total.to_f
						user = diff_all_user / diff_total.to_f
						system = diff_all_system / diff_total.to_f
						iowait = diff_iowait / diff_total.to_f

						hash = {:usage => usage, :user => user, :system => system, :iowait => iowait}
						hash = hash.merge(hash){ |key, value| round_2p2 value }

						cpu_usage[cpu_index] = hash
					end
					
					@last_data = new_data
					cpu_usage
				end

				def round_2p2 number
					(number * 100).round / 100.to_f
				end
			end
		end
	end
end