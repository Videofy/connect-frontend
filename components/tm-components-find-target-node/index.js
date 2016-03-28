module.exports = function findTargetNode (el, condition) {
  var target = el;
  while (target && !condition(target)) {
    target = target.parentNode;
  }
  return target;
};