## About

Scribe is a simple, lightweight bot for logging IRC channels. It is composed of 2 parts:

* a Ruby script to run in the background and watch and log a range of IRC channels
* a Sinatra webapp to receive messages from the bot and provide a user interface

## Setup

Copy the ``scribe.yml.sample`` to ``scribe.yml`` and edit settings - you can put as many rooms in the config as you need.

Run the main webapp ``main.rb``

Run the logger ``logger/scribe.rb``

Open the webapp's URL and you will be asked for a secret - use the same secret in your ``scribe.yml``

## Background

Scribe was originally by [commonthread](https://github.com/commonthread/). This version has been ported to Ruby 1.9 and newer versions of the required gems (Isaac, Yaml, Datamapper etc). 

## TODO

- [x] use Bundler
- [ ] store and organise data by day
- [ ] improve user interface
- [ ] provide Cloud Foundry config