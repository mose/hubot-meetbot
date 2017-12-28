Hubot Meetbot Plugin
=================================

[![Version](https://img.shields.io/npm/v/hubot-meetbot.svg)](https://www.npmjs.com/package/hubot-meetbot)
[![Downloads](https://img.shields.io/npm/dt/hubot-meetbot.svg)](https://www.npmjs.com/package/hubot-meetbot)
[![Build Status](https://img.shields.io/travis/mose/hubot-meetbot.svg)](https://travis-ci.org/mose/hubot-meetbot)
[![Dependency Status](https://gemnasium.com/mose/hubot-meetbot.svg)](https://gemnasium.com/mose/hubot-meetbot)
[![Coverage Status](https://coveralls.io/repos/github/mose/hubot-meetbot/badge.svg?branch=master)](https://coveralls.io/github/mose/hubot-meetbot?branch=master)
[![NPM](https://nodei.co/npm/hubot-meetbot.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/hubot-meetbot/)

This plugin is a clone of the famous Debian Meetbot https://wiki.debian.org/MeetBot, for use of teams on slack.

*Work in progress* - this plugin is ready for use but still very experimental.


Installation
--------------
In your hubot directory:    

    npm install hubot-meetbot --save

Then add `hubot-meetbot` to `external-scripts.json`


Configuration
-----------------

If you use [hubot-auth](https://github.com/hubot-scripts/hubot-auth), the plugin configuration commands will be restricted to user with the `admin` role. 

If hubot-auth is not loaded, all users can access those commands. You can use those variables to tune things up a bit.

- `MEETBOT_NOAUTH` - if defined, it will bypass the need to be admin to use the meetbot admin commands
- `MEETBOT_AUTH_GROUP` - if defined it will permit group specified to use the meetbot admin commands

It's also advised to use a brain persistence plugin, whatever it is, to persist ongoing meeting sessions between restarts.

When meeting is over and closed, the minutes will be emitted as a `meetbot.notes` event. For my immediate needs I have added a gitlab process to create a MR with the minutes in there, but later on other processors could be added (github, etherpad, mail, etc). In order for the processor to be functional, those 3 env variables have to be set:

- `MEETBOT_GITLAB_URL`
- `MEETBOT_GITLAB_APIKEY`
- `MEETBOT_GITLAB_REPO`
- `MEETBOT_GITLAB_FILEPATH` and `MEETBOT_GITLAB_DATEFORMAT` - 
    used to build the file name. optional. default is `minutes/%s-%s.md` and `YYYY-MM-DD`.  
    format `MEETBOT_GITLAB_FILEPATH` gets `MEETBOT_GITLAB_DATEFORMAT` and meeting label as arguments

Commands
--------------

**Note: until version 1.0.0, this readme is a roadmap, not a real documentation. This is a Readme-driven development approach.**

The commands are loosely inspired from http://meetbot.debian.net/Manual.html

Commands prefixed by `.` are here taking in account we use the `.` as hubot prefix, just replace it with your prefix if it is different. Uncommented commands are just not yet implemented.

    .meet
        give the name of the ongoing meeting on the given channel
        or warns that there is no ongoing meeting at the moment

    .meet start [<label>]
    .meet on [<label>]
    .startmeeting [<label>]
        starts a meeting with given <label> name
        if no label is provided, it will be named after the hour of start of the meeting
        perms: admin only

    .meet end
    .meet close
    .meet off
    .endmeeting
        closes a meeting
        An event meetbot.notes will be triggered at the end of the meeting, 
        so you can code whatever you want to do with the meeting notes in your custom bot
        perms: admin only

    .meet topic <topic>
        Sets the topic for the meeting
        perms: admin only

    .meet agree info<text>
    .agreed <text>
    .agree <text>
        Mark something as agreed on. The rest of the line is the details

    .meet info info<text>
    .info <text>
        Add an INFO item to the minutes

    .meet action <text>
    .action <text>
        Add an ACTION item to the minutes


Testing
----------------

    npm install

    # will run make test and coffeelint
    npm test 
    
    # or
    make test
    
    # or, for watch-mode
    make test-w

    # or for more documentation-style output
    make test-spec

    # and to generate coverage
    make test-cov

    # and to run the lint
    make lint

    # run the lint and the coverage
    make

Changelog
---------------
All changes are listed in the [CHANGELOG](CHANGELOG.md)

Authors
------------
- [@mose](https://github.com/mose) - author and maintainer

License
-------------
This source code is available under [MIT license](LICENSE).

Copyright
-------------
Copyright (c) 2017 - Mose - http://mose.com
