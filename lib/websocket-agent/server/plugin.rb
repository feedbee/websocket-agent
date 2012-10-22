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

			class Processes < ShellCmd
				def name
					"processes"
				end
				def initialize
					@command = 'ps aux --no-headers | awk \'{ print $8 }\''
				end
				def parse (data)
					all_processes = data.split("\n").map { |el| el[0..0] }

					running = all_processes.select { |el| el == "R" }.length - 1 # all running except self (ps) process
					sleep = all_processes.select { |el| el == "S" || el == "D" }.length
					stopped = all_processes.select { |el| el == "T" }.length
					zombie = all_processes.select { |el| el == "Z" }.length

					{:all => running + sleep + stopped + zombie, :running => running, :sleep => sleep,
						:stopped => stopped, :zombie => zombie}
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

			class MemInfo
				def name
					"meminfo"
				end
				def data
					data = WebSocketAgent::Server::Utils::MemInfo.get
					values = {}
					data.each_pair { |k, v| values[k] = v[:value] }

					{
						:memory => {:total => values["MemTotal"], :used => values["MemTotal"] - values["MemFree"], :free => values["MemFree"],
							:buffers => values["Buffers"], :cached => values["Cached"]},
						:swap => {:total => values["SwapTotal"], :used => values["SwapTotal"] - values["SwapFree"], :free => values["SwapFree"],
							:cached => values["SwapCached"]}
					}
				end
			end
		end
	end
end