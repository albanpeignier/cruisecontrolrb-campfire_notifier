# Campfire Notifier Plugin for CruiseControl.rb

Thoughtworks produced a piece of software called [CruiseControl.rb][0]
(“CC.rb”) that acts as a continuous integration service, essentially
running a “build” or your test suite for your Ruby projects.

 [0]: http://cruisecontrolrb.thoughtworks.com/

[Campfire][1] is a group chat service from 37signals that many companies use
for collaboration among their team members.

 [1]: http://campfirenow.com/

This plugin will post notifications to a Campfire room when a build on CC.rb
finishes. By default, it will alert the room when a build is: FIXED (was
previously failing, now passing), BROKEN (was previously passing, now failing),
SUCCESS and FAILED.

## Installation

### Getting the Software

Clone this repo into a suitable directory:

    $ cd ~
    $ git clone git://github.com/h3h/cruisecontrolrb-campfire_notifier.git
    $ cd cruisecontrolrb-campfire_notifier

Install bundler if you don't already have it
(You [shouldn't need to use `sudo`][2] when installing your gems):

 [2]: https://github.com/mxcl/homebrew/wiki/Gems,-Eggs-and-Perl-Modules/6be1bb6f74610538bf61409523d5e75c2bbcdaf5

    $ gem install bundler

Install all of the gems required for this library:

    $ bundle install

Make sure the tests pass:

    $ rake

### Installing the Plugin

Find your `$CRUISE_HOME/builder_plugins` directory (usually
`~/.cruise/builder_plugins`), then symlink to `lib/campfire_notifier.rb` within
this plugin:

    $ cd ~/.cruise/builder_plugins
    $ ln -s ~/cruisecontrolrb-campfire_notifier/lib/campfire_notifier.rb

You should end up with something like:

    # cd ~/.cruise
    $ tree -L 2
    .
    |-- builder_plugins
    |   `-- campfire_notifier.rb -> /Users/brad/cruisecontrolrb-campfire_notifier/lib/campfire_notifier.rb
    |-- data.version
    |-- projects
    |   `-- myproject
    |-- site.css
    `-- site_config.rb

## Configuration

Inside each of your project directories (`~/.cruise/projects/myproject/`)
you'll find a `cruise_config.rb` file. For each project that you want to
set up to notify Campfire, configure it with the following:

    Project.configure do |project|
      project.campfire_notifier.account               = 'myaccount'
      project.campfire_notifier.token                 = 'secret'
      project.campfire_notifier.room                  = 'Builds'

      # Optional:
      project.campfire_notifier.ssl                   = true
      project.campfire_notifier.trac_url              = '***/trac/***/changeset'
      project.campfire_notifier.broken_image          = 'http://***/sad.png'
      project.campfire_notifier.fixed_image           = 'http://***/happy.png'
      project.campfire_notifier.only_failed_builds    = true
      project.campfire_notifier.only_first_failure    = true
      project.campfire_notifier.only_fixed_and_broken_builds = true
    end

These configuration options should be pretty self-explanatory.

Or not.. here's the chart of when notifications are enabled/disabled:

    +------------------------------+------------------+----------------+------------------+----------------+
    |                              | was broke now ok | success        | was ok now broke | broken         |
    | when flag=true               | build_fixed      | build_finished | build_broken     | build_finished |
    +------------------------------+------------------+----------------+------------------+----------------+
    | (none - default)             |       no         |   yes          |       no         |  yes           |
    | only_failed_builds           |       no         |   no           |       no         |  yes           |
    | only_first_failure           |       no         |   yes          |       yes        |  no            |
    | only_fixed_and_broken_builds |       yes        |   no           |       yes        |  no            |
    +------------------------------+------------------+----------------+------------------+----------------+

## Test Coverage

    $ gem install rcov
    $ rake rcov

## Credits

This library was originally developed by [Alban Peignier][3] and enhanced by
[Brad Fults][4].

 [3]: https://github.com/albanpeignier
 [4]: https://github.com/h3h
