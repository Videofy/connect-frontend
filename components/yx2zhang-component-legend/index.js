function Legend  ( opts ) {
  var opts = opts || {};
  var title = opts.title
  var items = opts.items
  this.element = document.createElement("div");
  this.element.className = "legend"

  this.legendTitle = document.createElement("div");
  this.legendTitle.className = "legend-title"
  this.legendTitle.innerHTML = opts.title

  this.legendList = document.createElement("div");
  this.legendList.className = "legend-list";

  this.element.appendChild(this.legendTitle)
  this.element.appendChild(this.legendList)

  for (var i = 0; i<items.length; i++){
    var row = document.createElement("div");
    row.className = "legend-row"

    var key = items[i].key;
    key.classList.add("legend-key")

    var value  = document.createElement("div");
    value.classList.add("legend-value")
    value.innerHTML = items[i].value

    row.appendChild(key);
    row.appendChild(value);

    this.legendList.appendChild(row)
  }
}

module.exports = Legend
