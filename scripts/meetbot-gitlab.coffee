# Description:
#   a plugin to record meeting notes to a gitlab page
#
# Commands:
#
# Configuration:
#   MEETBOT_GITLAB_REPO
#
# Author:
#   mose

Gitlab  = require '../lib/gitlab'
moment = require 'moment'

module.exports = (robot) ->

  robot.gitlab ?= new Gitlab robot, process.env
  gitlab = robot.gitlab

  # when branching and MR
  # robot.on 'meetbot.notes', (data) ->
  #   label = data.label.replace(/[^a-zA-Z0-9]/g, '')
  #   date = moment(data.end).format('YYYY-MM-DD')
  #   branchname = "#{date}-#{label}"
  #   if process.env.MEETBOT_GITLAB_REPO and
  #   process.env.MEETBOT_GITLAB_URL and
  #   process.env.MEETBOT_GITLAB_APIKEY
  #     gitlab.getRepoId(process.env.MEETBOT_GITLAB_REPO)
  #     .then (repoId) ->
  #       label = data.label.replace(/[^a-zA-Z0-9]/g, '')
  #       date = moment(data.end).format('YYYY-MM-DD')
  #       gitlab.createBranch(repoId, branchname)
  #     .then (json) ->
  #       gitlab.format(data)
  #     .then (text) ->
  #       gitlab.createFile(repoId, branchname, data.end, data.label, text)
  #     .then (json) ->
  #       gitlab.createMergeRequest(repoId, branchname)
  #     .then (json) ->
  #       res json
  #     .catch (e) ->
  #       robot.logger.error e

  robot.on 'meetbot.notes', (data) ->
    if process.env.MEETBOT_GITLAB_REPO and
    process.env.MEETBOT_GITLAB_URL and
    process.env.MEETBOT_GITLAB_APIKEY
      repoId = null
      gitlab.getRepoId(process.env.MEETBOT_GITLAB_REPO)
      .bind(repoId)
      .then (@repoId) ->
        gitlab.formatData(data)
      .then (text) ->
        # console.log text
        gitlab.createFile(@repoId, 'master', data.end, data.label, text)
      .then (json) ->
        # console.log json
        robot.logger.info json
      .catch (e) ->
        robot.logger.error e

  robot.respond /meet show/, (res) ->
    gitlab.formatData(robot.brain.data.meetbot[res.envelope.room])
    .then (text) ->
      res.send "```\n#{text}\n```"
    res.finish()

  robot.respond /meet gitlab id/, (res) ->
    if process.env.MEETBOT_GITLAB_REPO and
    process.env.MEETBOT_GITLAB_URL and
    process.env.MEETBOT_GITLAB_APIKEY
      gitlab.getRepoId(process.env.MEETBOT_GITLAB_REPO)
      .then (repoId) ->
        res.send "repoId: #{repoId}"

  robot.respond /meet gitlab createfile/, (res) ->
    if process.env.MEETBOT_GITLAB_REPO and
    process.env.MEETBOT_GITLAB_URL and
    process.env.MEETBOT_GITLAB_APIKEY
      repoId = null
      gitlab.getRepoId(process.env.MEETBOT_GITLAB_REPO)
      .bind(repoId)
      .then (@repoId) ->
        res.send "repoId: #{@repoId}"
        data = {
          end: moment().utc().format()
          label: "test minutes"
        }
        text = "sample text"
        gitlab.createFile(@repoId, 'master', data.end, data.label, text)
      .then (json) ->
        console.log json
        robot.logger.info json
        res.send "Done."
      .catch (e) ->
        robot.logger.error e
