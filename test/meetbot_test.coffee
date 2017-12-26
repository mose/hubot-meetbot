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
sinon  = require 'sinon'
moment = require 'moment'
expect = require('chai').use(require('sinon-chai')).expect

room = null

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
  context 'meetbot robot launch', ->
    beforeEach ->
      room.robot.brain.data.meetbot = {
        room1: {
          label: 'standup meeting',
          info: ['event1'],
          action: ['event1'],
          agreed: [ ],
          logs: [ ]
        }
      }
      room.robot.brain.emit 'loaded'

    afterEach ->
      room.robot.brain.data.meetbot = { }

    context 'when brain is loaded', ->
      it 'room1 notes should be loaded', ->
        expect(room.robot.meetbot.data.room1).to.be.defined
      it 'room2 notes should be absent', ->
        expect(room.robot.meetbot.data.room2).not.to.be.defined

# --------------------------------------------------------------------------------------------------
  context 'user wants to know hubot-meetbot version', ->

    context 'meet version', ->
      hubot 'meet version'
      it 'should reply version number', ->
        expect(hubotResponseCount()).to.eql 1
        expect(hubotResponse()).to.match /hubot-meetbot is version [0-9]+\.[0-9]+\.[0-9]+/

# --------------------------------------------------------------------------------------------------
  context 'user wants to know if a meeting is going on', ->

    context 'there is no meeting going on', ->
      beforeEach ->
        room.robot.brain.data.meetbot = { }
        room.robot.brain.emit 'loaded'

      context 'meet', ->
        hubot 'meet'
        it 'should explain that there is no meeting', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'There is no meeting going on right now on this channel.'

    context 'there is a meeting going on', ->
      beforeEach ->
        room.robot.brain.data.meetbot = {
          room1: {
            label: 'standup meeting',
            info: ['event1'],
            action: ['event1'],
            agreed: [ ],
            logs: [ ]
          }
        }
        room.robot.brain.emit 'loaded'

      afterEach ->
        room.robot.brain.data.meetbot = { }

      context 'meet', ->
        hubot 'meet'
        it 'should give the label of the ongoing meeting', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'A meeting is in progress, named `standup meeting`.'
# --------------------------------------------------------------------------------------------------
  context 'user starts a new meeting', ->

    context 'but there is a meeting already going on', ->
      beforeEach ->
        room.robot.brain.data.meetbot = {
          room1: {
            label: 'standup meeting',
            info: ['event1'],
            action: ['event1'],
            agreed: [ ],
            logs: [ ]
          }
        }
        room.robot.brain.emit 'loaded'

      afterEach ->
        room.robot.brain.data.meetbot = { }

      context 'meet start newmeeting', ->
        hubot 'meet start newmeeting'
        it 'should give the label of the ongoing meeting', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'A meeting is already in progress, named `standup meeting`.'

    context 'and there is no meeting already going on', ->
      beforeEach ->
        room.robot.brain.data.meetbot = { }
      afterEach ->
        room.robot.brain.data.meetbot = { }

      context 'meet start', ->
        beforeEach ->
          @now = moment().utc().format('HH:mm')
        hubot 'meet start'
        it 'should give the label of the new meeting', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse())
          .to.eq "Meeting `meeting of #{@now}` is now open. All discussions will now be recorded."

      context 'meet start newmeeting', ->
        hubot 'meet start newmeeting'
        it 'should announce the new meeting is started', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse())
          .to.eq 'Meeting `newmeeting` is now open. All discussions will now be recorded.'
