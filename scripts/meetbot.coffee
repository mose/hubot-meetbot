# Description:
#   a meeting manager ala meetbot
#
# Commands:
#   hubot meet version
#   hubot meet
#   hubot meet start [<label>]
#   hubot meet start
#   hubot meet topic <topic>
#   hubot meet info <text>
#   hubot meet action <text>
#
# Configuration:
#   HUBOT_MEETBOT_NOAUTH
#   HUBOT_MEETBOT_AUTH_GROUP
#
# Author:
#   mose

Meetbot = require '../lib/meetbotlib'
path    = require 'path'

module.exports = (robot) ->

  meetbot = new Meetbot robot, process.env
  robot.meetbot = meetbot

#   hubot meet version
  robot.respond /meet version\s*$/, (res) ->
    pkg = require path.join __dirname, '..', 'package.json'
    res.send "hubot-meetbot is version #{pkg.version}"
    res.finish()

#   hubot meet
  robot.respond /meet\s*$/, (res) ->
    meetbot.findMeeting(res.envelope.room ? res.envelope.reply_to)
    .then (label) ->
      if label
        res.send "A meeting is in progress, named `#{label}`."
      else
        res.send 'There is no meeting going on right now on this channel.'
    .catch (e) ->
      res.send e
    res.finish()

#   hubot meet start [<label>]
  robot.respond /(?:startmeeting|meet (?:start|on))\s*(.*)?$/, (res) ->
    label = res.match[1]
    meetbot.withPermission(res.envelope.user)
    .then ->
      meetbot.startMeeting(res.envelope.room, label)
    .then (label) ->
      res.send "Meeting `#{label}` is now open. All discussions will now be recorded."
    .catch (e) ->
      res.send e
    res.finish()

#   hubot meet topic <topic>
  robot.respond /meet topic\s*(.*)?$/, (res) ->
    topic = res.match[1]
    meetbot.hasMeeting(res.envelope.room ? res.envelope.reply_to)
    .then ->
      meetbot.addTopic(res.envelope.room, topic)
    .then (label) ->
      res.send "Topic `#{topic}` recorded for meeting `#{label}`."
    .catch (e) ->
      res.send e
    res.finish()

  robot.hear /(.*)$/, (res) ->
    meetbot.hasMeeting(res.envelope.room ? res.envelope.reply_to)
    .then ->
      meetbot.addLog(res.envelope)
