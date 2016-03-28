isPlaying = (player, track)->
  (player.getItem() or {}).track is track and !player.audio?.paused

setState = (el, playing)->
  action = if playing then 'add' else 'remove'
  el.classList[action]('active')

module.exports = (config={})-> (v)->
  throw Error('Must provide getTrack method.') unless config.getTrack
  throw Error('Must provide event.') unless config.ev

  v.init (opts={})->
    { @player } = opts
    throw Error('Player must be provided.') unless @player

  v.on config.ev, (e)->
    { player } = @
    e.stopPropagation()
    el = e.currentTarget
    return unless track = config.getTrack.call(@, el)

    playing = isPlaying(player, track)
    if playing
      player.pause()
    else
      player.clear()
      player.addAndPlay
        source: track.fileOriginalUrl()
        track: track
      player.once "stop", =>
        setState(el, isPlaying(player, track))
    setState(el, !playing)
