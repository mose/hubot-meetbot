# Description:
#   handles formatting of meeting minutes
#
# Author:
#   mose

moment = require 'moment-timezone'
util = require 'util'
Promise = require 'bluebird'

class Format
  constructor: (env) ->
    @env = env
    @tz = @env.MEETBOT_TZ or 'UTC'

  markdown: (data) ->
    return new Promise (res, err) =>
      back = ''
      if data.topic
        back += "#{data.topic}\n"
      else
        back += 'Metting of ' + moment.tz(data.start, @tz).format('YYYY-MM-DD HH:mm') + '\n'
      back += '================================\n\n'
      unless data.end
        data.end = moment().utc().format()
      back += @fromto(data.start, data.end)
      for point in ['info', 'agreed', 'action', 'link']
        back += @point(data, point)
      back += 'Full log\n'
      back += '---------'
      namewidth = data.logs.reduce (acc, line) ->
        acc = line.user.length if line.user.length > acc
        acc
      , 0
      for line in data.logs
        back += util.format '\n    %s %s : %s',
          moment.tz(line.time, @tz).format('HH:mm'),
          @pad(line.user, namewidth + 2),
          line.text
      back += '\n\n*EOF*\n'
      res back

  point: (data, label) ->
    back = ''
    if data[label].length > 0
      back += "#{label[0].toUpperCase() + label.substr(1)}\n"
      back += Array(label.length + 1).join('-') + '\n'
      for line in data[label]
        back += "- #{line}\n"
      back += '\n'
    back

  fromto: (start, end) ->
    timespent = moment(end).diff(start, 'minutes')
    if moment.tz(start, @tz).format('YYYY-MM-DD') is moment.tz(end, @tz).format('YYYY-MM-DD')
      util.format('On %s from %s to %s (%s minutes)\n\n',
        moment.tz(start, @tz).format('YYYY-MM-DD'),
        moment.tz(start, @tz).format('HH:mm'),
        moment.tz(end, @tz).format('HH:mm'),
        timespent
        )
    else
      util.format('From %s to %s (%s minutes)\n\n',
        moment.tz(start, @tz).format('YYYY-MM-DD HH:mm'),
        moment.tz(end, @tz).format('YYYY-MM-DD HH:mm'),
        timespent
        )

  pad: (string, targetLength) ->
    targetLength = targetLength >> 0
    padString = ' '
    targetLength = targetLength - string.length
    padString += Array(targetLength / padString.length).join(padString)
    padString.slice(0, targetLength) + string



module.exports = Format
