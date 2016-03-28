SuperModel = require('super-model')
upload     = require('file-uploader')
parse      = require('parse')

class ArticleModel extends SuperModel

  urlRoot: '/api/article'

  getDownloadUri: ->
    "#{@url()}/#{@attributes.filename}"

  upload: (file, done)->
    upload.files
      method: 'put'
      url: "#{@url()}/#{file.name}"
      files: [file]
    , (err, res)=>
      err = parse.superagent(err, res)
      @set(res.body) unless err
      done(err)

  hasAttachment: ->
    !!(@attributes.filename and @attributes.hash)

module.exports = ArticleModel
