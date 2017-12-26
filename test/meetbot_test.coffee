require('source-map-support').install {
  handleUncaughtExceptions: false,
  environment: 'node'
}

require('es6-promise').polyfill()

Helper = require('hubot-test-helper')

# helper loads a specific script if it's a file
helper = new Helper('../scripts/meetbot.coffee')

path   = require 'path'
sinon  = require 'sinon'
moment = require 'moment'
expect = require('chai').use(require('sinon-chai')).expect

room = null

# ---------------------------------------------------------------------------------
describe 'meetbot module', ->

  hubot = (message, userName = 'momo', tempo = 40) ->
    beforeEach (done) ->
      room.user.say userName, "@hubot #{message}"
      setTimeout (done), tempo

  hubotResponse = (i = 1) ->
    room.messages[i]?[1]

  hubotResponseCount = ->
    room.messages?.length - 1

  beforeEach ->
    room = helper.createRoom { httpd: false }
    room.robot.logger.error = sinon.stub()

  # ---------------------------------------------------------------------------------
  context 'meetbot robot launch', ->
    beforeEach ->
      room.robot.brain.data.meetbot = {
        room1: {
          label: 'standup meeting',
          info: [ 
            'event1'
          ],
          action: [ 
            'event1'
          ],
          agreed: [ ],
          logs: [
            ""
          ]
        },
        room2: { }
      }
      room.robot.brain.emit 'loaded'

    afterEach ->
      room.robot.brain.data.meetbot = { }

    context 'when brain is loaded', ->
      it 'room1 notes should be loaded', ->
        expect(room.robot.at.actions.somejob).not.to.be.defined
      it 'jobs stored as started are started', ->
        expect(room.robot.at.actions.other).to.be.defined
      it 'job in brain should have a tz recorded', ->
        expect(room.robot.brain.data.at.other.tz).to.eql 'UTC'


  # ---------------------------------------------------------------------------------
  context 'user wants to know hubot-meetbot version', ->

    context 'meet version', ->
      hubot 'at version'
      it 'should reply version number', ->
        expect(hubotResponse()).
          to.match /hubot-meetbot module is version [0-9]+\.[0-9]+\.[0-9]+/
        expect(hubotResponseCount()).to.eql 1

  # ---------------------------------------------------------------------------------
