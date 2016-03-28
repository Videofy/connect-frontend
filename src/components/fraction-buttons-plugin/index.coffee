onClickSetFraction = (e)->
  target = e.currentTarget.getAttribute('target-fraction')
  value = e.currentTarget.getAttribute('value')
  return unless el = @n.getEl("[fraction-target='#{target}']")
  el.value = value
  ev = new Event 'change',
    bubbles: true
    cancelable: true
  el.dispatchEvent(ev)

module.exports = (config)->
  (v)->
    v.on 'click [role="set-fraction"]', onClickSetFraction
