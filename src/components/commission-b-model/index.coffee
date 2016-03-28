parse      = require('parse')
Ratio      = require('ratio')
SuperModel = require('super-model')

fixsplits = (splits)->
  (splits or []).map (split)->
    split.ratio = split.ratio.toString()
    split

sfn = (splits, done)->
  @save splits: fixsplits(splits),
    wait: true
    patch: true
    success: (model, res, opts)->
      done(null, model)
    error: (model, res, opts)->
      done(parse.backbone.error(res), model)

class Commission extends SuperModel

  idAttribute: "_id"

  urlRoot: '/api/commission'

  isWhole: ->
    splits = @get('splits')
    sum = _.chain(splits)
      .map((split)-> split.ratio)
      .reduce(((a, b)-> a.plus(b)), Ratio(0, 1))
      .value()
    sum.n * sum.d is 1

  parse: (res, opts)->
    res.labelRatio = new Ratio(res.labelRatio)
    res.splits = (res.splits or []).map (split)->
      split.ratio = new Ratio(split.ratio)
      split.startDate = new Date(split.startDate)
      split.endDate = new Date(split.endDate)
      split
    res

  toJSON: (opts)->
    obj = SuperModel.prototype.toJSON.call(@, opts)
    obj.labelRatio = obj.labelRatio.toString()
    obj.splits = fixsplits(obj.splits)
    obj

  changeSplit: (ratio, userId, done)->
    splits = @get('splits')
    split = _.detect splits, (split)-> split.userId is userId
    return done(Error('User not found in commissions.')) unless split
    split.ratio = ratio
    sfn.call(@, splits, done)

  addSplits: (splits, publisherId, done)->
    return unless splits.length
    toadd = splits.map (split)=>
      @createSplit(split.ratio, split.userId, publisherId)
    splits = @get('splits').concat(toadd)
    sfn.call @, splits, (err, model)->
      done(err, model, toadd)

  createSplit: (ratio, userId, publisherId)->
    userId: userId
    publisherId: publisherId
    ratio: ratio.toString()
    value: ratio.valueOf()

  addSplit: (ratio, userId, publisherId, done)->
    @addSplits(ratio, [userId], publisherId, done)

  removeSplit: (userId, done)->
    splits = @get('splits')
    split = _.detect splits, (split)-> split.userId is userId
    splits.splice(splits.indexOf(split), 1)
    sfn.call(@, splits, done)

  setRemainingSplit: (userId, done)->
    remaining = new Ratio(1)
    splits = @get('splits')
    splits.forEach (split)->
      remaining = remaining.minus(split.ratio) unless split.userId is userId
    @changeSplit(remaining, userId, done)

  getSplit: (userId)->
    _.find @get('splits') or [], (split)-> split.userId is userId

  setSplitDate: (userId, which, date, done)->
    splits = @attributes.splits
    split = _.detect splits, (split)-> split.userId is userId
    return done(Error('User not found in commissions.')) unless split
    split[which] = date
    sfn.call(@, splits, done)

  cloneAs: (type)->
    at = _.clone(@attributes)
    delete at._id
    at.type = type
    at.splits = at.splits.concat() if at.splits
    new Commission(at)

module.exports = Commission
