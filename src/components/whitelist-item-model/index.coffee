class WhiteListItem extends Backbone.Model
  idAttribute: "_id"
  initialize: (opts={})->

  urlRoot: "/user/whitelist/item" # not using it

module.exports = WhiteListItem
