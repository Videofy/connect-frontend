request       = require('superagent')
parse         = require('parse')
SuperModel    = require('super-model')
eurl          = require('end-point').url

class WhiteListItem extends SuperModel
  idAttribute: "_id"
  initialize: (opts={})->
  urlRoot: "/user/whitelist/item" # not using it

  updateChannel: (userId, newChannel, channelType, done)->
    request
      .put(eurl("/user/whitelistChannel/#{userId}"))
      .send
        oldChannelId: @id
        newChannel: newChannel
        channelType: channelType
      .end (err, res)->
        return done(parse.superagent(err,res), res?.body)

  removeChannel: (userId, channelType, done)->
    request
      .del(eurl("/user/whitelistChannel/#{userId}"))
      .send
        channelId: @id
        channelType: channelType
      .end (err, res)->
        return done(parse.superagent(err,res), res?.body)

module.exports = WhiteListItem
