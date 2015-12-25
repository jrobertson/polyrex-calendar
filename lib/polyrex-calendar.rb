#!/usr/bin/env ruby

# file: polyrex-calendar.rb

require 'polyrex_calendarbase'


module LIBRARY

  def fetch_filepath(filename)

    lib = File.dirname(__FILE__)
    File.join(lib,'..','stylesheet',filename)
  end
  
  def fetch_file(filename)

    filepath = fetch_filepath filename
    read filepath
  end
  

  def generate_webpage(xml, xsl)
    
    # transform the xml to html
    doc = Nokogiri::XML(xml)
    xslt  = Nokogiri::XSLT(xsl)
    xslt.transform(doc).to_s   
  end

  def read(s)
    RXFHelper.read(s).first
  end
end

class PolyrexObjects
  
  class Month
        
    def wk(n)
      self.records[n-1]        
    end      
    
    def to_webpage()
      
      month_xsl = fetch_file self.xslt
      month_layout_css = fetch_file self.css_layout
      month_css = fetch_file self.css_style
            
      File.write 'lmonth.xsl', month_xsl
      doc = self.to_doc
      
      xslt_filename = File.basename self.xslt
      
      doc.instructions << [
        'xml-stylesheet',
          "title='XSL_formatting' type='text/xsl' href='lmonth.xsl'"]
      
      # add a css selector for the current day
      highlight_today()     
      
      
      File.write 'month.xml', doc.xml(pretty: true)
      
      html = generate_webpage doc.xml, month_xsl
      {self.title.downcase[0..2] + '_calendar.html' => html,
          self.css_layout => month_layout_css, self.css_style => month_css}
    end    
  end

  class Week
    
    def to_webpage()

      week_xsl        = fetch_file 'week_calendar.xsl'
      week_layout_css = fetch_file 'week_layout.css'
      week_css        = fetch_file 'week.css'

      File.write 'self.xml', self.to_xml(pretty: true)
      File.write 'week.xsl', week_xsl
      #html = Rexslt.new(week_xsl, self.to_xml).to_xml
      #html = xsltproc 'week_calendar.xsl', self.to_xml

      # add a css selector for the current day
      highlight_today()


      html = generate_webpage self.to_xml, week_xsl
      {'week' + self.no + '_planner.html' => html, 'week_layout.css' => week_layout_css, \
      'week.css' => week_css}
    end  
  end


end

class PolyrexCalendar < PolyrexCalendarBase
  
  def initialize(calendar_file=nil, options={})

    super(calendar_file, options)

    @xsl = fetch_file 'calendar.xsl'
    @css = fetch_file 'layout.css'
       
  end

  def inspect()
     %Q(=> #<PolyrexCalendar:#{self.object_id} @id="#{@id}", @year="#{@year}">)
  end

  def kitchen_planner()

    px = @calendar

    # add a css selector for the current day
    date = DateTime.now.strftime("%Y-%b-%d")
    e = px.element("records/month/records/day/summary[sdate='#{date}']")
    e.attributes[:class] = 'selected' if e

    px.xslt = 'kplanner.xsl'
    px.css_layout = 'monthday_layout.css'
    px.css_style = 'monthday.css'
    px.filename = @year + '-kitchen-planner.html'

    px
    
  end

  def year_planner()

    px = Calendar.new(@visual_schema, id_counter: @id)
    px.summary.year = @year

    (1..12).each {|n| px.add self.month(n, monday_week: true) }

    # add a css selector for the current day
    date = DateTime.now.strftime("%Y-%b-%d")
    e = px.element("records/month/records/week/records/day/" \
                                              + "summary[sdate='#{date}']")
    e.attributes[:class] = 'selected' if e

    px.xslt = self.fetch_filepath('calendar.xsl')
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
          else Array.new(wday) + a
        end

        r

      end

      pxmonth.xslt = 'lmonth.xsl'
      pxmonth.css_layout = 'month_layout.css'
      pxmonth.css_style = 'month.css'
      pxmonth
    end

  end
    
  def this_week()

    dt = DateTime.now
    days = @calendar.month(dt.month).day

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
  
  private


  def make_month(m)
        
    cal_month = @calendar.month(m)
    
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

end