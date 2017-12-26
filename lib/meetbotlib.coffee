# Description:
#   at events library
#
# Author:
#   mose

querystring = require 'querystring'
moment = require 'moment'
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

  hasMeeting: (room) ->
    return new Promise (res, err) =>
      if @data[room]
        res @data[room].label
      else
        res false

  startMeeting: (room, label) ->
    return new Promise (res, err) ->
      res()



module.exports = Meetbot
