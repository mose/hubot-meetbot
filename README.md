Hubot Meetbot Plugin
=================================

[![Version](https://img.shields.io/npm/v/hubot-meetbot.svg)](https://www.npmjs.com/package/hubot-meetbot)
[![Downloads](https://img.shields.io/npm/dt/hubot-meetbot.svg)](https://www.npmjs.com/package/hubot-meetbot)
[![Build Status](https://img.shields.io/travis/Gandi/hubot-meetbot.svg)](https://travis-ci.org/Gandi/hubot-meetbot)
[![Dependency Status](https://gemnasium.com/Gandi/hubot-meetbot.svg)](https://gemnasium.com/Gandi/hubot-meetbot)
[![Coverage Status](https://img.shields.io/codeclimate/coverage/github/Gandi/hubot-meetbot.svg)](https://codeclimate.com/github/Gandi/hubot-meetbot/coverage)
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

- `HUBOT_MEETBOT_NOAUTH` - if defined, it will bypass the need to be admin to use the meetbot admin commands
- `HUBOT_MEETBOT_AUTH_GROUP` - if defined it will permit group specified to use the meetbot admin commands

It's also advised to use a brain persistence plugin, whatever it is, to persist ongoing meeting sessions between restarts.


Commands
--------------

**Note: until version 1.0.0, this readme is a roadmap, not a real documentation. This is a Readme-driven development approach.**

The commands are loosely inspired from http://meetbot.debian.net/Manual.html

Commands prefixed by `.` are here taking in account we use the `.` as hubot prefix, just replace it with your prefix if it is different. Uncommented commands are just not yet implemented.

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
        Sets teh topic for the meeting
        perms: admin only

    .agree <text>
    .agreed <text>
        Mark something as agreed on. The rest of the line is the details
        perms: admin only

    .meet info <text>
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

Contribute
--------------
Feel free to open a PR if you find any bug, typo, want to improve documentation, or think about a new feature. 

Gandi loves Free and Open Source Software. This project is used internally at Gandi but external contributions are **very welcome**. 

Authors
------------
- [@mose](https://github.com/mose) - author and maintainer

License
-------------
This source code is available under [MIT license](LICENSE).

Copyright
-------------
Copyright (c) 2017 - Mose - http://mose.com
