function StringUtil() {}

StringUtil.camelize = function ( str ) {
  str = str.trim().replace(/[-_\s]+(.)?/g, function(match, c) {
    return c ? c.toUpperCase() : "";
  });
  return str;
}

StringUtil.capitalize = function ( str ) {
  return str.substr(0, 1).toUpperCase() + str.substr(1).toLowerCase()
}

module.exports = StringUtil;