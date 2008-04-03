%w(rubygems active_record active_support gchart).each {|lib| require lib}

# Config
#-------------------------------------------------------------------------------------------------------------
days_back = 90


# Create file on the desktop
#-------------------------------------------------------------------------------------------------------------
filename = "#{ENV["HOME"]}/Desktop/firefox_activity_report_#{Time.now.tv_sec}.html"
output_file = File.new(filename, "a+")
output = ""


# Time Formats
#-------------------------------------------------------------------------------------------------------------
ymdhms = "%Y%m%d %H%M%S"
hms = "%H%M%S"
hms_with_colons = "%H:%M:%S"
h = "%H"
m = "%M"
nice_date = "%A, %b %d, %Y"


# Extend Time. Ha.
#-------------------------------------------------------------------------------------------------------------
class Time
  def to_moz_time
    self.to_i * 1000000
  end

  def beginning_of_day
  	(self - self.seconds_since_midnight).change(:usec => 0)
  end

  def seconds_since_midnight
  	self.to_i - self.change(:hour => 0).to_i + (self.usec/1.0e+6)
  end
  
  def end_of_day
    change(:hour => 23, :min => 59, :sec => 59)
  end
end


# Crack open the Places database
#-------------------------------------------------------------------------------------------------------------
ActiveRecord::Base.establish_connection(
	:adapter => "sqlite3",
	:database => Pathname.glob("#{ENV["HOME"]}/Library/Application Support/Firefox/Profiles/*/places.sqlite").sort_by {|i| i.size }.last
)


# Fudge some classes
#-------------------------------------------------------------------------------------------------------------
class MozHistoryvisit < ActiveRecord::Base
	belongs_to :place, :class_name => "MozPlaces", :foreign_key => "place_id"
	
	def date
	  Time.at(visit_date.to_i/1000000)
  end
  
  def hour_of_day
    date.strftime("%H").to_i
  end
  
  def minute_of_day
    hour_of_day*60 + date.strftime("%M").to_i
  end
  
end

class MozPlaces < ActiveRecord::Base
end


# Get them visits!
#-------------------------------------------------------------------------------------------------------------
days_back.downto(0) do |day|
  visits = MozHistoryvisit.find(:all, :conditions => ["visit_date > ? AND visit_date < ?", day.days.ago.beginning_of_day.to_moz_time, day.days.ago.end_of_day.to_moz_time])

  unless visits.empty?
    hours = []
    0.upto(23) {|hour| hours[hour] = visits.map(&:hour_of_day).select{|h| h==hour}.size }
    
    chart = Gchart.bar(
      :size => '900x100',
      :data => hours,
      :axis_with_labels => 'x,r',
      :axis_labels => [(0..23).to_a.join("|"), [0,hours.max].join("|")]
    )
    
    output << "<img src='#{chart}'><br/>"

    hours_spanned = ((visits.last.minute_of_day - visits.first.minute_of_day).to_f/60*4).to_i.to_f/4

    output << "<b>#{day.days.ago.strftime(nice_date)}</b><br />"
    output << "Activity Span: #{visits.first.date.strftime(hms_with_colons)}-#{visits.last.date.strftime(hms_with_colons)} (~#{hours_spanned})<br />"
    output << "Active Hours: #{hours.select{|h| h>0}.size}"
    output << "<br /><br /><br /><br />"
  end
end

# Slap some HTML and accumulated output to file and open it
#-------------------------------------------------------------------------------------------------------------
output_file.puts "<html><head><title>Firefox Activity Report</title></head><body>"
output_file.puts "<h1>Firefox Activity Report</h1>"
output_file.puts "<h2>#{days_back.days.ago.strftime(nice_date)} to #{Time.now.strftime(nice_date)}</h2>"
output_file.puts output
output_file.puts "</body></html>"
`open '#{filename}'`
