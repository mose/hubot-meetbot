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
payloadSample = require './sample/payload-sample.json'
dataSample = require './sample/data-sample.json'
dataOutput = require './sample/data-sample-output.json'
dataAnotherdaySample = require './sample/data-sample-anotherday.json'
dataAnotherdayOutput = require './sample/data-sample-anotherday-output.json'
dataIncompleteSample = require './sample/data-sample-incomplete.json'
dataIncompleteOutput = require './sample/data-sample-incomplete-output.json'

# --------------------------------------------------------------------------------------------------
describe 'unconfigured meetbot module', ->

  beforeEach ->
    room = helper.createRoom { httpd: false }
    room.robot.logger = sinon.spy()
    room.robot.logger.info = sinon.spy()
    room.robot.logger.error = sinon.spy()

  context 'something emits a meetbot.notes event', ->
    beforeEach (done) ->
      room.robot.emit 'meetbot.notes', { }
      setTimeout (done), 50
      
    it 'does not do anything', ->
      expect(room.robot.logger.error).not.called
      expect(room.robot.logger.info).calledOnce
      expect(room.robot.logger.info).calledWith 'GitLab not configured, skiping ...'
      expect(room.messages).not.to.be.defined

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
    process.env.MEETBOT_GITLAB_URL = 'http://example.com'
    process.env.MEETBOT_GITLAB_APIKEY = 'xxx'
    process.env.MEETBOT_GITLAB_REPO = 'meetings'
    process.env.MEETBOT_GITLAB_FILEPATH = 'minutes/%s-%s.md'
    process.env.MEETBOT_TZ = 'Asia/Taipei'
    room = helper.createRoom { httpd: false }
    room.robot.logger.error = sinon.stub()

  afterEach ->
    delete process.env.MEETBOT_GITLAB_URL
    delete process.env.MEETBOT_GITLAB_APIKEY
    delete process.env.MEETBOT_GITLAB_REPO
    delete process.env.MEETBOT_GITLAB_FILEPATH
    delete process.env.MEETBOT_TZ

    # room.receive = (userName, message) ->
    #   new Promise (resolve) =>
    #     @messages.push [userName, message]
    #     user = room.robot.brain.userForId userName
    #     @robot.receive(new Hubot.TextMessage(user, message), resolve)


