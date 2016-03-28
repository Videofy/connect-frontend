module.exports = function() {
  var a = document.createElement('a');
  if(typeof a.download !== 'undefined'){
    return true;
  } else {
    return false;
  }
}
