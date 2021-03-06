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

moment = require 'moment-timezone'
querystring = require 'querystring'
util = require 'util'
Promise = require 'bluebird'

class Gitlab
  constructor: (@robot, env) ->
    @url = env.MEETBOT_GITLAB_URL
    @apikey = env.MEETBOT_GITLAB_APIKEY
    @env = env
    @tz = @env.MEETBOT_TZ or 'UTC'
    storageLoaded = =>
      @storage = @robot.brain.data.gitlab ||= {
        repos: { }
      }
      @robot.logger.debug 'Gitlab Data Loaded: ' + JSON.stringify(@storage, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

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
        @env.MEETBOT_GITLAB_FILEPATH,
        moment(date).format(@env.MEETBOT_GITLAB_DATEFORMAT or 'YYYY-MM-DD'),
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


module.exports = Gitlab
