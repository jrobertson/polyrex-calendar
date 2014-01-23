#!/usr/bin/env ruby

# file: polyrex-calendar.rb

require 'polyrex'
require 'date'
require 'nokogiri'
require 'chronic_duration'
require 'chronic_cron'


MONTH = DAY * 30


h = {
  calendar: 'calendar[year]',
     month: 'month[n, title]',
      week: 'week[n, mon, no, label]',
       day: 'day[sdate, xday, event, bankholiday, title, sunrise, sunset]',
     entry: 'entry[time_start, time_end, duration, title]'
}
visual_schema = h.values.join '/'
PolyrexObjects.new(visual_schema)

module LIBRARY

  def fetch_file(filename)

    #lib = File.dirname(__FILE__)
    #File.read filename      
    lib = 'http://rorbuilder.info/r/ruby/polyrex-calendar'
    open(File.join(lib, filename), 
      'UserAgent' => 'PolyrexCalendar'){|x| x.read }
  end

  def generate_webpage(xml, xsl)
    
    # transform the xml to html
    doc = Nokogiri::XML(xml)
    xslt  = Nokogiri::XSLT(xsl)
    xslt.transform(doc).to_s   
  end
end 

class Polyrex
  include LIBRARY

  attr_accessor :xslt, :css_layout, :css_style, :filename

  def inspect()
    "#<Polyrex:%s" % __id__
  end

  def to_webpage()

    year_xsl        = fetch_file self.xslt
    year_layout_css = fetch_file self.css_layout
    year_css        = fetch_file self.css_style

    File.open('self.xml','w'){|f| f.write (self.to_xml pretty: true)}
    File.open(self.xslt,'w'){|f| f.write year_xsl }
    #html = Rexslt.new(month_xsl, self.to_xml).to_xml

    html = generate_webpage self.to_xml, year_xsl
    {self.filename => html, 
      self.css_layout => year_layout_css, self.css_style => year_css}

  end           
end

class PolyrexObjects::Month
  include LIBRARY

  attr_accessor :xslt, :css_layout, :css_style

  def inspect()
    "#<PolyrexObjects::Month:%s" % __id__
  end

  def to_webpage()

    month_xsl        = fetch_file self.xslt
    month_layout_css = fetch_file self.css_layout
    month_css        = fetch_file self.css_style

    #html = Rexslt.new(month_xsl, self.to_xml).to_xml

    # add a css selector for the current day
    date = Time.now.strftime("%Y-%b-%d")
    doc = Rexle.new self.to_xml
    e = doc.root.element("records/week/records/day/summary[sdate='#{date}']")
    e.add Rexle::Element.new('css_style').add_text('selected')

    File.write 'self.xml', self.to_xml(pretty: true)
    File.write 'month.xsl', month_xsl 


    html = generate_webpage doc.xml, month_xsl
    {self.title.downcase[0..2] + '_calendar.html' => html, 
      self.css_layout => month_layout_css, self.css_style => month_css}
  end      
  
  def wk(n)
    self.records[n-1]        
  end      
end

class PolyrexObjects::Week
  include LIBRARY

  def inspect()
    "#<PolyrexObjects::Week:%s" % __id__
  end
  
  def to_webpage()

    week_xsl        = fetch_file 'week_calendar.xsl'
    week_layout_css = fetch_file 'week_layout.css'
    week_css        = fetch_file 'week.css'

    File.write 'self.xml', self.to_xml(pretty: true)
    File.write 'week.xsl', week_xsl
    #html = Rexslt.new(week_xsl, self.to_xml).to_xml
    #html = xsltproc 'week_calendar.xsl', self.to_xml

    # add a css selector for the current day
    date = Time.now.strftime("%Y-%b-%d")
    doc = Rexle.new self.to_xml
    e = doc.root.element("records/day/summary[sdate='#{date}']")

    e.add Rexle::Element.new('css_style').add_text('selected')

    html = generate_webpage doc.xml, week_xsl
    {'week' + self.no + '_planner.html' => html, 'week_layout.css' => week_layout_css, \
     'week.css' => week_css}
  end  
end

class PolyrexObjects::Day

  def date()
    Date.parse(self.sdate)
  end

  def wday()
    self.date.wday
  end

  def day()
    self.date.day
  end
end

