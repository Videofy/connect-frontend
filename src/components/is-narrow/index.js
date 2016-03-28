module.exports = function (w) {
  if(w == null) { w = 1024; }
  return document.body.getBoundingClientRect().width <= w
}
