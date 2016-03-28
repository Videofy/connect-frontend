var Emitter = require("emitter");
var KeyValueMap = require("key-value-map");

function FileDropper ( opts ) {
  opts = opts || {};
  this.listener = this.onInputChange.bind(this);
  this.dlisteners = {};
  this.dlisteners["click"] = this.onClick.bind(this);
  this.dlisteners["dragenter"] = this.onDragEnter.bind(this);
  this.dlisteners["dragleave"] = this.onDragLeave.bind(this);
  this.dlisteners["dragover"] = this.onDragOver.bind(this);
  this.dlisteners["drop"] = this.onDrop.bind(this);
  this.input = document.createElement("input");
  this.input.setAttribute("type", "file");
  this.input.setAttribute("aria-hidden", true);
  this.input.style.display = "none";
  this.input.style.position = "absolute";
  this.validation = new KeyValueMap();
  this.init(opts);
}

FileDropper.prototype.init = function ( opts ) {
  this.destroy();
  this.input.multiple = !!opts.multiple;
  this.input.directory = this.input.webkitdirectory = this.input.mozdirectory = !!opts.directory;

  if ( opts.capture ) {
    this.input.setAttribute("capture", opts.capture);
  }

  if ( opts.types ) {
    this.input.accept = opts.types && opts.types.join ? opts.types.join(",") : opts.types;
    this.types = this.input.accept.split(",");
  }
  else {
    this.types = [];
  }
  
  this.input.addEventListener("change", this.listener);

  if (opts.el && !opts.dropEl) opts.dropEl = opts.el;

  if ( opts.dropEl ) {
    this.dropEl = opts.dropEl;
    for ( var key in this.dlisteners ) {
      this.dropEl.addEventListener(key, this.dlisteners[key]);
    }
  }
};

FileDropper.prototype.destroy = function() {
  this.validation.clear();
  this.input.removeEventListener("change", this.listener);
  this.input.removeAttribute("capture");
  if ( this.input.parentElement ) {
    this.input.parentElement.removeChild(this.input);
  }
  if ( this.dropEl ) {
    for ( var key in this.dlisteners ) {
      this.dropEl.removeEventListener(key, this.dlisteners[key]);
    }
  }
};

FileDropper.prototype.appendInput = function() {
  document.body.appendChild(this.input);
};

FileDropper.prototype.pick = function () {
  this.appendInput();
  this.input.click();
};

FileDropper.prototype.validate = function ( files ) {
  var opts = this.input;
  this.validation.clear();

  if ( !opts.multiple && files.length > 1 ) {
    this.fireValidated(false, undefined);
  }
  else {
    for ( var i = 0; i < files.length; i++ ) {
      this.validation.set(files[i], this.validateFile(files[i]));
    }
    this.checkFilesValidation();
  }
};

FileDropper.prototype.validateFile = function ( file ) {
  if ( this.types && 
      (
        ( !this.types.join && this.types != file.type ) || 
        this.types.length > 0 && this.types.indexOf(file.type) == -1 
      )
     ) {
    return "invalid";
  }
  else if ( !file.type && !this.input.directory ) {
    var fr = new FileReader();
    fr.onerror = this.onFileReaderError.bind(this, file);
    fr.onprogress = this.onFileReaderProgress.bind(this, file);
    fr.readAsText(file);
    return "pending";
  }
  return "valid";
};

FileDropper.prototype.checkFilesValidation = function () {
  var valid = 0;
  var invalid = 0;
  var total = this.validation.keys.length;
  for ( var i = 0; i < total; i++ ) {
    var status = this.validation.get(this.validation.keys[i]); 
    if ( status == "valid" ) {
      valid++;
    }
    else if ( status == "invalid" ) {
      invalid++;
    }
  }

  if ( valid == total ) {
    this.fireValidated(true, this.validation.keys);
  }
  else if ( invalid == total ) {
    this.fireValidated(false, undefined);
  }
};

FileDropper.prototype.fireFilesChanged = function( files ) {
  this.emit("changed", files);
};

FileDropper.prototype.fireValidated = function ( valid, files ) {
  this.emit("validated", !!valid, files);
};

FileDropper.prototype.onInputChange = function ( e ) {
  this.fireFilesChanged(this.input.files);
  this.fireValidated(true, this.input.files);
};

FileDropper.prototype.onFileReaderError = function ( file, e ) {
  this.validation.set(file, "invalid");
  this.checkFilesValidation();
};

FileDropper.prototype.onFileReaderProgress = function( file, e ) {
  var fr = e.target;
  fr.abort();
  this.validation.set(file, "valid");
  this.checkFilesValidation();
};

FileDropper.prototype.onClick = function ( e ) {
  e.preventDefault();
  e.stopPropagation();
  this.pick();
};

FileDropper.prototype.onDragEnter = function ( e ) {
  e.preventDefault();
  e.stopPropagation();
  this.emit("activated");
};

FileDropper.prototype.onDragLeave = function ( e ) {
  e.preventDefault();
  e.stopPropagation();
  this.emit("deactivated");
};

FileDropper.prototype.onDragOver = function ( e ) {
  e.preventDefault();
  e.stopPropagation();
};

FileDropper.prototype.onDrop = function ( e ) {
  e.preventDefault();
  e.stopPropagation();
  this.appendInput();
  this.fireFilesChanged(e.dataTransfer.files);
  this.validate(e.dataTransfer.files);
};

Emitter(FileDropper.prototype);

module.exports = FileDropper;