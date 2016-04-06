parse      = require("parse")
request    = require("superagent")
SuperModel = require("super-model")

class LabelModel extends SuperModel

  urlRoot: '/api/label'

  createAdmin: (email, password, done)->
    request
    .post("#{@url()}/create-admin")
    .withCredentials()
    .send
      email: email
      password: password
    .end (err, res)=>
      return done(err, res) if err = parse.superagent(err, res)
      done(null, res)

module.exports = LabelModel
