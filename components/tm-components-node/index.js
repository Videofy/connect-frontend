
var matchesSelector = require("matches-selector");

function Node () {}

Node.prependChild = function ( node, parent ) {
  parent.insertBefore(node, parent.firstChild);
};

Node.empty = function ( node ) {
  while ( node.firstChild ) {
    node.removeChild(node.firstChild);
  }
};

Node.getChildIndex = function ( node, child ) {
  for ( var i = 0; i < node.children.length; i++ ) {
    if ( child == node.children[i] ) {
      return i;
    }
  }
  return -1;
};

Node.hasParent = function ( node, parent ) {
  var p = node.parentNode;
  while ( p != null ) {
    if ( p == parent ) {
      return true;
    }
    p = p.parentNode;
  }
  return false;
};

Node.findParent = function ( node, selector ) {
  var p = node.parentNode;
  while ( p != null ) {
    if ( p != document && Node.isSelector(p, selector) ) {
      return p;
    }
    p = p.parentNode;
  }
}

Node.isSelector = function ( node, selector ) {
  return matchesSelector(node, selector);
}

module.exports = Node;