# Adding entries to a Polyrex Calendar

There are various ways to add an entry to a Polyrex Calendar, either from a Dynarex, or Polyrex document, or from direct access to the day object.

## Creating a Polyrex Calendar

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new
    pc.save 'polyrex.xml'

## Adding an individual event for a specific day

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new 'polyrex.xml'

    # select January 25th; note: The index for the month and day starts at 0
    pc.records[0].day[24].event = "Doctor's appointment at 14:30"
    pc.save

## Adding events from a Dynarex document

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new 'polyrex.xml'

    s =<<EOF
    &lt;?dynarex schema="entries[title,tags]/entry(date,title,reminder,recurring)"?&gt;
    title: Events 2014
    tags: events 2014 dates appointments schedule
    --+

    date: 21 Jan @ 12:30
    title: building 44
    reminder: 2 hours before

    date: 27 Feb @ 14:20
    title: Dentist 6 month checkup
    reminder: 2 hours before
    EOF

    dx = Dynarex.new
    dx.import s

    pc.import! dx
    pc.save

## Adding events from a Polyrex document

In this example not only is an event added, entries relating to that day can also be stored.

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new 'polyrex.xml'

    dates =<<EOF
    &lt;?polyrex schema="events/day[sdate, title]/entry[start_time, end_time, duration, title]" ?&gt;
    26-Feb-2014
      11:00 (1 hour) Review application
    27-Feb-2014 14:50 Dentist  
      14:50 Dentist
      15:50 Shopping
    28-Feb-2014 14:00 Car trip xyz
      14:00 Car trip xyz
    EOF

    px = Polyrex.new
    px.format_masks[1] = '([!start_time] \([!duration]\) [!title]|' +  \
      '[!start_time]-[!end_time] [!title]|' + \
      '[!start_time] [!title])'

    px.import(dates)
    pc.import_events px

    pc.save

## Displaying the various calendar formats

The calendar can generate various calendar formats including, monthly, weekly, yearly, and monthly planner as show below:

### Monthly calendar

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new 'polyrex.xml'
    h = pc.this_month.to_webpage

    # saves the HTML, and CSS to files on disk
    h.each{|filename, buffer| File.write filename, buffer}

![monthly calendar screenshot](http://www.jamesrobertson.eu/images/2014/jan/23/monthly-calendar.png)

### Weekly calendar

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new 'polyrex.xml'
    h = pc.this_week.to_webpage
    h.each{|filename, buffer| File.write filename, buffer}

![weekly planner screenshot](http://www.jamesrobertson.eu/images/2014/jan/23/weekly-planner.png)

### Yearly calendar

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new 'polyrex.xml'
    h = pc.to_webpage
    h.each{|filename, buffer| File.write filename, buffer}

![yearly planner screenshot](http://www.jamesrobertson.eu/images/2014/jan/23/yearly-planner.png)

### Kitchen monthly planner

    require 'polyrex-calendar'

    pc = PolyrexCalendar.new 'polyrex.xml'
    h = pc.kitchen_planner.to_webpage
    h.each{|filename, buffer| File.write filename, buffer}

![kitchen monthly planner screenshot](http://www.jamesrobertson.eu/images/2014/jan/23/kitchen-monthly-planner.png)

## Applying a custom XSLT stylesheet for the yearly calendar

    require 'polyrex-calendar'

    Dir.chdir '/home/james/jamesrobertson.eu/calendar/'
    cal = PolyrexCalendar.new 'polyrex.xml'

    k = cal.year_planner
    k.xslt = '/home/james/jamesrobertson.eu/calendar/public_calendar.xsl'
    h = k.to_webpage

In this example I removed the side events from the page as show below:

![screenshot of the yearly calendar](http://www.jamesrobertson.eu/images/2014/jul/06/yearly-planner.png)

## Resources

* [jrobertson/polyrex-calendar](https://github.com/jrobertson/polyrex-calendar)


