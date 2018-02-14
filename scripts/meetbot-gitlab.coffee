# Description:
#   a plugin to record meeting notes to a gitlab page
#
# Commands:
#
# Configuration:
#   MEETBOT_GITLAB_REPO
#   MEETBOT_GITLAB_URL
#   MEETBOT_GITLAB_APIKEY
#
# Author:
#   mose

Gitlab  = require '../lib/gitlab'
Format  = require '../lib/format'
moment = require 'moment'
util = require 'util'

module.exports = (robot) ->

  robot.gitlab ?= new Gitlab robot, process.env
  gitlab = robot.gitlab

  robot.format ?= new Format process.env
  format = robot.format

  robot.on 'meetbot.notes', (data) ->
    if process.env.MEETBOT_GITLAB_REPO? and
    process.env.MEETBOT_GITLAB_URL? and
    process.env.MEETBOT_GITLAB_APIKEY?
      repoId = null
      branch = process.env.MEETBOT_GITLAB_BRANCH or 'master'
      gitlab.getRepoId(process.env.MEETBOT_GITLAB_REPO)
      .bind(repoId)
      .then (@repoId) ->
        format.markdown(data)
      .then (text) ->
        # console.log text
        gitlab.createFile(@repoId, branch, data.end, data.label, text)
      .then (json) ->
        # console.log json
        robot.logger.info json
        robot.messageRoom data.room, util.format(
          'Done: %s/%s/blob/%s/%s',
          process.env.MEETBOT_GITLAB_URL,
          process.env.MEETBOT_GITLAB_REPO,
          branch,
          json.file_path
          )
      .catch (e) ->
        robot.logger.error e
    else
      robot.logger.info 'GitLab not configured, skiping ...'
