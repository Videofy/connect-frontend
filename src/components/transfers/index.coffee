emitter = require("emitter")
debug = require("debug")("connect:transfers")

class Transfer

  constructor: (@id, @status)->
    @seen = true

  set: (key, value)->
    @[key] = value
    @fire()

  fire: ->
    @emit("change")

emitter(Transfer.prototype)

class Transfers

  constructor: (@evs)->
    @cache = {}
    @fire = @emit.bind(@, "change")

  get: (id)->
    @cache[id]

  set: (id, obj)->
    obj.id = id
    @cache[id] = obj
    @fire()
    obj

  create: (id, status="Pending")->
    id = id or String((new Date).getTime())
    transfer = new Transfer(id, status)
    transfer.on("change", @fire)
    @set(id, transfer)
    transfer

  hasItemsReady: (status="Ready")->
    for key, transfer of @cache
      return true if transfer.status == status
    false

  numUnseen: ->
    i = 0
    for key, transfer of @cache
      i++ if !transfer.seen
    i

  markAllSeen: ->
    for key, transfer of @cache
      transfer.set("seen", true)

emitter(Transfers.prototype)

module.exports = Transfers