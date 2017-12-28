require('source-map-support').install {
  handleUncaughtExceptions: false,
  environment: 'node'
}

require('es6-promise').polyfill()

Helper = require('hubot-test-helper')
Hubot = require('../node_modules/hubot')

# helper loads a specific script if it's a file
helper = new Helper('../scripts/meetbot-gitlab.coffee')

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
    process.env.MEETBOT_GITLAB_URL = 'http://example.com'
    process.env.MEETBOT_GITLAB_APIKEY = 'xxx'
    process.env.MEETBOT_GITLAB_REPO = 'meetings'
    room = helper.createRoom { httpd: false }
    room.robot.logger.error = sinon.stub()

  afterEach ->
    delete process.env.MEETBOT_GITLAB_URL
    delete process.env.MEETBOT_GITLAB_APIKEY
    delete process.env.MEETBOT_GITLAB_REPO

    # room.receive = (userName, message) ->
    #   new Promise (resolve) =>
    #     @messages.push [userName, message]
    #     user = room.robot.brain.userForId userName
    #     @robot.receive(new Hubot.TextMessage(user, message), resolve)

# --------------------------------------------------------------------------------------------------
  context 'something emits a meetbot.notes event', ->
    it 'should know about meetbot.notes', ->
      expect(room.robot.events['meetbot.notes']).to.be.defined

    context 'with a user object, ', ->
      beforeEach (done) ->
        # room.robot.logger = sinon.spy()
        # room.robot.logger.info = sinon.spy()
        # room.robot.logger.error = sinon.spy()
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .get('/api/v3/projects/search/meetings?per_page=100')
          .reply(200, [ { path_with_namespace: 'meetings', id: 42 } ])
          .post('/api/v3/projects/42/repository/files')
          .reply(201, { result: { object: { id: 42 } } })
        room.robot.emit 'meetbot.notes', meetData
        setTimeout (done), 40

      afterEach ->
        nock.cleanAll()

      it 'logs a success', ->
        # expect(room.robot.logger.error).not.called
        # expect(room.robot.logger.info).calledOnce
        # expect(room.robot.logger.info).calledWith 'woot'
        expect(room.messages[0]).not.to.be.defined
