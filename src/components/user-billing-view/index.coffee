parse = require('parse')
view  = require('view-plugin')

UserBillingView = v = bQuery.view()

v.use view
  className: "user-billing-view"
  template: require('./template')
  binder: 'property'

v.set 'render', ->
  @renderer.render()
  @displayPaymentInfo()
  @stopListening(@model)
  @listenTo(@model, "change:paymentType", @displayPaymentInfo.bind(@))

v.set 'displayPaymentInfo', ->
  @n.evaluateClass("[role='paypal-email-info']", "hide",
    @model.get("paymentType") isnt "PayPal")

module.exports = v.make()