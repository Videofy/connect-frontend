getActiveTag = ->
  document.activeElement?.tagName?.toLowerCase()

isInputting = ->
  getActiveTag() in ['select', 'input', 'textarea']

module.exports = (player, config={})->
  config.next ?= 78
  config.previous ?= 80
  config.loop ?= 76
  config.toggle ?= 32
  config.search ?= 83

  onKeyDown = (e)->
    if not isInputting()
      if e.keyCode is config.next
        player.next()
      else if e.keyCode is config.previous
        player.previous()
      else if e.keyCode is config.loop
        player.loop = !player.loop
      else if e.keyCode is config.search
        document.querySelector('[role="filter"]')?.focus()
        e.preventDefault()
      else if e.keyCode is config.toggle
        if not player.audio or player.audio.paused
          player.play()
        else
          player.pause()
    else if e.keyCode is 27 and getActiveTag() is 'input'
      document.activeElement.blur()

  document.addEventListener('keydown', onKeyDown)
