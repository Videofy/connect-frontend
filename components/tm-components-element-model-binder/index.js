
/* Creates a new binder.
 * @opts is a map that specifies the model's get, set, and save methods.
 */
function ElementModelBinder ( opts ) {
  this.modelGet = opts.get;
  this.modelSet = opts.set;
  this.modelSave = opts.save;
  this.bindings = [];
}

ElementModelBinder.prototype.getBindingForEl = function ( el ) {
  var count = this.bindings.length;
  for ( var i = 0; i < count; i++ ) {
    if ( this.bindings[i] == el ) {
      return this.bindings[i];
    }
  }
  return null;
};

/* Binds an element to the model.
 * @opts is a map of properties to customize the binding. 
 * The @opts map is as follows:
 * @opts.el - The element to listen to.
 * @opts.property - The property to mutate on the model.
 * @opts.ev - The event to listen for on the element. 
      By default this is "input".
 * @opts.immediate - Determines if the new value on the element should be 
      saved immediately or delay to wait for any other changes. 
      This is good for rapid typing.
 * @opts.value(el) - A function to retrieve a custom value from the element. 
      By default the el.value property is used unless this is specified.
 * @opts.validator(value, oldvalue) - A function that validates the elements 
      value before saving. No validation is done unless this is passed.
 */
ElementModelBinder.prototype.bindEl = function ( opts ) {
  var binding;

  if (opts == null) {
    opts = {
      el: null,
      property: ""
    };
  }

  if ( !(opts.el === !null && opts.property === !"") ) {
    this.unbindEl(opts.el);
    binding = opts;
    binding.ev = binding.ev || "input";
    binding.timer = -1;
    binding.callback = this.onEvent.bind(this, binding);
    binding.el.addEventListener(binding.ev, binding.callback);
    this.bindings.push(binding);
  }
};

ElementModelBinder.prototype.unbindEl = function(el) {
  var binding = this.getBindingForEl(el);
  if (binding) {
    unbindBinding(binding);
  }
};

ElementModelBinder.prototype.unbindBinding = function(binding) {
  var index = this.bindings.indexOf(binding);
  if ( index > -1 ) {
    binding.el.removeEventListener(binding.ev, binding.callback);
    clearTimeout(binding.timer);
    this.bindings.splice(index, 1);
  }
};

ElementModelBinder.prototype.bindBatch = function ( arr, opts ) {
  if (opts == null) {
    opts = {};
  }

  var count = arr.length;
  for ( var i = 0; i < count; i++ ) {
    var item = arr[i];
    this.bindEl({
      el: item.el,
      property: item.property || opts.property,
      ev: item.ev || opts.ev,
      immediate: item.immediate || opts.immediate,
      validator: item.validator || opts.validator,
      value: item.value || opts.value
    });
  }
};

ElementModelBinder.prototype.reset = function () {
  var count = this.bindings.length;
  for ( var i = 0; i < count; i++ ) {
    this.unbindBinding(this.bindings[i]);
  }
};

ElementModelBinder.prototype.onEvent = function ( binding ) {
  clearTimeout(binding.timer);

  if (binding.immediate) {
    this.save(binding);
  } 
  else {
    binding.timer = setTimeout(this.save.bind(this, binding), 500);
  }
};

ElementModelBinder.prototype.save = function ( binding ) {
  var value;
  value = binding.el.value;

  if (binding.value) {
    value = binding.value(binding.el);
  }

  if (!binding.validator || 
      (binding.validator && 
      binding.validator(value, this.modelGet(binding.property), binding.el))) {
    this.modelSet(binding.property, value);
    if ( this.modelSave ) {
      this.modelSave();
    }
  }
};

ElementModelBinder.getCheckboxValue = function ( el ) {
  return el.checked;
};

ElementModelBinder.getSelectValue = function ( el ) {
  var option = el.options[el.selectedIndex];
  if ( option ) {
    return option.value;
  }
  return undefined;
};

module.exports = ElementModelBinder;
