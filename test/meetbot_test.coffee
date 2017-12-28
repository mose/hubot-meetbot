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
meetData = require './sample/meetdata-empty.json'

# --------------------------------------------------------------------------------------------------
describe 'meetbot module', ->

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

# --------------------------------------------------------------------------------------------------
  context 'meetbot robot launch', ->
    beforeEach ->
      room.robot.brain.data.meetbot = meetData
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

    context 'there is a broken meeting going on', ->
      beforeEach ->
        room.robot.brain.data.meetbot = { room1: { } }
        room.robot.brain.emit 'loaded'

      context 'meet', ->
        hubot 'meet'
        it 'should explain that there is a broken meeting', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse())
          .to.eq 'Opps something is broken in the meeting, you should close it.'

    context 'there is a meeting going on', ->
      beforeEach ->
        room.robot.brain.data.meetbot = meetData
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
        room.robot.brain.data.meetbot = meetData
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

# --------------------------------------------------------------------------------------------------
  context 'meeting is started', ->

    context 'and someone says something', ->
      beforeEach ->
        room.robot.brain.data.meetbot = meetData
        room.robot.brain.emit 'loaded'
        @clock = sinon.useFakeTimers({ now: moment().valueOf(), toFake: ['Date'] })

      afterEach ->
        room.robot.brain.data.meetbot = { }
        @clock.restore()

      context 'I say something', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubotHear 'I say something'
        it 'should record what someone says in the logs', ->
          expect(hubotResponseCount()).to.eql 0
          expect(room.robot.meetbot.data.room1.logs.length).to.eql 1
          expect(room.robot.meetbot.data.room1.logs[0])
          .to.eql {
            time: moment(@clock.now, 'x').utc().format()
            user: 'momo'
            text: 'I say something'
          }

      # topic
      context 'meet topic some topic', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'meet topic some topic'
        it 'should record the new topic', ->
          expect(hubotResponseCount()).to.eql 1
          expect(room.robot.meetbot.data.room1.logs.length).to.eql 1
          expect(room.robot.meetbot.data.room1.topic).to.eql 'some topic'
          expect(hubotResponse())
          .to.eq 'Topic `some topic` recorded for meeting `standup meeting`.'

      context 'meet agree some topic', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'meet agree some topic'
        it 'should record the new agreement', ->
          expect(hubotResponseCount()).to.eql 1
          expect(room.robot.meetbot.data.room1.logs.length).to.eql 1
          expect(room.robot.meetbot.data.room1.agreed[0]).to.eql 'some topic'
          expect(hubotResponse())
          .to.eq 'Agreement `some topic` recorded for meeting `standup meeting`.'

      context 'agree some topic', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'agree some topic'
        it 'should record the new agreement', ->
          expect(hubotResponse())
          .to.eq 'Agreement `some topic` recorded for meeting `standup meeting`.'

      context 'agreed some topic', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'agreed some topic'
        it 'should record the new agreement', ->
          expect(hubotResponse())
          .to.eq 'Agreement `some topic` recorded for meeting `standup meeting`.'

      # info
      context 'meet info some info', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'meet info some info'
        it 'should record the new info', ->
          expect(hubotResponseCount()).to.eql 1
          expect(room.robot.meetbot.data.room1.logs.length).to.eql 1
          expect(room.robot.meetbot.data.room1.info[0]).to.eql 'some info'
          expect(hubotResponse())
          .to.eq 'Info `some info` recorded for meeting `standup meeting`.'

      context 'info some info', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'info some info'
        it 'should record the new info', ->
          expect(hubotResponse())
          .to.eq 'Info `some info` recorded for meeting `standup meeting`.'

      # action
      context 'meet action some action', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'meet action some action'
        it 'should record the new action', ->
          expect(hubotResponseCount()).to.eql 1
          expect(room.robot.meetbot.data.room1.logs.length).to.eql 1
          expect(room.robot.meetbot.data.room1.action[0]).to.eql 'some action'
          expect(hubotResponse())
          .to.eq 'Action `some action` recorded for meeting `standup meeting`.'

      context 'action some action', ->
        afterEach ->
          room.robot.meetbot.data.room1.logs = []
        hubot 'action some action'
        it 'should record the new action', ->
          expect(hubotResponse())
          .to.eq 'Action `some action` recorded for meeting `standup meeting`.'

      # end
      context 'endmeeting', ->
        beforeEach ->
          room.robot.brain.data.meetbot = meetData
        afterEach ->
          room.robot.meetbot.data.room1 = { }
        hubot 'endmeeting'
        it 'should close the meeting', ->
          expect(hubotResponseCount()).to.eql 1
          # expect(room.robot.brain.data.meetbot).to.eql room1: { }
          expect(hubotResponse())
          .to.eq 'Closing meeting `standup meeting` ...'

