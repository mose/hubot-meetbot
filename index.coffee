path = require 'path'

module.exports = (robot) ->
  robot.loadFile(path.resolve(__dirname, 'scripts'), 'meetbot-gitlab.coffee')
  robot.loadFile(path.resolve(__dirname, 'scripts'), 'meetbot.coffee')
