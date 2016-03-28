var Point = require("point");

// See: http://www.javascripter.net/faq/rgbtohex.htm
var hexchars = "0123456789ABCDEF"
function hex ( n ) {
  n = parseInt(n, 10)
  if (isNaN(n)) return "00"
  n = Math.max(0, Math.min(n, 255))
  return hexchars.charAt((n - n % 16) / 16) + hexchars.charAt(n % 16)
}

function Color (r, g, b, a) {
  this.set(r, g, b, a)
}

Color.rgb = function (r, g, b) {
  return "rgb(" + r + ", " + g + ", " + b + ")"
};

Color.rgba = function (r, g, b, a) {
  return "rgba(" + r + ", " + g + ", " + b + ", " + a + ")"
};

Color.hex = function (r, g, b) {
  return hex(r) + hex(g) + hex(b)
};

Color.validHex = function ( str ) {
  return /^([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(str)
}

/**
 * H runs from 0 to 360 degree s
 * S and V run from 0 to 100
 *
 * Ported from the excellent java algorithm by Eugene Vishnevsky at:
 * http://www.cs.rit.edu/~ncs/color/t_convert.html
 *
 * http://snipplr.com/view.php?codeview&id=14590
 */
Color.hsvToRgb = function (h, s, v) {
  var r, g, b, i, f, p, q, t

  // Make sure our arguments stay in-range
  h = Math.max(0, Math.min(360, h))
  s = Math.max(0, Math.min(100, s))
  v = Math.max(0, Math.min(100, v))

  // We accept saturation and value arguments from 0 to 100 because that's
  // how Photoshop represents those values. Internally, however, the
  // saturation and value are calculated from a range of 0 to 1. We make
  // That conversion here.
  s /= 100
  v /= 100

  if (s == 0) {
    // Achromatic (grey)
    r = g = b = v
    return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)]
  }

  h /= 60 // sector 0 to 5
  i = Math.floor(h)
  f = h - i // factorial part of h
  p = v * (1 - s)
  q = v * (1 - s * f)
  t = v * (1 - s * (1 - f))

  switch (i) {
    case 0:
      r = v;
      g = t;
      b = p;
      break;
    case 1:
      r = q;
      g = v;
      b = p;
      break;
    case 2:
      r = p;
      g = v;
      b = t;
      break;
    case 3:
      r = p;
      g = q;
      b = v;
      break;
    case 4:
      r = t;
      g = p;
      b = v;
      break;
    default: // case 5:
      r = v;
      g = p;
      b = q;
  }

  return {
    r: Math.round(r * 255),
    g: Math.round(g * 255),
    b: Math.round(b * 255)
  }
}

Color.fromHsv = function (h, s, v) {
  var cl = Color.hsvToRgb(h, s, v)
  return new Color(cl.r, cl.g, cl.b, 1)
}

Color.prototype.set = function(r, g, b, a) {
  if (r == void 0) r = 0
  if (g == void 0) g = 0
  if (b == void 0) b = 0
  if (a == void 0) a = 1
  this.r = Point.clamp(r, 0, 255).toFixed(0)
  this.g = Point.clamp(g, 0, 255).toFixed(0)
  this.b = Point.clamp(b, 0, 255).toFixed(0)
  this.a = Point.clamp(a, 0, 1.0)
}

Color.prototype.clone = function() {
  return new Color(this.r, this.g, this.b, this.a)
}

Color.prototype.toRGB = function () {
  return Color.rgb(this.r, this.g, this.b)
}

Color.prototype.toRGBA = function () {
  return Color.rgba(this.r, this.g, this.b, this.a)
}

Color.prototype.toHex = function ( pound ) {
  return ( pound ? "#" : "" ) + Color.hex(this.r, this.g, this.b)
}

module.exports = Color;