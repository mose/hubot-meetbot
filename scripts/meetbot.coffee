# Description:
#   a meeting manager ala meetbot
#
# Commands:
#   hubot meet version
#   hubot meet
#   hubot meet start [<label>]
#   hubot meet start
#   hubot meet end
#   hubot meet topic <topic>
#   hubot meet agree <text>
#   hubot meet info <text>
#   hubot meet action <text>
#   hubot meet link <text containing link>
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

  robot.meetbot ?= new Meetbot robot, process.env
  meetbot = robot.meetbot

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

#   hubot meet end
  robot.respond /(?:endmeeting|meet (?:end|close|off))\s*?$/, (res) ->
    label = res.match[1]
    meetbot.withPermission(res.envelope.user)
    .then ->
      meetbot.endMeeting(res.envelope.room)
    .then (label) ->
      res.send "Closing meeting `#{label}` ..."
    .catch (e) ->
      res.send e
    res.finish()

#   hubot meet topic <topic>
  robot.respond /meet topic\s*(.*)?$/, (res) ->
    topic = res.match[1]
    meetbot.addTopic(res.envelope.room, topic)
    .then (data) ->
      res.send "Topic `#{data.topic}` recorded for meeting `#{data.label}`."
    .catch (e) ->
      res.send e

#   hubot meet agree <text>
  robot.respond /(?:meet )?agreed?\s*(.*)?$/, (res) ->
    text = res.match[1]
    meetbot.addAgreement(res.envelope.room, text)
    .then (data) ->
      res.send "Agreement `#{data.text}` recorded for meeting `#{data.label}`."
    .catch (e) ->
      res.send e

#   hubot meet info <text>
  robot.respond /(?:meet )?info\s*(.*)?$/, (res) ->
    text = res.match[1]
    meetbot.addInfo(res.envelope.room, text)
    .then (data) ->
      res.send "Info `#{data.text}` recorded for meeting `#{data.label}`."
    .catch (e) ->
      res.send e

#   hubot meet action <text>
  robot.respond /(?:meet )?action\s*(.*)?$/, (res) ->
    text = res.match[1]
    meetbot.addAction(res.envelope.room, text)
    .then (data) ->
      res.send "Action `#{data.text}` recorded for meeting `#{data.label}`."
    .catch (e) ->
      res.send e

#   hubot meet link <text containing link>
  robot.respond /(?:meet )?link\s*(.*)?$/, (res) ->
    text = res.match[1]
    meetbot.addLink(res.envelope.room, text)
    .then (data) ->
      res.send "Link `#{data.url}` recorded for meeting `#{data.label}`."
    .catch (e) ->
      res.send e


  robot.hear /(.*)$/, (res) ->
    meetbot.hasMeeting(res.envelope.room ? res.envelope.reply_to)
    .then ->
      meetbot.addLog(res.envelope)
    .catch (e) -> { }
