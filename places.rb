require 'rubygems'

file =  File.new("visit_dates.csv")
visits = file.readlines

fmt = "%d %b %Y at %I:%M:%S %p"
hour_fmt = "%I:%M %p"

yday = 0
start_min = 0
visits[0..100].sort.each_with_index do |visit, index|
  time = Time.at(visit.to_i/1000000)
  
  current_yday = time.yday.to_i


  if current_yday != yday
    if index > 0
      puts "Last total: #{((time.hour*60) + time.min) - start_min}"
    end
    
    start_min = ((time.hour*60) + time.min)
    
    puts "\n\n"
    puts Time.at(time).strftime(fmt)
    yday = current_yday
  else
    puts Time.at(time).strftime(hour_fmt) + " - " + ((time.hour*60) + time.min).to_s
  end

end