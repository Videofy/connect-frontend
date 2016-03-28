
function Regex () {}

Regex.escapeString = function ( str ) {
  // See http://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
};

module.exports = Regex;
