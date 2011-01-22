#!/usr/bin/ruby

# file: polyrex-calendar.rb

require 'polyrex'
require 'date'
require 'nokogiri'

class PolyrexCalendar

  def initialize(year=nil)
    @year = year ? year : Time.now.year
    generate_calendar
  end

  def to_a()
    @a
  end

  def to_xml()
    @xml
  end

  def to_webpage()
    
    # transform the xml to html

    doc = Nokogiri::XML(@xml)
    xslt  = Nokogiri::XSLT(open('calendar.xsl','r'))
    html =  xslt.transform(doc).to_xml
    css = File.open('layout.css','r').read
    
    {'calendar.html' => html, 'layout.css' => css}
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

    @a = months

    calendar = Polyrex.new('calendar[year]/month[no,name]/week[no, rel_no]/day[wday, xday, name, event]')
    year_start = months[0][0][-1]
    calendar.summary.year = year_start.year.to_s
    old_year_week = year_start.prev_day.cweek

    week_i = 0

    months.each_with_index do |month,i| 

      calendar.create.month no: (i+1).to_s, name: Date::MONTHNAMES[i+1] do |create|
        month.each_with_index do |week,j|

          week_s = (week_i == 0 ? old_year_week : week_i).to_s
          create.week rel_no: (j+1).to_s, no: week_s do |create|
            week.each_with_index do |x,k|

              if x then
                week_i += 1 if x.wday == 6
                h = {wday: x.wday.to_s, xday: x.day.to_s, name: Date::DAYNAMES[k]}
              else
                h = {}
              end
              create.day(h)
            end
          end
        end
      end
    end

    @xml = calendar.to_xml pretty: true

  end
end
