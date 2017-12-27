# Description:
#   a plugin to record meeting notes to a gitlab page
#
# Commands:
#
# Configuration:
#   MEETBOT_GITLAB_REPO
#
# Author:
#   mose

Gitlab = require '../lib/gitlab'
path    = require 'path'

module.exports = (robot) ->

  robot.meetbot ?= new Meetbot robot, process.env
  meetbot = robot.meetbot

  robot.on 'meetbot.notes', (data) ->
    console.log data
    if process.env.MEETBOT_GITLAB_REPO
      console.log 'a'
