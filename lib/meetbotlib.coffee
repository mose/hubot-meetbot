# Description:
#   at events library
#
# Author:
#   mose

querystring = require 'querystring'
moment = require 'moment'
util = require 'util'
Promise = require 'bluebird'

class Meetbot

  constructor: (@robot, env) ->
    storageLoaded = =>
      @data = @robot.brain.data.meetbot ||= { }
      @robot.logger.debug 'Meetbot Data Loaded: ' + JSON.stringify(@data, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  withPermission: (user) =>
    return new Promise (res, err) =>
      if process.env.HUBOT_MEETBOT_NOAUTH is 'y'
        isAuthorized = true
      else
        isAuthorized = @robot.auth?.hasRole(user, [process.env.HUBOT_MEETBOT_AUTH_GROUP]) or
                       @robot.auth?.isAdmin(user)
      if @robot.auth? and not isAuthorized
        err "You don't have permission to do that."
      else
        res()

  findMeeting: (room) ->
    return new Promise (res, err) =>
      if @data[room]
        res @data[room].label
      else
        res false

  hasMeeting: (room) ->
    return new Promise (res, err) =>
      if @data[room]
        res false
      else
        err false

  startMeeting: (room, label) ->
    return new Promise (res, err) =>
      if @data[room]
        err "A meeting is already in progress, named `#{@data[room].label}`."
      else
        label ||= util.format 'meeting of %s', moment().utc().format('HH:mm')
        @data[room] = {
          label: label
          topic: ''
          start: moment().utc().format()
          end: false
          info: []
          action: []
          agreed: []
          logs: []
        }
        res label

  addLog: (envelope) ->
    @data[envelope.room].logs.push {
      time: moment().utc().format()
      user: envelope.user.name
      text: envelope.message.text
    }

  addTopic: (room, topic) ->
    return new Promise (res, err) =>
      if @data[room]
        @data[room].topic = topic
        res topic
      else
        err 'There is no ongoing meeting here.'



module.exports = Meetbot
