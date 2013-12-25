# Create a Yearly, Monthly, or Weekly Calendar

## Example

    require 'polyrex-calendar' 

    dates =<<EOF
    <?polyrex schema="events/dayx[date, title]/entryx[start_time, end_time, duration, title]" ?>
    26-Dec-2013
      11:00 (1 hour) Review application
    27-Dec-2013 14:50 Dentist  
      14:50 Dentist
      15:50 Shopping
    29-Dec-2013 14:00 Car trip xyz
      14:00 Car trip xyz
    EOF

    px = Polyrex.new 
    px.format_masks[1] = '([!start_time] \([!duration]\) [!title]|' +  \
      '[!start_time]-[!end_time] [!title]|' + \
      '[!start_time] [!title])'

    px.import(dates)

    cal = PolyrexCalendar.new
    cal.import! px

    h = cal.this_month.to_webpage
    h.each {|filename, buffer| File.open(filename, 'w'){|f| f.write buffer}}

    h = cal.this_week.to_webpage
    h.each {|filename, buffer| File.open(filename, 'w'){|f| f.write buffer}}

    h = cal.to_webpage
    h.each {|filename, buffer| File.open(filename, 'w'){|f| f.write buffer}}

## Screenshots

### Monthly calendar

![monthly calendar screenshot](http://www.jamesrobertson.eu/images/2013/dec/24/dec-monthly-calendar-screenshot.png)

### Weekly calendar

![weekly calendar screenshot](http://www.jamesrobertson.eu/images/2013/dec/24/dec-weekly-calendar-screenshot.png)

### Yearly calendar

![yearly calendar screenshot](http://www.jamesrobertson.eu/images/2013/dec/24/dec-yearly-calendar-screenshot.png)

polyrexcalendar calendar yearly monthly weekly
