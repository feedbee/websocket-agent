module WebSocketAgent
	module Server
		module Utils
			module ProcStat
				# All values are mesured in jiffies
				# Method source: https://github.com/djberg96/sys-cpu/blob/ffi/lib/linux/sys/cpu.rb
				# with modfications
				def self.cpu_stat
					cpu_stat_file = "/proc/stat" # file description: http://www.linuxhowtos.org/System/procstat.htm
					hash = {} # Hash needed for multi-cpu systems

					lines = IO.readlines(cpu_stat_file)

					lines.each_with_index{ |line, i|
						array = line.split
						cpuName = array[0]
						break unless cpuName =~ /cpu/   # 'cpu' entries always on top

						# Some machines list a 'cpu' and a 'cpu0'. In this case only
						# return values for the numbered cpu entry.
						if lines[i].split[0] == "cpu" && lines[i+1].split[0] =~ /cpu\d/
						  next
						end

						vals = array[1..-1].map{ |e| e = e.to_i }
						valsHash = {}
						[:user,:nice,:system,:idle,:iowait,:irq,:softirq].each_with_index { |key, index|
							valsHash[key] = vals[index]
						}
						hash[cpuName] = valsHash
					}

					hash
				end
			end
		end
	end
end