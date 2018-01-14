# Description:
#   requests Gitlab api
#
# Dependencies:
#
# Configuration:
#  MEETBOT_GITLAB_URL
#  MEETBOT_GITLAB_APIKEY
#
# Author:
#   mose

querystring = require 'querystring'
moment = require 'moment'
util = require 'util'
Promise = require 'bluebird'

class Gitlab
  constructor: (@robot, env) ->
    @url = env.MEETBOT_GITLAB_URL
    @apikey = env.MEETBOT_GITLAB_APIKEY
    @env = env
    storageLoaded = =>
      @storage = @robot.brain.data.gitlab ||= {
        repos: { }
      }
      @robot.logger.debug 'Gitlab Data Loaded: ' + JSON.stringify(@storage, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  ready: ->
    @robot.logger.error 'Error: Gitlab url is not specified' if not @env.MEETBOT_GITLAB_URL
    @robot.logger.error 'Error: Gitlab api key is not specified' if not @env.MEETBOT_GITLAB_APIKEY
    return false unless (@env.MEETBOT_GITLAB_URL and @env.MEETBOT_GITLAB_APIKEY)
    true

  get: (endpoint) =>
    return new Promise (res, err) =>
      @robot.http(@url)
        .path("api/v4/#{endpoint}")
        .header('PRIVATE-TOKEN', @apikey)
        .get() (error, result, payload) ->
          if error
            err error
          else
            if result.statusCode is 200
              res JSON.parse(payload)
            else
              err "http error #{result.statusCode}"

  post: (endpoint, body) =>
    return new Promise (res, err) =>
      @robot.http(@url)
        .path("api/v4/#{endpoint}")
        .header('PRIVATE-TOKEN', @apikey)
        .post(body) (error, result, payload) ->
          if error
            err error
          else
            if result.statusCode is 201
              res JSON.parse(payload)
            else
              err "http error #{result.statusCode}"

  getRepoId: (repo) ->
    return new Promise (res, err) =>
      if @robot.brain.data.gitlab.repos[repo]
        res @robot.brain.data.gitlab.repos[repo]
      else
        endpoint = 'projects/' + encodeURIComponent(repo)
        @get(endpoint)
        .then (json_body) =>
          if json_body.id
            @robot.brain.data.gitlab.repos[repo] = json_body.id
            res json_body.id
          else
            err "Repo #{repo} not found."
        .catch (e) ->
          err e

  # createBranch: (repoId, branchName) ->
  #   return new Promise (res, err) =>
  #     query = { }
  #     query.id = repoId
  #     query.branch = branchName
  #     query.ref = 'master'
  #     body = querystring.stringify(query)
  #     endpoint = "projects/#{repoId}/repository/branches"
  #     @post(endpoint)
  #     .then (json_body) ->
  #       res json_body
  #     .catch (e) ->
  #       err e

  createFile: (repoId, branchName, date, label, text) ->
    return new Promise (res, err) =>
      filetitle = text
        .slice(0, text.indexOf('\n'))
        .replace(/[^a-zA-Z0-9]/g, '')
        .replace(/^[0-9]{1,8}/, '')
      filepath = util.format(
        process.env.MEETBOT_GITLAB_FILEPATH,
        moment(date).format(process.env.MEETBOT_GITLAB_DATEFORMAT),
        label
      )
      query = { }
      query.branch = branchName
      query.content = text
      query.commit_message = 'Meetbot minutes'
      body = querystring.stringify(query)
      endpoint = "projects/#{repoId}/repository/files/" + encodeURIComponent(filepath)
      @post(endpoint, body)
      .then (json_body) ->
        res json_body
      .catch (e) ->
        err e

  # createMergeRequest: (repoId, branchName) ->
  #   return new Promise (res, err) =>
  #     query = { }
  #     query.id = repoId
  #     query.source_branch = branchName
  #     query.target_branch = 'master'
  #     query.title = branchName
  #     body = querystring.stringify(query)
  #     endpoint = "projects/#{repoId}/merge_requests"
  #     @post(endpoint)
  #     .then (json_body) ->
  #       res json_body
  #     .catch (e) ->
  #       err e

  formatData: (data) ->
    return new Promise (res, err) =>
      back = ''
      if data.topic
        back += "#{data.topic}\n"
      else
        back += 'Metting of ' + moment(data.start).format('YYYY-MM-DD HH:mm') + '\n'
      back += '================================\n\n'
      unless data.end
        data.end = moment().utc().format()
      back += @fromto(data.start, data.end)
      for point in ['info', 'agreed', 'action']
        back += @point(data, point)
      back += 'Full log\n'
      back += '---------'
      namewidth = data.logs.reduce (acc, line) ->
        acc = line.user.length if line.user.length > acc
        acc
      , 0
      for line in data.logs
        back += util.format '\n    %s %s : %s',
          moment(line.time).format('HH:mm'),
          @pad(line.user, namewidth + 2),
          line.text
      back += '\n\n*EOF*\n'
      console.log back
      res back

  point: (data, label) ->
    back = ''
    if data[label].length > 0
      back += "#{label[0].toUpperCase() + label.substr(1)}\n"
      back += Array(label.length + 1).join('-') + '\n'
      for line in data[label]
        back += "- #{line}\n"
      back += '\n'
    back

  fromto: (start, end) ->
    timespent = moment(end).diff(start, 'minutes')
    if moment(start).format('YYYY-MM-DD') is moment(end).format('YYYY-MM-DD')
      util.format('On %s from %s to %s (%s minutes)\n\n',
        moment(start).format('YYYY-MM-DD'),
        moment(start).format('HH:mm'),
        moment(end).format('HH:mm'),
        timespent
        )
    else
      util.format('From %s to %s (%s minutes)\n\n',
        moment(start).format('YYYY-MM-DD HH:mm'),
        moment(end).format('YYYY-MM-DD HH:mm'),
        timespent
        )


  pad: (string, targetLength) ->
    targetLength = targetLength >> 0
    padString = ' '
    if string.length > targetLength
      string
    else
      targetLength = targetLength - string.length
      if targetLength > padString.length
        padString += padString.repeat(targetLength / padString.length)
      padString.slice(0, targetLength) + string



module.exports = Gitlab
