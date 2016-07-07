
function isInputElement ( el ) {
  if(!el) {
    return false;
  }
  var tag = el.tagName.toLowerCase();
  return tag === "input" || tag === "textarea";
}

function Enabler ( el ) {
  this.el = el;
}

Enabler.getEl = function ( el, selector ) {
  if ( !selector ) {
    return el;
  }
  else if ( selector.tagName ) {
    return selector;
  }
  return el.querySelector(selector);
};

Enabler.prototype.getEl = function ( selector ) {
  return Enabler.getEl(this.el, selector);
};

Enabler.prototype.evaluateDisabled = function ( selector, evaluation ) {
  var el = this.getEl(selector);
  if ( el.disabled != undefined ) {
    el.disabled = !!evaluation;
  }
  else {
    if ( evaluation ) {
      el.setAttribute("disabled", "disabled");
    }
    else {
      el.removeAttribute("disabled");
    }
  }
};

Enabler.prototype.evaluateClass = function ( selector, className, evaluation ) {
  if ( evaluation == undefined ) {
    evaluation = className;
    className = selector;
    selector = this.getEl();
  }
  if ( evaluation ) {
    this.getEl(selector).classList.add(className); return;
  }
  this.getEl(selector).classList.remove(className);
};

Enabler.prototype.setText = function ( selector, value ) {
  var el = this.getEl(selector);

  if ( isInputElement(el) ) {
    el.value = value; return;
  }

  el.textContent = value;
};

Enabler.prototype.setHtml = function ( selector, value ) {
  this.getEl(selector).innerHTML = value;
};

Enabler.prototype.getValue = function ( selector ) {
  var el = this.getEl(selector);

  if ( isInputElement(el) ) {
    return el.value;
  }
  return el.textContent;
};

Enabler.prototype.bind = function ( selector, ev, callback ) {
  this.getEl(selector).addEventListener(ev, callback);
};

Enabler.prototype.bindAll = function(selector, ev, callback) {
  var arr = this.getEl().querySelectorAll(selector);
  for (var i=0; i<arr.length; i++) {
    arr[i].addEventListener(ev, callback);
  }
};

Enabler.prototype.unbind = function ( selector, ev, callback ) {
  this.getEl(selector).removeEventListener(ev, callback);
};

Enabler.prototype.unbindAll = function(selector, ev, callback) {
  var arr = this.getEl().querySelectorAll(selector);
  for (var i=0; i<arr.length; i++) {
    arr[i].removeEventListener(ev, callback);
  }
};

module.exports = Enabler;
