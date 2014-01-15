#!/usr/bin/env ruby

# file: polyrex-calendar.rb

require 'polyrex'
require 'date'
require 'nokogiri'
require 'chronic_duration'

MINUTE = 60
HOUR = MINUTE * 60
DAY = HOUR * 24
WEEK = DAY * 7
MONTH = DAY * 30


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

class PolyrexCalendar
  include LIBRARY

  attr_accessor :xsl, :css, :polyrex, :month_xsl, :month_css
  attr_reader :day
  
  def initialize(calendar_file=nil, options={})

    opts = {year: Time.now.year.to_s}.merge(options)
    @year = opts[:year]

    @schema = 'calendar[year]/month[no,title,year]/' + \
        'week[no, rel_no, mon, label]/day[wday, xday, title, event, date, ' + \
        'ordinal, overlap, bankholiday]/' + \
        'entry[time_start, time_end, duration, title]'

    if calendar_file then
      @polyrex = Polyrex.new calendar_file
      @id = @polyrex.id_counter

      @day = {}
      @polyrex.records.each_with_index do |month,m|
        month.records.each_with_index do |weeks,w| 
          weeks.records.each_with_index do|d,i| 
            @day[Date.parse(d.date)] = [m,w,i]
          end 
        end
      end

    else
      @id = '1'
      generate_calendar
    end

    @xsl = fetch_file 'calendar.xsl'
    @css = fetch_file 'layout.css'

    Polyrex.class_eval do
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

    PolyrexObjects::Month.class_eval do
      include LIBRARY

      attr_accessor :xslt, :css_layout, :css_style

      def inspect()
        "#<PolyrexObjects::Month:%s" % __id__
      end

      def to_webpage()

        month_xsl        = fetch_file self.xslt
        month_layout_css = fetch_file self.css_layout
        month_css        = fetch_file self.css_style

        File.open('self.xml','w'){|f| f.write self.to_xml pretty: true}
        File.open('month.xsl','w'){|f| f.write month_xsl }
        #html = Rexslt.new(month_xsl, self.to_xml).to_xml

        # add a css selector for the current day
        date = Time.now.strftime("%Y-%b-%d")
        doc = Rexle.new self.to_xml
        e = doc.root.element("records/week/records/day/summary[date='#{date}']")
        e.add Rexle::Element.new('css_style').add_text('selected')

        html = generate_webpage doc.xml, month_xsl
        {self.title.downcase[0..2] + '_calendar.html' => html, 
          self.css_layout => month_layout_css, self.css_style => month_css}
      end      
      
      def wk(n)
        self.records[n-1]        
      end      
    end
    
    PolyrexObjects::Week.class_eval do
      include LIBRARY

      def inspect()
        "#<PolyrexObjects::Week:%s" % __id__
      end
      
      def to_webpage()

        week_xsl        = fetch_file 'week_calendar.xsl'
        week_layout_css = fetch_file 'week_layout.css'
        week_css        = fetch_file 'week.css'

        File.open('self.xml','w'){|f| f.write self.to_xml pretty: true}
        File.open('week.xsl','w'){|f| f.write week_xsl }        
        #html = Rexslt.new(week_xsl, self.to_xml).to_xml
        #html = xsltproc 'week_calendar.xsl', self.to_xml

        # add a css selector for the current day
        date = Time.now.strftime("%Y-%b-%d")
        doc = Rexle.new self.to_xml
        e = doc.root.element("records/day/summary[date='#{date}']")

        e.add Rexle::Element.new('css_style').add_text('selected')

        html = generate_webpage doc.xml, week_xsl
        {'week' + self.no + '_planner.html' => html, 'week_layout.css' => week_layout_css, \
         'week.css' => week_css}
      end
      
    end
    
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

    px = Polyrex.new(@schema, id_counter: @id)
    px.summary.year = @year
    (1..12).each {|n| px.add self.month(n, strict: true) }

    px.xslt = 'kplanner.xsl'
    px.css_layout = 'monthday_layout.css'
    px.css_style = 'monthday.css'
    px.filename = summary.year.to_s + '-kitchen-planner.html'

    px
    
  end

  def year_planner()

    px = Polyrex.new(@schema, id_counter: @id)
    px.summary.year = @year
    (1..12).each {|n| px.add self.month(n, strict: true) }

    px.xslt = 'calendar.xsl'
    px.css_layout = 'layout.css'
    px.css_style = 'year.css'
    px.filename = px.summary.year.to_s + '-planner.html'

    px
    
  end

  def month(m, strict: false)

    cal_month = @polyrex.records[m-1]

    if strict == true then

      days_in_month = cal_month.xpath('records/week/records/.')\
        .select {|x| Date.parse(x.text('summary/date')).month == m}

      doc_month = Rexle.new cal_month.to_xml
      records = doc_month.root.element 'records'
      records.insert_before Rexle::Element.new('records')

      records.delete

      h = PolyrexObjects.new(@schema).to_h
      pxmonth = h['Month'].new doc_month.root

      a = days_in_month
      i = a[0].text('summary/wday').to_i

      a2 = if i > 1 then
        Array.new(i - 1) + a
      elsif i < 1 then
        Array.new(6) + a
      else
        a
      end

      a2.each_slice(7) do |days_in_week|

        pxweek = h['Week'].new Rexle.new('<week><summary/><records/></week>').root

        days_in_week.each do |day|

          day = Rexle.new("<day><summary/><records/></day>") unless day
          pxweek.add h['Day'].new(day.root)
        end

        pxmonth.add pxweek
      end

      pxmonth.xslt = 'monthday_calendar.xsl'
      pxmonth.css_layout = 'monthday_layout.css'
      pxmonth.css_style = 'monthday.css'
      pxmonth

    else
      cal_month.xslt = 'month_calendar.xsl'
      cal_month.css_layout = 'month_layout.css'
      cal_month.css_style = 'month.css'

      cal_month
    end

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

    m = DateTime.now.month
    thisweek = self.month(m).records.find do |week|
      now = DateTime.now
      #week_no = now.cwday < 7 ? now.cweek - 1: now.cweek
      week_no = now.cweek
      week.no == week_no.to_s
    end

    day = (Time.now - DAY * (Time.now.wday - 1)).day

    days_in_week = self.this_month.xpath('records/week/records/.')\
      .select {|x| x.text('summary/xday').to_i >= day}\
      .take 7

    doc_week = Rexle.new thisweek.to_xml
    records = doc_week.root.element 'records'
    records.insert_before Rexle::Element.new('records')

    records.delete

    week = doc_week.root.element 'records'
    days_in_week.each {|day| week.add day }
    PolyrexObjects.new(@schema).to_h['Week'].new doc_week.root

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
      m,w,i = @day[dt.to_date]      
      record = {title: title, time_start: time_start}

      @polyrex.records[m].week[w].day[i].create.entry record
    end
  end
  
  private
  
  def import_dynarex(dynarex, daytype=:event=)

    dynarex.flat_records.each do |event|

      dt = DateTime.parse(event[:date])
      m,w,i = @day[dt.to_date]      
      @polyrex.records[m].week[w].day[i].method(daytype).call event[:title]
    end
  end

  def import_polyrex(polyrex)

    polyrex.records.each do |day|

      d1 = Date.parse(day.date)
      sd = d1.strftime("%Y-%b-%d ")
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
  

  def generate_calendar()

    a = (Date.parse(@year + '-01-01')...Date.parse(@year.succ + '-01-01')).to_a

    months = a.group_by(&:month).map do |key, month|

      i = month.index(month.detect{|x| x.wday == 0})
      unless i == 0 then
        weeks = [month.slice!(0,i)] + month.each_slice(7).to_a
        (weeks[0] = ([nil] * 6 + weeks[0]).slice(-7..-1))
      else
        weeks = month.each_slice(7).to_a
      end

      weeks[-1] = (weeks[-1] + [nil] * 6 ).slice(0,7) if weeks[-1].length < 7 

      weeks
    end

    @day = {}
    months.each_with_index do |month,m|
      month.each_with_index do |weeks,w| 
        weeks.each_with_index{|d,i| @day[d] = [m,w,i]} 
      end
    end

    @a = months

    @polyrex = Polyrex.new(@schema, id_counter: @id)
    year_start = months[0][0][-1]
    @polyrex.summary.year = @year
    old_year_week = (year_start - 7).cweek

    week_i = 1

    months.each_with_index do |month,i| 
      month_name = Date::MONTHNAMES[i+1]
      @polyrex.create.month no: (i+1).to_s, title: month_name, year: @year do |create|
        month.each_with_index do |week,j|

          # jr241213 week_s = (week_i == 0 ? old_year_week : week_i).to_s
          week_s = week_i.to_s
          
          if week[0].nil? then
            label = Date::MONTHNAMES[(i > 0 ? i : 12)] + " - " + month_name
          end
          
          if week[-1].nil? then
            label = month_name + " - " + Date::MONTHNAMES[(i+2 <= 12 ? i+2 : 1)] 
          end          
          

          week_record = {
            rel_no: (j+1).to_s,
            no: week_s, 
            mon: month_name, 
            label: label
          }
          
          create.week week_record do |create|
            week.each_with_index do |day, k|
                    
              # if it's a day in the month then ...
              if day then
                x = day
                week_i += 1 if x.wday == 6
                h = {wday: x.wday.to_s, xday: x.day.to_s, \
                  title: Date::DAYNAMES[k], date: x.strftime("%Y-%b-%d"), \
                  ordinal: ordinal(x.day.to_i)}
              else
                #if blank find the nearest date in the week and calculate this date
                # check right and if nothing then it's at the end of the month
                x = week[-1] ? (week[-1] - (7-(k+1))) : week[0] + k
                h = {wday: x.wday.to_s, xday: x.day.to_s, \
                  title: Date::DAYNAMES[k], date: x.strftime("%Y-%b-%d"), \
                  ordinal: ordinal(x.day.to_i), overlap: 'true'}
              end

              create.day(h)
            end
          end
        end
      end
    end

  end
  
  def ordinal
    ( (10...20).include?(self) ? 'th' : %w{ th st nd rd th th th th th th }[self % 10] )
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