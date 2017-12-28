require('source-map-support').install {
  handleUncaughtExceptions: false,
  environment: 'node'
}

require('es6-promise').polyfill()

Helper = require('hubot-test-helper')
Hubot = require('../node_modules/hubot')

# helper loads a specific script if it's a file
helper = new Helper('../scripts/meetbot.coffee')

path   = require 'path'
nock   = require 'nock'
sinon  = require 'sinon'
moment = require 'moment'
expect = require('chai').use(require('sinon-chai')).expect

room = null
meetData = require './sample/meetdata-empty.json'

# --------------------------------------------------------------------------------------------------
describe 'meetbot module', ->

  hubotEmit = (e, data, tempo = 40) ->
    beforeEach (done) ->
      room.robot.emit e, data
      setTimeout (done), tempo
 
  hubotHear = (message, userName = 'momo', tempo = 40) ->
    beforeEach (done) ->
      room.user.say userName, message
      setTimeout (done), tempo

  hubot = (message, userName = 'momo') ->
    hubotHear "@hubot #{message}", userName

  hubotResponse = (i = 1) ->
    room.messages[i]?[1]

  hubotResponseCount = ->
    room.messages?.length - 1

  beforeEach ->
    room = helper.createRoom { httpd: false }
    room.robot.logger.error = sinon.stub()

    # room.receive = (userName, message) ->
    #   new Promise (resolve) =>
    #     @messages.push [userName, message]
    #     user = room.robot.brain.userForId userName
    #     @robot.receive(new Hubot.TextMessage(user, message), resolve)

# --------------------------------------------------------------------------------------------------
