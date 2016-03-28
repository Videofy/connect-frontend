
function KeyValueMap () {
  this.clear();
}

/* Sets the value for the key given.
 * @key - Any type.
 * @value - Any type.
 */
KeyValueMap.prototype.set = function ( key, value ) {
  var index = this.keys.indexOf(key)
  if ( index > -1 ) {
    this.values[index] = value;
  }
  else {
    this.keys.push(key);
    this.values.push(value);
    this.length++;
  }
};

/* Gets the value for the key.
 * @key - Any type.
 */
KeyValueMap.prototype.get = function ( key ) {
  var index = this.keys.indexOf(key)
  if ( index > -1 ) {
    return this.values[index];
  }
  return null;
};

/* Deletes the key value pair from the map.
 * @key - Any type.
 * @value - Any type.
 */
KeyValueMap.prototype.delete = function ( key ) {
  var index = this.keys.indexOf(key)
  if ( index > -1 ) {
    this.keys.splice(index, 1);
    this.values.splice(index, 1);
    this.length--;
  }
};

KeyValueMap.prototype.clear = function () {
  this.keys = [];
  this.values = [];
  this.length = 0;
};

module.exports = KeyValueMap;