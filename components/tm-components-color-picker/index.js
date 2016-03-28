
var Color = require("color");
var Emitter = require('emitter');
var Point = require("point");
var autoscale = require("autoscale-canvas");

function Pane ( width, height ) {
  this.pos = new Point();
  this.scale = new Point();
  this.color = new Color();
  this.el = document.createElement("div");
  this.el.className = "pane";
  this.canvas = document.createElement("canvas");
  this.el.appendChild(this.canvas);
  this.active = false;
}

Pane.prototype.resize = function ( width, height ) {
  this.canvas.width = width;
  this.canvas.height = height;
  autoscale(this.canvas);
};

Pane.prototype.setPos = function( x, y ) {
  var ctx = this.canvas.getContext("2d");
  var scale = window.devicePixelRatio;
  var pos = this.pos.clone();
  pos.clampX(x * scale, 0, this.canvas.width - 1);
  pos.clampY(y * scale, 0, this.canvas.height - 1);

  var data = ctx.getImageData(pos.x, pos.y, 1, 1).data;
  this.color.set(data[0], data[1], data[2], 1);
  this.pos.x = x;
  this.pos.y = y;
};

function ColorPicker ( opts ) {
  opts = opts || {};
  this.size = opts.size || 180;
  this.el = document.createElement("div");
  this.el.className = "color-picker";
  this.shade = new Pane();
  this.shade.el.classList.add("shade");
  this.hue = new Pane();
  this.hue.el.classList.add("hue");
  this.hue.color.set(255, 0, 0);
  this.el.appendChild(this.shade.el);
  this.el.appendChild(this.hue.el);
  this.render();
  this.listeners = {
    down: this.onMouseDown.bind(this),
    up: this.onMouseUp.bind(this),
    move: this.onMouseMove.bind(this),
    selectstart: this.onSelectStart.bind(this)
  };
}

ColorPicker.prototype.appendTo = function ( el ) {
  el.appendChild(this.el);
  this.watch();
};

ColorPicker.prototype.remove = function () {
  this.el.remove();
  this.unwatch();
};

ColorPicker.prototype.watch = function () {
  this.el.addEventListener("selectstart", this.listeners.selectstart);
  window.addEventListener("mousedown", this.listeners.down);
  window.addEventListener("mouseup", this.listeners.up);
  window.addEventListener("mousemove", this.listeners.move);
};

ColorPicker.prototype.unwatch = function () {
  this.el.removeEventListener("selectstart", this.listeners.selectstart);
  window.removeEventListener("mousedown", this.listeners.down);
  window.removeEventListener("mouseup", this.listeners.up);
  window.removeEventListener("mousemove", this.listeners.move);
};

ColorPicker.prototype.resize = function ( size ) {
  this.size = size;
  this.render();
};

ColorPicker.prototype.getColor = function () {
  return this.shade.color;
};

ColorPicker.prototype.render = function () {
  this.renderHue();
  this.renderShade();
};

ColorPicker.prototype.renderHue = function () {
  var ctx = this.hue.canvas.getContext("2d");
  var w = this.size * 0.12;
  var h = this.size;

  this.hue.resize(w, h);

  var grad = ctx.createLinearGradient(0, 0, 0, h);
  grad.addColorStop(0, Color.rgb(255, 0, 0));
  grad.addColorStop(.15, Color.rgb(255, 0, 255));
  grad.addColorStop(.33, Color.rgb(0, 0, 255));
  grad.addColorStop(.49, Color.rgb(0, 255, 255));
  grad.addColorStop(.67, Color.rgb(0, 255, 0));
  grad.addColorStop(.84, Color.rgb(255, 255, 0));
  grad.addColorStop(1, Color.rgb(255, 0, 0));

  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, w, h);
};

ColorPicker.prototype.renderShade = function () {
  var ctx = this.shade.canvas.getContext("2d");
  var w = this.size;
  var h = this.size;

  this.shade.resize(w, h);

  var grad = ctx.createLinearGradient(0, 0, w, 0);
  grad.addColorStop(0, Color.rgb(255, 255, 255));
  grad.addColorStop(1, this.hue.color.toRGB());

  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, w, h);

  grad = ctx.createLinearGradient(0, 0, 0, h);
  grad.addColorStop(0, Color.rgba(255, 255, 255, 0));
  grad.addColorStop(1, Color.rgba(0, 0, 0, 1));

  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, w, h);
};

ColorPicker.prototype.isPointInPane = function ( point, pane ) {
  var rect = pane.canvas.getBoundingClientRect();
  return point.onRectangle(rect.left, rect.top, rect.width, rect.height);
};

ColorPicker.prototype.offsetForPane = function ( point, pane ) {
  var rect = pane.canvas.getBoundingClientRect();
  return point.getOffset(rect.left, rect.top);
};

ColorPicker.prototype.updateHue = function ( point ) {
  this.hue.setPos(point.x, point.y);
  this.renderShade();
  this.shade.setPos(this.shade.pos.x, this.shade.pos.y);
  this.emit("change", this.shade.color);
};

ColorPicker.prototype.updateShade = function ( point ) {
  this.shade.setPos(point.x, point.y);
  this.emit("change", this.shade.color);
};

ColorPicker.prototype.onMouseDown = function ( e ) {
  var p = new Point(e.clientX, e.clientY);
  if ( this.isPointInPane(p, this.hue) ) {
    this.hue.active = true;
    this.updateHue(this.offsetForPane(p, this.hue));
  }
  else if ( this.isPointInPane(p, this.shade) ) {
    this.shade.active = true;
    this.updateShade(this.offsetForPane(p, this.shade));
  }
};

ColorPicker.prototype.onMouseMove = function ( e ) {
  if ( this.hue.active ) {
    this.updateHue(this.offsetForPane(new Point(e.clientX, e.clientY), this.hue));
  }
  else if ( this.shade.active ) {
    this.updateShade(this.offsetForPane(new Point(e.clientX, e.clientY), this.shade));
  }
};

ColorPicker.prototype.onMouseUp = function ( e ) {
  this.hue.active = false;
  this.shade.active = false;
};

ColorPicker.prototype.onSelectStart = function ( e ) {
  e.preventDefault();
  return false;
};

Emitter(ColorPicker.prototype);

module.exports = ColorPicker;
