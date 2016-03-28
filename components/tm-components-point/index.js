
function Point ( x, y ) {
  this.x = x || 0;
  this.y = y || 0;
}

Point.clamp = function ( value, min, max ) {
  return Math.max(min, Math.min(value, max));
};

Point.prototype.clone = function () {
  return new Point(this.x, this.y);
};

Point.prototype.clampX = function ( value, min, max ) {
  this.x = Point.clamp(value, min, max);
};

Point.prototype.clampY = function ( value, min, max ) {
  this.y = Point.clamp(value, min, max);
};

Point.prototype.insideRectangle = function ( x, y, width, height ) {
  return this.x > x && this.x < x + width && this.y > y && this.y < y + height;
};

Point.prototype.onRectangle = function ( x, y, width, height ) {
  return this.x >= x && this.x <= x + width && this.y >= y && this.y <= y + height;
};

Point.prototype.getOffset = function ( x, y ) {
  return new Point(this.x - x, this.y - y);
};

module.exports = Point;