# --------------------------------------------------------------------------------------------------
  context 'meeting is NOT started', ->

    context 'and someone says something', ->
      beforeEach ->
        room.robot.brain.data.meetbot = { }
        room.robot.brain.emit 'loaded'

      afterEach ->
        room.robot.brain.data.meetbot = { }

      context 'I say something', ->
        hubotHear 'I say something'
        it 'should not record anything', ->
          expect(hubotResponseCount()).to.eql 0
          expect(room.robot.meetbot.data).to.eql { }

      # topic
      context 'meet topic some topic', ->
        hubot 'meet topic some topic'
        it 'should warn that no meeting is ongoing', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'There is no ongoing meeting here.'

      # agree
      context 'meet agree decision', ->
        hubot 'meet agree decision'
        it 'should warn that no meeting is ongoing', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'There is no ongoing meeting here.'

      # info
      context 'meet info some info', ->
        hubot 'meet info some info'
        it 'should warn that no meeting is ongoing', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'There is no ongoing meeting here.'

      # action
      context 'meet action some action', ->
        hubot 'meet action some action'
        it 'should warn that no meeting is ongoing', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'There is no ongoing meeting here.'

      # end
      context 'endmeeting', ->
        hubot 'endmeeting'
        it 'should warn that no meeting is ongoing', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse()).to.eq 'There is no ongoing meeting here.'

# --------------------------------------------------------------------------------------------------
  context 'permissions system', ->
    beforeEach ->
      process.env.HUBOT_AUTH_ADMIN = 'admin_user,U00000000'
      room.robot.loadFile path.resolve('node_modules/hubot-auth/src'), 'auth.coffee'
      room.robot.brain.userForId 'U00000000', {
        id: 'U00000000',
        name: 'admin_user'
      }
      room.robot.brain.userForId 'UXXXXXXXX', {
        id: 'UXXXXXXXX',
        name: 'normal_user'
      }
      room.robot.brain.data.meetbot = meetData
    afterEach ->
      room.robot.brain.data.meetbot = { }

    context 'user wants to know if a meeting is going on', ->
      context 'there is no meeting going on', ->
        beforeEach ->
          room.robot.brain.data.meetbot = { }
          room.robot.brain.emit 'loaded'
        context 'meet', ->
          hubot 'meet', 'UXXXXXXXX'
          it 'should explain that there is no meeting', ->
            expect(hubotResponseCount()).to.eql 1
            expect(hubotResponse()).to.eq 'There is no meeting going on right now on this channel.'

    context 'normal user starts a new meeting', ->
      beforeEach ->
        room.robot.brain.data.meetbot = { }
      context 'meet start new meeting', ->
        beforeEach ->
          @now = moment().utc().format('HH:mm')
        hubot 'meet start new meeting', 'UXXXXXXXX'
        it 'should deny permission to the user', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse())
          .to.eq "You don't have permission to do that."

    context 'normal user end a meeting', ->
      context 'meet end', ->
        hubot 'meet end', 'UXXXXXXXX'
        it 'should deny permission to the user', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse())
          .to.eq "You don't have permission to do that."

    context 'normal user starts a new meeting in a NOAUTH environment', ->
      beforeEach ->
        process.env.MEETBOT_NOAUTH = 'y'
        room.robot.brain.data.meetbot = { }
      context 'meet start new meeting', ->
        beforeEach ->
          @now = moment().utc().format('HH:mm')
        hubot 'meet start new meeting', 'UXXXXXXXX'
        it 'should deny permission to the user', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse())
          .to.eq 'Meeting `new meeting` is now open. All discussions will now be recorded.'


    context 'admin user starts a new meeting', ->
      beforeEach ->
        room.robot.brain.data.meetbot = { }
      context 'meet start new meeting', ->
        beforeEach ->
          @now = moment().utc().format('HH:mm')
        hubot 'meet start new meeting', 'U00000000'
        it 'should deny permission to the user', ->
          expect(hubotResponseCount()).to.eql 1
          expect(hubotResponse())
          .to.eq 'Meeting `new meeting` is now open. All discussions will now be recorded.'

# --------------------------------------------------------------------------------------------------
