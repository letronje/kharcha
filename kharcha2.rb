#! /usr/bin/ruby

fpath = ARGV[0]

if fpath == nil
	puts "Enter kharcha data file name"
	exit
end

$AbbrRegex = /([a-zA-Z0-9_]+)\s*=\s*([a-zA-Z0-9_,\s\.\-\/]+)/
$KharchRegex1 = /(.*),\s*(.*)\s*,\s*(.*)\s*,\s*(\d*\.?\d*)\s*/
$KharchRegex2 = /(.*),\s*(.*)\s*,\s*(.*)\s*,\s*(\d*\.?\d*)\s*,all/
$KharchRegex3 = /(.*),\s*(.*)\s*,\s*(.*)\s*,\s*(\d*\.?\d*)\s*,\s*(.*)\s*/

#Stores what each person should pay others
#"[p1,p2] => A" indicates that p1 should pay amount "A" to p2
$PayMap = {}

#Stores total money each person should receive from others.
$RecvMap = {}

#Stores name abbreviations for each user
$AbbrMap = {}

#Stores total money spent by each person
$PaidMap = {}

#Stores expenditure between each pair of users
$KharchaMap = {}

$MaxAmountStrLen = 100000.to_s.length

$TotalSpent = 0

def process(paid_by, amount_paid, shared_grp, details)
	$TotalSpent += amount_paid
	each_pay = amount_paid / shared_grp.length
	
	if $PaidMap.include? paid_by
		$PaidMap[paid_by] += amount_paid
	else
		$PaidMap[paid_by] = amount_paid	
	end
		
	shared_grp.each do |guy|
		next if guy == paid_by
		key = [guy, paid_by]
		rev_key = key.reverse
		
		if $PayMap.include? key
			$PayMap[key] += each_pay
		elsif $PayMap.include? rev_key
			$PayMap[rev_key] += -each_pay
		else
			$PayMap[key]=each_pay
		end
		
		if $KharchaMap.include? key
			$KharchaMap[key] << [each_pay, details]
		else
			$KharchaMap[key] = [[each_pay, details]]
		end
			
	end
end				

def show_credits(fpath)
	File.open(fpath).each_line do |line|
		line.chomp!
		next if line.empty?
		case line
			when $AbbrRegex
				s1 = $1.strip
				s2 = $2.strip
				name = (s1.length > s2.length) ? (s1) : (s2)
				abbr = (s1.length < s2.length) ? (s1) : (s2)
				$AbbrMap[abbr] = name				
			when $KharchRegex3
				paid_by = $2.strip
				amount_paid = $4.strip.to_f
				grp = $5.chomp.strip.split(/\s*,\s*/)
				unless grp.include? paid_by
					grp << paid_by
				end
				process(paid_by, amount_paid, grp, line)
			when $KharchRegex1
				process($2.strip, $4.strip.to_f, $AbbrMap.keys, line)
			when $KharchRegex2
				process($2.strip, $4.strip.to_f, $AbbrMap.keys, line)
		end
	end
	
	puts "\nTotal Money Spent = #{$TotalSpent}"
	
	$PayMap.each_pair do|a, b|
		case 
			when b == 0
				$PayMap.delete(a)
			when b < 0
				$PayMap.delete(a)
				$PayMap[a.reverse] = -b
		end
	end
	
	$PayMap.each_pair do |a, b|
		if not $RecvMap.include? a[1]
			$RecvMap[a[1]] = b
		else
			$RecvMap[a[1]] += b
		end		
	end
	
	disp_str = "\n### DETAILS ###\n\n" 
	
	$AbbrMap.each_pair do |from, from_name|
		disp_str += "\n-- #{from_name}  should pay -- \n\n"
		
		$AbbrMap.each_pair do |to, to_name|
			pair = [from, to]
			next unless $KharchaMap.include? pair
			
			kharchas = $KharchaMap[pair]
			disp_str += "\t-- #{to_name} --\n\n"
			
			kharchas.sort! do |a, b|
				b[0] <=> a[0]
			end

			total = 0	
			
			kharchas.each do |kharcha|
				amount = kharcha[0]
				disp_str += "\t\t#{amount.round.to_s.ljust($MaxAmountStrLen)} for      \"#{kharcha[1]}\"\n"
				total += kharcha[0]
			end
			disp_str += "\n"
			disp_str += "\t\t--------------------\n"
			disp_str += "\t\tTotal = #{total.round} \n"
			disp_str += "\t\t--------------------\n\n"	
		end
		disp_str += "\n"
	end

	disp_str += "\n ## SUMMARY ##  \n"
	
	#puts $PayMap.inspect
	$AbbrMap.each_pair do |abbr, name|
		$PaidMap[abbr]=0.0 unless $PaidMap.include? abbr
		disp_str += "\n\n#{name} has already spent #{$PaidMap[abbr]}\n"
		total = 0
		str1 = "#{name} should pay ... \n"
		str2 = ""
		$PayMap.each_pair do |a, b|
			if a[0] == abbr
				#puts "\n#{a[1]}\n"
				str2 += "\t#{b.round} to #{$AbbrMap[a[1]]}\n"
				total += b
			end	
		end
		if str2 != ""
			disp_str += (str1 + str2 + "\t------------------------------\n\ttotal = #{total.round}\n\t------------------------------ \n")
		else
			disp_str += "\t#{name} need not pay anybody\n"
		end	
		
		#disp_str += "Total amt spent by #{name} will be #{total}"
	end

	disp_str += "\n"
	
	$AbbrMap.each_pair do |abbr, name|
		if $RecvMap[abbr].to_i > 0 
			disp_str += "#{name} should receive #{$RecvMap[abbr]}\n"
		end	
	end
		
	puts disp_str
end

show_credits(fpath)
