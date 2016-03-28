FileDropper = require("file-dropper")
upload      = require("file-uploader")
view        = require("view-plugin")

onDropperValidated = (valid, files)->
  return if !valid or !files or !files.length

  filename = files[0].name
  upload.files
    url: @model.profileImage()
    files: files
    method: 'put'
  , (err, req)=>
    if err
      stat = "#{filename} has failed to upload."
      theme = "error"
    else
      stat = "#{filename} has finished uploading."
      theme = "success"

    @evs.trigger "toast",
      time: 2500
      theme: theme
      text: stat

    @update(err)

  @evs.trigger "toast",
    time: 2500
    text: "\"#{filename}\" is being uploaded. Please wait..."

UserProfilePageView = v = bQuery.view()

v.use view
  className: "user-profile-image-view"
  template: require("./template")

v.init (opts={})->
  return unless @permissions.canAccess('website.update.profileImageBlobId')
  @cbs =
    validated: onDropperValidated.bind(@)

v.set "render", ->
  @renderer.render()
  return unless @cbs?
  @dropper = new FileDropper
    el: @n.getEl("[role='upload']")
    types: ["application/jpeg", "application/png"]
  @dropper.on("validated", @cbs.validated)

v.set "update", (err)->
  img = @n.getEl("img")
  parent = img.parentElement
  parent.removeChild(img)
  img.src = @model.profileImage()
  parent.insertBefore(img, parent.firstChild)
  img.classList.remove("hide") if not err

module.exports = v.make()
