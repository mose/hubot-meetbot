# Description:
#   a plugin to record meeting notes to a github page
#
# Commands:
#
# Configuration:
#   MEETBOT_GITHUB_ORG
#   MEETBOT_GITHUB_REPO
#   MEETBOT_GITHUB_APIKEY
#   MEETBOT_GITHUB_BRANCH
#
# Author:
#   mose

Github  = require '../lib/github'
Format  = require '../lib/format'
moment = require 'moment'
util = require 'util'

module.exports = (robot) ->

  robot.github ?= new Github robot, process.env
  github = robot.github

  robot.format ?= new Format process.env
  format = robot.format

  robot.on 'meetbot.notes', (data) ->
    if process.env.MEETBOT_GITHUB_REPO? and
    process.env.MEETBOT_GITHUB_APIKEY?
      repoId = null
      branch = process.env.MEETBOT_GITHUB_BRANCH or 'master'
      github.getRepoId(process.env.MEETBOT_GITHUB_REPO)
      .bind(repoId)
      .then (@repoId) ->
        format.markdown(data)
      .then (text) ->
        # console.log text
        github.createFile(@repoId, branch, data.end, data.label, text)
      .then (json) ->
        # console.log json
        robot.logger.info json
        robot.messageRoom data.room, util.format(
          'Done: https://github.com/%s/%s/blob/%s/%s',
          process.env.MEETBOT_GITHUB_ORG,
          process.env.MEETBOT_GITHUB_REPO,
          branch,
          json.file_path
          )
      .catch (e) ->
        robot.logger.error e
    else
      robot.logger.info 'Github not configured, skiping ...'
