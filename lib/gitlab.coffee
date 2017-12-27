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

querystring = require('querystring')

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
        .path("api/v3/#{endpoint}")
        .header('PRIVATE-TOKEN', @apikey)
        .get() (error, result, payload) ->
          if res.statusCode is 200
            res JSON.parse(payload)
          else
            err "http error #{result.statusCode}"

  post: (endpoint, body) =>
    return new Promise (res, err) =>
      @robot.http(@url)
        .path("api/v3/#{endpoint}")
        .header('PRIVATE-TOKEN', @apikey)
        .post(body) (error, result, payload) ->
          if res.statusCode is 201
            res JSON.parse(payload)
          else
            err "http error #{result.statusCode}"


  getRepoId: (repo) ->
    return new Promise (res, err) =>
      if @robot.brain.data.gitlab.repos[repo]
        res @robot.brain.data.gitlab.repos[repo]
      else
        endpoint = 'projects/search/' + repo.replace(/.*\//, '') + '?per_page=100'
        @get(endpoint)
        .then (json_body) ->
          for p in json_body
            if p.path_with_namespace is repo
              @robot.brain.data.gitlab.repos[repo] = p.id
              res p.id
              break
          err "Repo #{repo} not found"
        .catch (e) ->
          err e

  createBranch: (repoId, branchName) ->
    return new Promise (res, err) =>
      query = { }
      query.id = repoId
      query.branch_name = branchName
      query.ref = 'master'
      body = querystring.stringify(query)
      endpoint = "projects/#{repoId}/repository/branches"
      @post(endpoint)
      .then (json_body) ->
        res json_body
      .catch (e) ->
        err e

  createFile: (repoId, branchname, date, label, text) ->
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
      query.branch_name = branchName
      query.content = text
      query.file_path = filepath
      query.commit_message = 'Meetbot minutes'
      body = querystring.stringify(query)
      endpoint = "projects/#{repoId}/repository/files"
      @post(endpoint)
      .then (json_body) ->
        res json_body
      .catch (e) ->
        err e

  createMergeRequest: (msg, repoId, branchName) ->
    return new Promise (res, err) =>
      query = { }
      query.id = repoId
      query.source_branch = branchName
      query.target_branch = 'master'
      query.title = branchName
      body = querystring.stringify(query)
      endpoint = "projects/#{repoId}/merge_requests"
      @post(endpoint)
      .then (json_body) ->
        res json_body
      .catch (e) ->
        err e

  format: (data) ->
    back = ''
    # formatting
    back



module.exports = Gitlab
