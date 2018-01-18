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

# --------------------------------------------------------------------------------------------------
describe 'meetbot module', ->

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
    room = helper.createRoom { httpd: false }
    room.robot.logger.error = sinon.stub()

  afterEach ->
    delete process.env.MEETBOT_GITLAB_URL
    delete process.env.MEETBOT_GITLAB_APIKEY
    delete process.env.MEETBOT_GITLAB_REPO
    delete process.env.MEETBOT_GITLAB_FILEPATH

    # room.receive = (userName, message) ->
    #   new Promise (resolve) =>
    #     @messages.push [userName, message]
    #     user = room.robot.brain.userForId userName
    #     @robot.receive(new Hubot.TextMessage(user, message), resolve)

# --------------------------------------------------------------------------------------------------
  context 'something emits a meetbot.notes event', ->
    it 'should know about meetbot.notes', ->
      expect(room.robot.events['meetbot.notes']).to.be.defined

    context 'with a unknown project id, ', ->
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
