
FileDropper = require("file-dropper")
FileUploader = require("file-uploader")
TemplateRenderer = require("template-renderer")

class FileUploadView extends Backbone.View

  className: "file-upload-view"

  initialize: ( opts ) ->
    @url = opts.url
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @dropper = new FileDropper
      dropEl: @el
      directory: opts.directory
      multiple: opts.multiple
      types: opts.types
    @dropper.on "validated", @onValidated.bind(@)
    @dropper.on "activated", @onActivated.bind(@)
    @dropper.on "deactivated", @onDeactivated.bind(@)

  render: ->
    @renderer.render()
    @bg = @el.querySelector(".bg")
    @icon = @el.querySelector("i")

  upload: ( files ) ->
    @icon.classList.remove("fa-exclamation-circle")
    @icon.classList.remove("fa-check-circle")
    @icon.classList.add("fa-arrow-circle-o-up")
    @el.classList.add("working")
    @el.classList.remove("ready")
    @el.classList.remove("error")
    FileUploader.send
      url: @url
      files: files
      progress: @onProgress.bind(@)
      success: @onSuccess.bind(@)
      error: @onError.bind(@)

  setProgress: ( percent ) ->
    @bg.style.width = percent + "%"

  onProgress: ( e ) ->
    percent = (e.loaded / e.total) * 100
    @setProgress(percent)
    @trigger("upload-progress", percent)

  onSuccess: ( response ) ->
    @icon.classList.remove("fa-arrow-circle-o-up")
    @icon.classList.add("fa-check-circle")
    @el.classList.remove("working")
    @el.classList.add("ready")
    @trigger("upload-success", response)

  onError: ( response ) ->
    @icon.classList.remove("fa-arrow-circle-o-up")
    @icon.classList.add("fa-exclamation-circle")
    @el.classList.remove("working")
    @el.classList.add("error")
    @trigger("upload-error", response)

  onActivated: ->
    @el.classList.add("active")

  onDeactivated: ->
    @el.classList.remove("active")

  onValidated: ( valid, files ) ->
    @onDeactivated()
    if valid && files
      @upload(files)

module.exports = FileUploadView
