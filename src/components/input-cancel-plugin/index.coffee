module.exports = (config={})-> (v)->
  { target, button, canceled } = config

  onClick = (e)->
    return unless el = @n.getEl(target)
    return unless el.value

    el.value = ''

    # Not sure i like this, but is so the fsr plugin which
    # listens to keyup events still works
    # Could just reset filter in config.canceled
    # but not sure i want to type all that either.
    el.dispatchEvent(new Event('keyup', {bubbles: true, cancelable: true}))
    el.dispatchEvent(new Event('change', {bubbles: true, cancelable: true}))

    canceled.call(@) if typeof canceled is 'function'

  v.ons
    "click #{button}": onClick
