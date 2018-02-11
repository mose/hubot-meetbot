# Description:
#   requests Gitlab api
#
# Dependencies:
#
# Configuration:
#  MEETBOT_GITHUB_APIKEY
#  MEETBOT_GITHUB_ORG
#  MEETBOT_GITHUB_REPO
#
# Author:
#   mose

moment = require 'moment-timezone'
querystring = require 'querystring'
util = require 'util'
Promise = require 'bluebird'
octokit = require('@octokit/rest')()

class Github
  constructor: (@robot, env) ->
    @org = env.MEETBOT_GITHUB_ORG
    @repo = env.MEETBOT_GITHUB_REPO
    @tz = env.MEETBOT_TZ or 'UTC'

  createFile: (repoId, branchName, date, label, text) ->
    return new Promise (res, err) =>
      octokit.authenticate({ type: 'oauth', token: env.MEETBOT_GITHUB_APIKEY })
      filetitle = text
        .slice(0, text.indexOf('\n'))
        .replace(/[^a-zA-Z0-9]/g, '')
        .replace(/^[0-9]{1,8}/, '')
      filepath = util.format(
        @env.MEETBOT_GITLAB_FILEPATH,
        moment(date).format(@env.MEETBOT_GITLAB_DATEFORMAT or 'YYYY-MM-DD'),
        label
      )
      octokit.repos.createFile({
        owner: 'octokit',
        repo: 'rest.js',
        path: 'blah.txt',
        message: 'blah blah',
        content: 'YmxlZXAgYmxvb3A='
      })



module.exports = Github
