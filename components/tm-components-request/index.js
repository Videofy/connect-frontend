
var Emitter = require("emitter");

function Request ( config ) {
  this.url = config.url || "";
  this.method = config.method || "GET";
  this.async = config.async == undefined || config.async == null ? true : config.async;
  this.user = config.user;
  this.password = config.password;
  this.mime = config.mime;
  this.headers = config.headers;
  this.data = config.data;
}

Request.prototype.send = function () {
  this.abort();

  var x = this.xhr = new XMLHttpRequest();
  x.open(this.method, this.url, this.async, this.user, this.password);

  if ( this.mime ) {
    x.overrideMimeType(this.mime);
  }

  if ( this.headers ) {
    for ( header in this.headers ) {
      x.setRequestHeader(header, this.headers[header]);
    }
  }

  if ( this.async ) {
    var self = this;
    x.onreadystatechange = function () {
      if ( x.readyState == 4 ) {
        self.emit("completed", x.status, x.responseText, x);
      }
      else if ( x.readyState == 3 ) {
        self.emit("progress", x);
      }
      else if ( x.readyState == 2 ) {
        self.emit("recieved", x);
      }
    }
  }

  if ( this.data ) {
    x.send(this.data);
  }
  else {
    x.send();
  }

  return x;
};

Request.prototype.abort = function () {
  if ( this.xhr ) {
    if ( this.xhr.readyState != 4 ) {
      this.emit("aborted");
    }
    this.xhr.abort();
    delete this.xhr;
  }
};

var methods = [
  "connect",
  "delete",
  "get",
  "head",
  "options",
  "patch",
  "post",
  "put",
  "trace"
];

for ( var i = 0; i < methods.length; i++ ) {
  var method = methods[i];
  Request[method] = (function ( method ) {
    return function ( config ) {
      config.method = method.toUpperCase();
      var r = new Request(config);
      r.send();
      return r;
    };
  })(method);
}

Emitter(Request.prototype);

module.exports = Request;