# --------------------------------------------------------------------------------------------------
  context 'something emits a meetbot.notes event', ->
    it 'should know about meetbot.notes', ->
      expect(room.robot.events['meetbot.notes']).to.be.defined

    context 'with a unknown project id', ->
      beforeEach (done) ->
        room.robot.logger = sinon.spy()
        room.robot.logger.info = sinon.spy()
        room.robot.logger.error = sinon.spy()
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .get('/api/v4/projects/' + process.env.MEETBOT_GITLAB_REPO)
          .reply(200, { path_with_namespace: 'meetings', id: 42 })
          .post('/api/v4/projects/42/repository/files/' +
                'minutes%2F2018-01-14-standup%20meeting%20sample.md')
          .reply(201, { file_path: 'minutes/2018-01-14-standup%20meeting%20sample.md' })
        room.robot.emit 'meetbot.notes', payloadSample
        setTimeout (done), 50

      afterEach ->
        nock.cleanAll()

      it 'logs a success', ->
        expect(room.robot.logger.error).not.called
        expect(room.robot.logger.info).calledOnce
        expect(room.robot.logger.info).calledWith {
          file_path: 'minutes/2018-01-14-standup%20meeting%20sample.md'
        }
        expect(room.messages[0][1])
          .to.eq 'Done: http://example.com/meetings/blob/master/' +
                 'minutes/2018-01-14-standup%20meeting%20sample.md'

    context 'with a known project id', ->
      beforeEach (done) ->
        room.robot.logger = sinon.spy()
        room.robot.logger.info = sinon.spy()
        room.robot.logger.error = sinon.spy()
        room.robot.brain.data.gitlab.repos[process.env.MEETBOT_GITLAB_REPO] = 42
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .post('/api/v4/projects/42/repository/files/' +
                'minutes%2F2018-01-14-standup%20meeting%20sample.md')
          .reply(201, { file_path: 'minutes/2018-01-14-standup%20meeting%20sample.md' })
        room.robot.emit 'meetbot.notes', payloadSample
        setTimeout (done), 50

      afterEach ->
        delete room.robot.brain.data.gitlab
        nock.cleanAll()

      it 'logs a success', ->
        expect(room.robot.logger.error).not.called
        expect(room.robot.logger.info).calledOnce
        expect(room.robot.logger.info).calledWith {
          file_path: 'minutes/2018-01-14-standup%20meeting%20sample.md'
        }
        expect(room.messages[0][1])
          .to.eq 'Done: http://example.com/meetings/blob/master/' +
                 'minutes/2018-01-14-standup%20meeting%20sample.md'

    context 'but a http error happens on a post', ->
      beforeEach (done) ->
        room.robot.logger = sinon.spy()
        room.robot.logger.info = sinon.spy()
        room.robot.logger.error = sinon.spy()
        room.robot.brain.data.gitlab.repos[process.env.MEETBOT_GITLAB_REPO] = 42
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .post('/api/v4/projects/42/repository/files/' +
                'minutes%2F2018-01-14-standup%20meeting%20sample.md')
          .reply(500, { })
        room.robot.emit 'meetbot.notes', payloadSample
        setTimeout (done), 50

      afterEach ->
        delete room.robot.brain.data.gitlab
        nock.cleanAll()

      it 'logs a success', ->
        expect(room.robot.logger.error).calledOnce
        expect(room.robot.logger.error).calledWith 'http error 500'

    context 'but an error happens on a post', ->
      beforeEach (done) ->
        room.robot.logger = sinon.spy()
        room.robot.logger.info = sinon.spy()
        room.robot.logger.error = sinon.spy()
        room.robot.brain.data.gitlab.repos[process.env.MEETBOT_GITLAB_REPO] = 42
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .post('/api/v4/projects/42/repository/files/' +
                'minutes%2F2018-01-14-standup%20meeting%20sample.md')
          .replyWithError({ 'message': 'Internet down.' })
        room.robot.emit 'meetbot.notes', payloadSample
        setTimeout (done), 50

      afterEach ->
        delete room.robot.brain.data.gitlab
        nock.cleanAll()

      it 'logs a success', ->
        expect(room.robot.logger.error).calledOnce
        expect(room.robot.logger.error).calledWith { 'message': 'Internet down.' }

    context 'but an http error happens on a get', ->
      beforeEach (done) ->
        room.robot.logger = sinon.spy()
        room.robot.logger.info = sinon.spy()
        room.robot.logger.error = sinon.spy()
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .get('/api/v4/projects/' + process.env.MEETBOT_GITLAB_REPO)
          .reply(500, { })
        room.robot.emit 'meetbot.notes', payloadSample
        setTimeout (done), 50

      afterEach ->
        delete room.robot.brain.data.gitlab
        nock.cleanAll()

      it 'logs a success', ->
        expect(room.robot.logger.error).calledOnce
        expect(room.robot.logger.error).calledWith 'http error 500'

    context 'but an error happens on a get', ->
      beforeEach (done) ->
        room.robot.logger = sinon.spy()
        room.robot.logger.info = sinon.spy()
        room.robot.logger.error = sinon.spy()
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .get('/api/v4/projects/' + process.env.MEETBOT_GITLAB_REPO)
          .replyWithError({ 'message': 'Internet down.' })
        room.robot.emit 'meetbot.notes', payloadSample
        setTimeout (done), 50

      afterEach ->
        delete room.robot.brain.data.gitlab
        nock.cleanAll()

      it 'logs a success', ->
        expect(room.robot.logger.error).calledOnce
        expect(room.robot.logger.error).calledWith { 'message': 'Internet down.' }

    context 'but an error happens when finding the repo id', ->
      beforeEach (done) ->
        room.robot.logger = sinon.spy()
        room.robot.logger.info = sinon.spy()
        room.robot.logger.error = sinon.spy()
        do nock.disableNetConnect
        nock(process.env.MEETBOT_GITLAB_URL)
          .get('/api/v4/projects/' + process.env.MEETBOT_GITLAB_REPO)
          .reply(200, { })
        room.robot.emit 'meetbot.notes', payloadSample
        setTimeout (done), 50

      afterEach ->
        delete room.robot.brain.data.gitlab
        nock.cleanAll()

      it 'logs a success', ->
        expect(room.robot.logger.error).calledOnce
        expect(room.robot.logger.error).calledWith 'Repo meetings not found.'
