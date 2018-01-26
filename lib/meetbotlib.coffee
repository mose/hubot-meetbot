# Description:
#   meetbot library
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

  withPermission: (user) ->
    return new Promise (res, err) =>
      if process.env.MEETBOT_NOAUTH is 'y'
        isAuthorized = true
      else
        isAuthorized = @robot.auth?.hasRole(user, [process.env.MEETBOT_AUTH_GROUP]) or
                       @robot.auth?.isAdmin(user)
      if @robot.auth? and not isAuthorized
        err "You don't have permission to do that."
      else
        res()

  findMeeting: (room) ->
    return new Promise (res, err) =>
      if @data[room]
        if @data[room].label
          res @data[room].label
        else
          err 'Opps something is broken in the meeting, you should close it.'
      else
        res false

  hasMeeting: (room) ->
    return new Promise (res, err) =>
      if @data[room]
        res true
      else
        err 'There is no ongoing meeting here.'

  startMeeting: (room, label) ->
    return new Promise (res, err) =>
      if @data[room]
        err "A meeting is already in progress, named `#{@data[room].label}`."
      else
        label ||= util.format 'meeting of %s', moment().utc().format('HH:mm')
        @data[room] = {
          label: label
          topic: false
          start: moment().utc().format()
          end: false
          info: []
          action: []
          agreed: []
          link: []
          logs: []
        }
        res label

  endMeeting: (room) ->
    return new Promise (res, err) =>
      if @data[room]
        label = @data[room].label
        @data[room].room = room
        @data[room].end = moment().utc().format()
        @robot.emit 'meetbot.notes', @data[room]
        delete @data[room]
        res label
      else
        err 'There is no ongoing meeting here.'

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
        res { label: @data[room].label, topic: topic }
      else
        err 'There is no ongoing meeting here.'

  addAgreement: (room, text) ->
    return new Promise (res, err) =>
      if @data[room]
        @data[room].agreed.push text
        res { label: @data[room].label, text: text }
      else
        err 'There is no ongoing meeting here.'

  addInfo: (room, text) ->
    return new Promise (res, err) =>
      if @data[room]
        @data[room].info.push text
        res { label: @data[room].label, text: text }
      else
        err 'There is no ongoing meeting here.'

  addAction: (room, text) ->
    return new Promise (res, err) =>
      if @data[room]
        @data[room].action.push text
        res { label: @data[room].label, text: text }
      else
        err 'There is no ongoing meeting here.'

  addLink: (room, text) ->
    return new Promise (res, err) =>
      if @data[room]
        @data[room].link ||= []
        @data[room].link.push text
        res { label: @data[room].label, text: text }
      else
        err 'There is no ongoing meeting here.'



module.exports = Meetbot
