AssetCollection             = require('asset-collection')
AccountCollection           = require('account-collection')
ContractCollection          = require('contract-collection')
DocumentCollection          = require('document-collection')
eurl                        = require('end-point').url
LabelCollection             = require('labels-collection')
LabelModel                  = require("label-model")
NewsStreamCollection        = require('news-stream-collection')
PlaylistCollection          = require("playlist-collection")
ReleaseCollection           = require('release-collection')
SubscriptionModel           = require('subscription-model')
SuperCollection             = require('super-collection')
SuperModel                  = require('super-model')
TrackCollection             = require('track-collection')
UserCollection              = require('user-collection')
UserModel                   = require('user-model')

class DataSources

  constructor: ->
    @accounts     = new AccountCollection
    @assets       = new AssetCollection
    @contracts    = new ContractCollection
    @newsStream   = new NewsStreamCollection
    @label        = new LabelModel
    @labels       = new LabelCollection
    @playlists    = new PlaylistCollection
    @statements   = new DocumentCollection
    @subscription = new SubscriptionModel
    @users        = new UserCollection
    @releases     = new ReleaseCollection
    @tracks       = new TrackCollection
    @user         = new UserModel

    @user.url = -> eurl('/api/self')
    @tracks.urlRoot = '/api/catalog/track'
    @releases.urlRoot = '/api/catalog/release'

  setSubscription: (obj={})->
    if @user.isSubscriber() and obj
      @subscription.set(obj)

  setUser: (obj={})->
    @user.set(obj)
    @userInfo =
      id: @user.id
      username: @user.get("name")

  setLabel: (obj={})->
    @label.set(obj)
    @newsStream.label = @label

module.exports = DataSources
