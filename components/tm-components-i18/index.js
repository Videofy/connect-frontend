
var SuperAgent = require("superagent");
var Emitter = require("emitter");

function I18 () {
  this.locale = "";
  this.strings = {};
  this.events = new Emitter();
}

I18.prototype.set = function ( locale, strings ) {
  this.locale = locale;
  this.strings = strings;
  this.events.emit("change");
};

I18.prototype.load = function ( url, done ) {
  SuperAgent
    .get(url)
    .end((function ( err, res ) {
      if ( res.status != 200 )
        return done(new Error(
          "Recieved an invalid response from the server."));
      else if ( !res.body || !res.body.locale || !res.body.strings ) 
        return done(new Error("Missing body parameters."));
      this.set(res.body.locale, res.body.strings);
      done(undefined, this);
    }).bind(this));
};

module.exports = I18;