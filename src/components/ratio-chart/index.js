var Chart = require("chart")
var Color = require("color")
var Ratio = require("ratio")

// Creates an array with n(count) colors.
function distinctColors(count, s, v) {
  if (s == void 0) s = 100
  if (v == void 0) v = 100
  var colors = [];
  for(hue = 0; hue < 360; hue += 360 / count) {
    colors.push(Color.fromHsv(hue, s, v).toHex(true))
  }
  return colors;
}

// Breaks down data into a format that ChartJS can read.
function appropriate (ratios) {
  var arr = []
  var left = new Ratio(1)
  // Add one for missing piece.
  var colors = distinctColors(ratios.length + 1, 60, 100)
  var highlights = distinctColors(ratios.length + 1, 100, 100)

  ratios.forEach(function (ratio) {
    arr.push({
      color: colors.shift(),
      highlight: highlights.shift(),
      label: ratio.label,
      value: ratio.value.valueOf()
    })
    left = left.minus(ratio.value)
  })

  if (!left.valueOf() !== 0) {
    arr.push({
      color: colors.shift(),
      highlight: highlights.shift(),
      label: "Remaining",
      value: left.valueOf()
    })
  }

  return arr
}

function RatioChart (opts) {
  this.size = opts.size
  this.type = opts.type || "Pie"
  this.chartOpts = opts.chart || {}
  this.el = document.createElement(opts.tagName || "div")
  if (opts.className) this.el.className = opts.className
  this.canvas = document.createElement("canvas")
  this.el.appendChild(this.canvas)
}

RatioChart.prototype = {
  // Updates the chart display with the ratio items provided.
  set: function (ratios) {
    if (this.chart) this.chart.destroy()

    var ctx = this.canvas.getContext('2d')
    this.canvas.setAttribute("width", this.size)
    this.canvas.setAttribute("height", this.size)
    this.chart = new Chart(ctx)[this.type](appropriate(ratios), this.chartOpts)
  }
}

module.exports = RatioChart