class PolyrexCalendar
  include LIBRARY

  attr_accessor :xsl, :css, :polyrex, :month_xsl, :month_css
  attr_reader :day
  
  def initialize(calendar_file=nil, options={})

    opts = {year: Time.now.year.to_s}.merge(options)
    @year = opts[:year]

    h = {
      calendar: 'calendar[year]',
         month: 'month[n, title]',
          week: 'week[n]',
           day: 'day[sdate, xday, event, bankholiday, title, sunrise, sunset]',
         entry: 'entry[time_start, time_end, duration, title]'
    }
    @schema = %i(calendar month day entry).map{|x| h[x]}.join '/'


    if calendar_file then
      @polyrex = Polyrex.new calendar_file
      @id = @polyrex.id_counter

    else
      @id = '1'
      # generate the calendar

      a = (Date.parse(@year + '-01-01')...Date.parse(@year.succ + '-01-01')).to_a

      @polyrex = Polyrex.new(@schema, id_counter: @id)
      @polyrex.summary.year = @year

      a.group_by(&:month).each do |month, days| 

        @polyrex.create.month no: month.to_s, title: Date::MONTHNAMES[month]  do |create|
          days.each do |x|
            create.day sdate: x.strftime("%Y-%b-%d"), xday: x.day.to_s, title: Date::DAYNAMES[x.wday]
          end
        end
      end

    end

    visual_schema = h.values.join '/'
    PolyrexObjects.new(visual_schema)

    @xsl = fetch_file 'calendar.xsl'
    @css = fetch_file 'layout.css'
       
  end

  def to_a()
    @a
  end

  def to_xml()
    @polyrex.to_xml pretty: true
  end

  def import_events(objx)
    @id = @polyrex.id_counter
    method('import_'.+(objx.class.to_s.downcase).to_sym).call(objx)
    self
  end
  
  alias import! import_events

  def inspect()
     %Q(=> #<PolyrexCalendar:#{self.object_id} @id="#{@id}", @year="#{@year}">)
  end

  def kitchen_planner()

    #px = Polyrex.new(@schema, id_counter: @id)
    #px.summary.year = @year
    #(1..12).each {|n| px.add self.month(n, monday_week: true) }
    px = @polyrex

    px.xslt = 'kplanner.xsl'
    px.css_layout = 'monthday_layout.css'
    px.css_style = 'monthday.css'
    px.filename = @year + '-kitchen-planner.html'

    px
    
  end

  def year_planner()

    px = Polyrex.new(@schema, id_counter: @id)
    px.summary.year = @year
    (1..12).each {|n| px.add self.month(n, monday_week: true) }

    px.xslt = 'calendar.xsl'
    px.css_layout = 'layout.css'
    px.css_style = 'year.css'
    px.filename = px.summary.year.to_s + '-planner.html'

    px
    
  end

  def month(m, monday_week: false)

    if monday_week == true

      pxmonth = make_month(m) do |a, wday|

        # Monday start
        # wdays: 1 = Monday, 0 = Sunday

        r = case wday

          # the 1st day of the month is a Monday, add no placeholders
          when 1 then  a

          # the 1st day is a Sunday, add 6 placeholders before that day
          when 0 then Array.new(6) + a

          # add a few placeholders before the 1st day          
          else Array.new(wday - 1) + a
        end

        r


      end

      pxmonth.xslt = 'monthday_calendar.xsl'
      pxmonth.css_layout = 'monthday_layout.css'
      pxmonth.css_style = 'monthday.css'
      pxmonth

    else

      pxmonth = make_month(m) do |a, wday|

        # Sunday start
        # wdays: 1 = Monday, 0 = Sunday

        r = case wday

          # the 1st day of the month is a Sunday, add no placeholders
          when 0 then  a

          # add a few placeholders before the 1st day          
          else Array.new(6 - wday) + a
        end

        r

      end

      pxmonth.xslt = 'month_calendar.xsl'
      pxmonth.css_layout = 'month_layout.css'
      pxmonth.css_style = 'month.css'
      pxmonth
    end

  end
  def month_day()
  end

  def months
    @polyrex.records
  end
  
  def parse_events(list)    
    
    polyrex = Polyrex.new('events/dayx[date, title]/entryx[start_time, end_time,' + \
      ' duration, title]')

    polyrex.format_masks[1] = '([!start_time] \([!duration]\) [!title]|' +  \
      '[!start_time]-[!end_time] [!title]|' + \
      '[!start_time] [!title])'

    polyrex.parse(list)

    self.import_events polyrex
    # for testing only
    #polyrex
  end

  def save(filename='polyrex.xml')
    @polyrex.save filename
  end
  
  def this_week()

    dt = DateTime.now
    days = @polyrex.records[dt.month-1].day

    r = days.find {|day| day.date.cweek == dt.cweek }    
    pxweek = PolyrexObjects::Week.new
    pxweek.mon = Date::MONTHNAMES[dt.month]
    pxweek.no = dt.cweek.to_s
    pxweek.label = ''
    days[days.index(r),7].each{|day| pxweek.add day }

    pxweek
  end

  def this_month()
    self.month(DateTime.now.month)
  end

  def import_bankholidays(dynarex)
    import_dynarex(dynarex, :bankholiday=)
  end

  def import_recurring_events(dynarex)

    title = dynarex.summary[:event_title]
    cc = ChronicCron.new dynarex.summary[:description].split(/,/,2).first
    time_start= "%s:%02d" % cc.to_time.to_a.values_at(2,1)

    dynarex.flat_records.each do |event|

      dt = DateTime.parse(event[:date])
      m, d = dt.month, dt.day
      record = {title: title, time_start: time_start}

      @polyrex.records[m-1].day[d-1].create.entry record
    end
  end

  def import_sunrise_times(dynarex)
    import_suntimes dynarex, :sunrise=
  end

  def import_sunset_times(dynarex)
    import_suntimes dynarex, :sunset=
  end
  
  private

  def import_suntimes(dynarex, event_type=:sunrise=)

    dynarex.flat_records.each do |event|

      dt = DateTime.parse(event[:date])
      m, d = dt.month, dt.day
      @polyrex.records[m-1].day[d-1].method(event_type).call event[:time]
    end
  end
  
  def import_dynarex(dynarex, daytype=:event=)

    dynarex.flat_records.each do |event|

      dt = DateTime.parse(event[:date])
      m, d = dt.month, dt.day

      event_label = case daytype
        when :event=
          "%s at %s" % [event[:title], dt.strftime("%H:%M%p")]
        else
          "%s" % event[:title]
      end

      @polyrex.records[m-1].day[d-1].method(daytype).call event_label
    end
  end

  def import_polyrex(polyrex)

    polyrex.records.each do |day|

      sd = day.date.strftime("%Y-%b-%d ")
      m,w,i = @day[d1]

      cal_day = @polyrex.records[m].week[w].day[i]
    
      cal_day.event = day.title

      if day.records.length > 0 then

        raw_entries = day.records

        entries = raw_entries.inject({}) do |r,entry|

          start_time = entry.start_time  

          if entry.end_time.length > 0 then

            end_time = entry.end_time
            duration = ChronicDuration.output(Time.parse(sd + end_time) \
              - Time.parse(sd + start_time))
          else

            if entry.duration.length > 0 then
              duration = entry.duration
            else
              duration = '10 mins'
            end

            end_time = (Time.parse(sd + start_time) + ChronicDuration.parse(duration))\
              .strftime("%H:%M")
          end

          r.merge!(start_time => {time_start: start_time, time_end: end_time, \
            duration: duration, title: entry.title})

        end

        seconds = entries.keys.map{|x| Time.parse(x) - Time.parse('08:00')}

        unless d1.saturday? or d1.sunday? then
          rows = slotted_sort(seconds).map do |x| 
            (Time.parse('08:00') + x.to_i).strftime("%H:%M") if x
          end
        else
          rows = entries.keys
        end

        rows.each do |row|
          create = cal_day.create
          create.id = @id
          create.entry entries[row] || {}
        end        

      end  
    end 
    
  end

  def make_month(m)

    cal_month = @polyrex.records[m-1]
    days_in_month = cal_month.records
    pxmonth = cal_month.clone
    pxmonth.records.each(&:delete)

    a = days_in_month

    i = a[0].wday

    a2 = yield(a, i)

    a2.each_slice(7) do |days_in_week|

      pxweek = PolyrexObjects::Week.new

      days_in_week.each do |day| 

        new_day = day ? day.deep_clone : PolyrexObjects::Day.new
        pxweek.add new_day
      end

      pxmonth.add pxweek
    end

    week1 = pxmonth.week[0]

    other_days = week1.day.select{|day| day.sdate.empty? }
    start_date = week1.day[other_days.length].date

    other_days.reverse.each.with_index do |day, i|
      day.sdate = (start_date - (i+1)).strftime("%Y %b %d")
      day.xday = day.date.day.to_s
    end

    last_week = pxmonth.week[-1]

    gap = 7 - last_week.records.length
    end_date = last_week.day.last.date

    gap.times do |i|

      day = PolyrexObjects::Day.new
      day.sdate = (end_date + (i+1)).strftime("%Y %b %d")
      day.xday = day.date.day.to_s
      last_week.add day
    end

    pxmonth
  end
    
  def ordinal(val)
    (10...20).include?(val) ? \
      'th' : %w{ th st nd rd th th th th th th }[val % 10] 
  end

  def slotted_sort(a)

    upper = 36000 # upper slot value
    slot_width = 9000 # 2.5 hours
    max_slots = 3  

    b = a.reverse.inject([]) do |r,x|

      upper ||= 10;  i ||= 0
      diff = upper - x

      if diff >= slot_width and (i + a.length) < max_slots then
        r << nil
        i += 1
        upper -= slot_width
        redo
      else
        upper -= slot_width if x <= upper
        r << x
      end
    end

    a = b.+([nil] * max_slots).take(max_slots).reverse
  end
  

end