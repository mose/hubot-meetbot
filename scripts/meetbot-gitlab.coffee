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

module.exports = (robot) ->

  robot.gitlab ?= new Gitlab robot, process.env
  gitlab = robot.gitlab

  robot.on 'meetbot.notes', (data) ->
    console.log data
    label = data.label.replace(/[^a-zA-Z0-9]/g, '')
    date = moment(data.end).format('YYYY-MM-DD')
    branchname = "#{date}-#{label}"
    if process.env.MEETBOT_GITLAB_REPO and
    process.env.MEETBOT_GITLAB_URL and
    process.env.MEETBOT_GITLAB_APIKEY
      gitlab.getRepoId(process.env.MEETBOT_GITLAB_REPO)
      .then (repoId) ->
        label = data.label.replace(/[^a-zA-Z0-9]/g, '')
        date = moment(data.end).format('YYYY-MM-DD')
        gitlab.createBranch(repoId, branchname)
      .then (json) ->
        gitlab.format(data)
      .then (text) ->
        gitlab.createFile(repoId, branchname, data.end, data.label, text)
      .then (json) ->
        gitlab.createMergeRequest(repoId, branchname)
      .then (json) ->
        res json
      .catch (e) ->
        robot.logger.error e

  robot.respond /meet show/, (res) ->
    room = res.envelope.room
    gitlab.format(robot.brain.data.meetbot[room])
    .then (text) ->
      res.send "```\n#{text}\n```"
    res.finish()
