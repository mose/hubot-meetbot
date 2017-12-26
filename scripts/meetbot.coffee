# Description:
#   a meeting manager ala meetbot
#
# Commands:
#   hubot meet version
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
    res.send "hubot-meetbot module is version #{pkg.version}"
    res.finish()
