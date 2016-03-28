TransfersView = require("transfers-view")
PresenterView = require("presenter-view")
View = require("view-plugin")

onToggleMenuClick = (e)->
  @evs.trigger("toggle-menu")

onOpenTransfersClick = (e)->
  return unless @transfers
  if !@transfersView
    @transfersView = new TransfersView(transfers: @transfers)
    @transfersView.render()
  @transfers.markAllSeen()
  @presenterView.open(@transfersView)

onTransfersChange = ->
  unseen = @transfers.numUnseen()

  @n.evaluateClass("[role='open-transfers']",
    "active", !!unseen)

  sel = "[role='count']"
  @n.evaluateClass(sel,
    "hide", unseen is 0)
  @n.setText(sel, unseen)

MastView = v = bQuery.view()

v.use View
  className: "mast-view"
  template: require("./template")

v.init (opts={})->
  { @transfers, @user } = opts

  @presenterView = new PresenterView()
  @presenterView.el.classList.add("flexi", "share-coupon-code")

  @transfers.on("change", onTransfersChange.bind(@)) if @transfers

v.set "render", ->
  @renderer.locals.canViewTransfers = !!@transfers
  @renderer.render()
  @presenterView.attach()
  @n.bind("[role='toggle-menu']", "click", onToggleMenuClick.bind(@))
  @n.bind("[role='open-transfers']", "click", onOpenTransfersClick.bind(@))

v.set "setLabel", (label)->
  @setLogo("/img/monstercat-black-icon.png")

v.set "setLogo", (source)->
  @el.querySelector(".mast-logo").style.backgroundImage = "url('#{source}')"

module.exports = v.make()
