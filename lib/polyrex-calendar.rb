#!/usr/bin/ruby

# file: polyrex-calendar.rb

require 'polyrex'
require 'date'
require 'nokogiri'

class PolyrexCalendar

  attr_accessor :xsl, :css, :polyrex, :month_xsl, :month_css
  
  def initialize(year=nil)
    @year = year ? year : Time.now.year
    generate_calendar
    lib = File.dirname(__FILE__)
    @xsl = File.open(lib + '/calendar.xsl','r').read
    @css = File.open(lib + '/layout.css','r').read
    @month_xsl = File.open(lib + '/month_calendar.xsl','r').read
    @month_css = File.open(lib + '/month_layout.css','r').read

    PolyrexObjects::Month.class_eval {
      def to_webpage()
        lib = File.dirname(__FILE__)
        month_xsl = File.open(lib + '/month_calendar.xsl','r').read
        month_css = File.open(lib + '/month_layout.css','r').read
        doc = Nokogiri::XML(self.to_xml);  xslt  = Nokogiri::XSLT(month_xsl)
        html =  xslt.transform(doc).to_xml    
        {self.name.downcase[0..2] + '_calendar.html' => html, 'month_layout.css' => month_css}
      end
    }

  end

  def to_a()
    @a
  end

  def to_xml()
    @polyrex.to_xml pretty: true
  end

  def to_webpage()    
    html = generate_webpage(@polyrex.to_xml, @xsl)    
    {'calendar.html' => html, 'layout.css' => @css}
  end  

  def import_events(dynarex)
    dynarex.flat_records.each do |event|
      m,w,i = @day[Date.parse(event[:date])]
      @polyrex.records[m].week[w].day[i].event = event[:title]
    end
    self
  end

  def month(m)
    @polyrex.records[m-1]
  end

  def months
    @polyrex.records
  end

  private

  def generate_calendar()

    d = Date.parse(@year.to_s + '-Jan-01')
    a = []
    (a << d; d += 1) while d.year == Time.now.year

    months = a.group_by(&:month).map do |key, month|
      i = month.index(month.detect{|x| x.wday == 0})
      unless i == 0 then
        weeks = [month.slice!(0,i)] + month.each_slice(7).to_a
        (weeks[0] = ([nil] * 6 + weeks[0]).slice(-7..-1))
      else
        weeks = month.each_slice(7).to_a
      end

      weeks
    end

    @day = {}
    months.each_with_index do |month,m|
      month.each_with_index do |weeks,w| 
        weeks.each_with_index{|d,i| @day[d] = [m,w,i]} 
      end
    end

    @a = months

    @polyrex = Polyrex.new('calendar[year]/month[no,name,year]/week[no, rel_no]/day[wday, xday, name, event, date]')
    year_start = months[0][0][-1]
    @polyrex.summary.year = @year
    old_year_week = (year_start - 7).cweek

    week_i = 0

    months.each_with_index do |month,i| 

      @polyrex.create.month no: (i+1).to_s, name: Date::MONTHNAMES[i+1], year: @year do |create|
        month.each_with_index do |week,j|

          week_s = (week_i == 0 ? old_year_week : week_i).to_s
          create.week rel_no: (j+1).to_s, no: week_s do |create|
            week.each_with_index do |x,k|

              if x then
                week_i += 1 if x.wday == 6
                h = {wday: x.wday.to_s, xday: x.day.to_s, name: Date::DAYNAMES[k], \
                  date: x.strftime("%Y-%b-%d")}
              else
                #if blank find the nearest date in the week and calculate this date
                # check right and if nothing then it'sat the end of the month
                h = {}
              end
              create.day(h)
            end
          end
        end
      end
    end

  end

  def generate_webpage(xml, xsl)
    
    # transform the xml to html
    doc = Nokogiri::XML(xml)
    xslt  = Nokogiri::XSLT(xsl)
    html =  xslt.transform(doc).to_xml    
    html

  end
end
