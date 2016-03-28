CommissionCollection = require('commission-b-collection')
PublisherCollection  = require('publisher-collection')
TrackModel           = require('track-model')
UserCollection       = require('user-collection')
UserModel            = require('user-model')

toPercent = (value)->
  (value * 100).toFixed(2) + "%"

pull = (dest, src)->
  for k, v of src
    dest[k] = v

copyUser = (from, to)->
  to.artistName = from.name
  to.realName = from.realName
  to.location = from.location

getUserError = (obj)->
  return Error('User is missing an artist name.') unless obj.artistName
  return Error('User is missing a real name.') unless obj.realName
  return Error('User is missing a location.') unless obj.location
  undefined

class Track
  constructor: (obj)->
    @assetType = 'track'
    @importObj(obj) if obj?

  importModel: (id, done)->
    return done?(Error('id not provided.')) unless id
    @connectId = id
    (new TrackModel(_id: id)).sfetch (err, model)=>
      { @title, @isrc, @iswc, @artistsTitle, @label } = model.attributes
      done(Error('Track is missing a title.')) unless @title
      done(Error('Track is missing an ISRC.')) unless @isrc
      # done(Error('Track is missing an ISWC.')) unless @iswc
      done(Error('Track is missing an artist title.')) unless @artistsTitle
      @getShareholders(done)

  importObj: (obj)->
    pull(@, obj)

  getShareholders: (done)->
    selfie = @
    col = new CommissionCollection null,
      by:
        key: 'trackId'
        value: @connectId
    col.sfetch (err, col)->
      return done(err) if err
      usrs = {}
      pubs = []
      col.forEach (com)->
        # TODO validate commission date
        com.attributes.splits.forEach (split)->
          o = usrs[split.userId]
          unless o
            o =
              connectId: split.userId
              shares: {}
            usrs[split.userId] = o
          o.shares[com.attributes.type] =
            value: (split.value * 100).toFixed(2)
            publisher: split.publisherId or ''

          if split.publisherId and pubs.indexOf(split.publisherId) is -1
            pubs.push(split.publisherId)

      getPublishers = (done)->
        pcol = new PublisherCollection null,
          by:
            key: 'label'
            value: selfie.label
          list: pubs
          fields: ['name', 'email', 'contact']
        pcol.sfetch (err, col)->
          return done(err) if err
          done(err, col)

      getUsers = (done)->
        ids = Object.keys(usrs)
        ucol = new UserCollection null,
          list: ids
          fields: ['name', 'realName', 'location']
        ucol.sfetch (err, col)->
          return done(err) if err
          users = []
          for id, i in ids
            data = (col.get(id) or {}).attributes or {}
            u = usrs[id]
            copyUser(data, u)
            return done(err) if err = getUserError(u)
            users.push(u)
          done(null, users)

      getPublishers (err, pcol)->
        return done(err) if err
        getUsers (err, users)->
          return done(err) if err
          users.forEach (u)->
            for k, v of u.shares
              v.publisher = p.attributes if p = pcol.get(v.publisher)
          selfie.users = users
          done(null, selfie)

class User
  constructor: (obj)->
    @assetType = 'user'
    @importObj(obj) if obj?

  importModel: (id, done)->
    return done?(Error('id not provided.')) unless id
    @connectId = id
    (new UserModel(_id: id)).sfetch (err, model)=>
      copyUser(model.attributes, @)
      return done(err) if err = getUserError(@)
      done(null, @)

  importObj: (obj)->
    pull(@, obj)

map =
  'track': Track
  'user': User

module.exports =
  map: map
  types: Object.keys(map)
  Track: Track
  User: User
