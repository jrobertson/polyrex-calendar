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

class Numeric
  def ordinal
    ( (10...20).include?(self) ? 'th' : %w{ th st nd rd th th th th th th }[self % 10] )
  end
end

class PolyrexCalendar

  attr_accessor :xsl, :css, :polyrex, :month_xsl, :month_css
  
  def initialize(calendar_file=nil, options={})

    @id = '1'
    if calendar_file then
      @polyrex = Polyrex.new calendar_file
      @id = @polyrex.id_counter
    else
      @id = '1'
    end
    
    lib = File.dirname(__FILE__)
    opts = {calendar_xsl: lib + '/calendar.xsl'
            }.merge(options)
    
    year = opts[:year]
    @year = year ? year.to_s : Time.now.year.to_s
    generate_calendar

    @xsl = File.read lib + '/calendar.xsl'
    @css = File.read lib + '/layout.css'
    
    PolyrexObjects::Month.class_eval do

      def inspect()
        "#<PolyrexObjects::Month:%s" % __id__
      end

      def to_webpage()
        lib = File.dirname(__FILE__)

        month_xsl = File.read lib + '/month_calendar.xsl'
        month_layout_css = File.read lib + '/month_layout.css'
        month_css = File.read lib + '/month.css'

        File.open('self.xml','w'){|f| f.write self.to_xml pretty: true}
        File.open('month.xsl','w'){|f| f.write month_xsl }
        #html = Rexslt.new(month_xsl, self.to_xml).to_xml

        # add a css selector for the current day
        date = Time.now.strftime("%Y-%b-%d")
        doc = Rexle.new self.to_xml
        e = doc.root.element("records/week/records/day/summary[date='#{date}']")
        e.add Rexle::Element.new('css_style').add_text('selected')

        xslt  = Nokogiri::XSLT(month_xsl)
        html = xslt.transform(Nokogiri::XML(doc.xml)).to_s
        {self.title.downcase[0..2] + '_calendar.html' => html, 
          'month_layout.css' => month_layout_css, 'month.css' => month_css}

      end      
      
      def wk(n)
        self.records[n-1]        
      end      
    end
    
    PolyrexObjects::Week.class_eval do

      def inspect()
        "#<PolyrexObjects::Week:%s" % __id__
      end
      
      def to_webpage()
        
        lib = File.dirname(__FILE__)
        
        week_xsl = File.read lib + '/week_calendar.xsl'
        week_layout_css = File.read lib + '/week_layout.css'
        week_css = File.read lib + '/week.css'
        
        File.open('self.xml','w'){|f| f.write self.to_xml pretty: true}
        File.open('week.xsl','w'){|f| f.write week_xsl }        
        #html = Rexslt.new(week_xsl, self.to_xml).to_xml
        #html = xsltproc 'week_calendar.xsl', self.to_xml
        
        # add a css selector for the current day
        date = Time.now.strftime("%Y-%b-%d")
        doc = Rexle.new self.to_xml
        e = doc.root.element("records/day/summary[date='#{date}']")

        e.add Rexle::Element.new('css_style').add_text('selected')        
        xslt  = Nokogiri::XSLT(week_xsl)
        html = xslt.transform(Nokogiri::XML(doc.xml)).to_s
        
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

  def to_webpage()
    # jr2441213 html = Rexslt.new(@xsl, @polyrex.to_xml).to_xml   
    xslt  = Nokogiri::XSLT(@xsl)
    html = xslt.transform(Nokogiri::XML(@polyrex.to_xml)).to_s
    {'calendar.html' => html, 'layout.css' => @css}
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

  def month(m)
    @polyrex.records[m-1]
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
    @polyrex.save filenameS
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
  
  private
  
  def import_dynarex(dynarex, daytype=:event=)

    dynarex.flat_records.each do |event|

      date = Date.parse(event[:date])
      m,w,i = @day[date]    
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
    @schema = 'calendar[year]/month[no,title,year]/week[no, rel_no, mon, label]/' + \
        'day[wday, xday, title, event, date, ordinal, overlap, bankholiday]/' + \
        'entry[time_start, time_end, duration, title]'
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
                  ordinal: x.day.to_i.ordinal}
              else
                #if blank find the nearest date in the week and calculate this date
                # check right and if nothing then it's at the end of the month
                x = week[-1] ? (week[-1] - (7-(k+1))) : week[0] + k
                h = {wday: x.wday.to_s, xday: x.day.to_s, \
                  title: Date::DAYNAMES[k], date: x.strftime("%Y-%b-%d"), \
                  ordinal: x.day.to_i.ordinal, overlap: 'true'}
              end

              create.day(h)
            end
          end
        end
      end
    end

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
  
  def generate_webpage(xml, xsl)
    
    # transform the xml to html
    doc = Nokogiri::XML(xml)
    xslt  = Nokogiri::XSLT(xsl)
    html =  xslt.transform(doc).to_xml    
    html

  end
end