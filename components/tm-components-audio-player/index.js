
var Point = require("point");
var Emitter = require("emitter");

function getRandomElement (items) {
  return items[Math.floor(Math.random()*items.length)];
}

function AudioPlayer () {
  this.items = [];
  this.index = -1;
  this.continuous = true;
  this.loop = false;
  this.shuffle = false;
  this.vol = 1.0;
  this.autoRestart = true;
  this.restartCount = 0;
  this.restartRate = 200;
  this.currentTime = 0;
  this.listeners = {
    audio: {
      error: this.onAudioError.bind(this),
      ended: this.onAudioEnded.bind(this),
      play: this.onAudioPlay.bind(this),
      timeupdate: this.onAudioPlaying.bind(this)
    }
  };
  this.clearPlayed();
}


Emitter(AudioPlayer.prototype);

AudioPlayer.prototype.add = function ( item ) {
  if ( item && item.source && typeof item.source == "string" ) {
    this.items.push(item);
    this.emit("add", item);
    return this.items.length - 1;
  }
  return -1;
};

AudioPlayer.prototype.addAndPlay = function ( item ) {
  var index = this.add(item);
  if ( index >= 0 ) {
    this.play(index);
  }
};

AudioPlayer.prototype.remove = function ( item ) {
  var index = this.items.indexOf(item);
  if ( index > -1 ) {
    if ( index == this.index ) {
      this.killAudio();
    }

    this.items.splice(index, 1);

    // Fix the current index.
    if ( this.index > index ) {
      this.index--;
    }

    // Fix played array.
    for (var i = 0; i < this.played.length; i++){
      if ( this.played[i] > index ) this.played[i] = this.played[i]-1;
    }

    this.emit("remove", item);
  }
};

// Sets the items list without disrupting the player.
AudioPlayer.prototype.set = function (items) {
  var item = this.getItem(this.getIndex());
  var self = this;
  
  if ( item ) {
    items.forEach(function(nitem, i, arr){
      if ( nitem.source == item.source ) {
        self.index = i;
      }
    });
  }

  this.items = items;
  this.clearPlayed();
  this.emit("set");
};

AudioPlayer.prototype.clear = function () {
  while ( this.items.length ) {
    this.remove(this.items[0]);
  }
  this.index = -1;
};

AudioPlayer.prototype.createAudio = function ( source ) {
  audio = new Audio(source);
  audio.source = source;
  audio.volume = this.vol;
  for ( var key in this.listeners.audio ) {
    audio.addEventListener(key, this.listeners.audio[key]);
  }
  return audio;
};

AudioPlayer.prototype.destroyAudio = function ( audio ) {
  if ( !audio ) return;
  for ( var key in this.listeners.audio ) {
    audio.removeEventListener(key, this.listeners.audio[key]);
  }
};

AudioPlayer.prototype.killAudio = function () {
  if ( !this.audio ) return;
  this.stop();
  this.destroyAudio(this.audio);
  delete this.audio;
};

AudioPlayer.prototype.play = function ( index ) {
  var index = this.getIndex(index);
  var item = this.items[index];
  var source = (item || {}).source;
  if ( !source ) return false;

  var changed = false;
  if ( index != this.index || 
    (this.audio && this.audio.source != source) || 
    !this.audio ) {
    this.index = index;
    changed = true;
  }

  if ( changed ) {
    this.killAudio();
    this.audio = this.createAudio(source);
    this.emit("change");
  }

  if (this.restartCount > 0) {
    this.audio = this.createAudio(source) 
    this.audio.currentTime = this.currentTime; // set currentTime when song gets restarted
    this.emit("restart");
  }

  this.temp = item;
  this.audio.play();
  this.emit("play", item);
  return true;

};

AudioPlayer.prototype.getIndex = function(index) {
  index = index == null ? this.index : index;
  return this.items.length > 0 && index == -1 ? 0 : index;
}


AudioPlayer.prototype.getItem = function(index) {
  return this.items[this.getIndex(index)];
}

AudioPlayer.prototype.getTempItem = function() {
  return this.getItem() || this.temp;
};

AudioPlayer.prototype.pause = function () {
  if ( !this.audio || this.audio.error ) return;
  this.audio.pause();
  this.emit("pause", this.getTempItem());
};

AudioPlayer.prototype.getEventData = function (){
  data = this.temp
  data.playedTime = this.audio.currentTime;
  return data
}

AudioPlayer.prototype.stop = function () {
  if ( !this.audio || this.audio.error ) return;
  this.emit("stop", this.getEventData());
  this.audio.pause();
  this.audio.currentTime = 0.0;
};

AudioPlayer.prototype.next = function () {
  var index = this.index;
  this.played.push(index);

  // Get the next track based on the mode.
  if ( this.shuffle ) {
    index = getRandomElement(this.getUnplayed());
    if(isNaN(index)) index = -1;
  }
  else {
    index += 1;
  }

  // Reset the played tracks and start over.
  if ( this.loop && this.invalidIndex(index) ) {
    this.clearPlayed();
    if ( this.shuffle ) {
      index = getRandomElement(this.getUnplayed());
    }
    else {
      index = 0;
    }
  }

  if ( this.invalidIndex(index) ) return;

  this.stop();
  this.emit("next", this.getItem(index));
  this.play(index);
};

AudioPlayer.prototype.previous = function () {
  var index = this.played.pop() || this.index - 1;

  if ( this.loop && this.invalidIndex(index) ) {
    this.clearPlayed();
    if ( this.shuffle ) {
      index = getRandomElement(this.getUnplayed());
    }
    else {
      index = this.items.length - 1;
    }
  }

  if ( this.invalidIndex(index) ) return;

  this.stop();
  this.emit("previous", this.getItem(index));
  this.play(index);
};

AudioPlayer.prototype.volume = function ( value ) {
  var volume = Point.clamp(value, 0.0, 1.0);

  if ( this.vol != volume ) {
    this.vol = volume;
    this.emit("volume", this.getTempItem(), volume);
  }

  if ( this.audio ) {
    this.audio.volume = this.vol;
  }

  return this.vol;
};

AudioPlayer.prototype.seek = function ( percent ) {
  if ( !this.audio || this.audio.error ) return;

  percent = Point.clamp(percent, 0.0, 1.0);
  try {
    this.audio.currentTime = percent * this.audio.duration;
  }
  catch (e) {
    console.log("A seek error occured.\n"+e);
  }
};

AudioPlayer.prototype.clearPlayed = function () {
  this.played = [];
}

AudioPlayer.prototype.getUnplayed = function () {
  var played = this.played;
  var arr = this.items.map(function(v, i, a){ return i;});
  for ( var i = 0; i < played.length; i++ ) {
    var num = played[i];
    var index = arr.indexOf(num);
    if ( index > -1 ) {
      arr.splice(index, 1);
    }
  }
  return arr;
};

AudioPlayer.prototype.restartPlay = function () {
  this.restartCount++;
  setTimeout((function(){
    this.play();
  }).bind(this), this.restartCount * this.restartRate)
};

AudioPlayer.prototype.invalidIndex = function(index) {
  return (index < 0 || index >= this.items.length);
};


AudioPlayer.prototype.onAudioError = function ( e ) {
  ev = {
    name: 'error',
    shouldRestart: this.autoRestart,
    item: this.getTempItem()
  }
  this.emit("error", ev.item, ev);
  if (ev.shouldRestart) this.restartPlay();
};

AudioPlayer.prototype.onAudioEnded = function( e ) {
  this.emit("ended", this.getTempItem());
  if ( this.continuous ) {
    this.next();
  }
};

AudioPlayer.prototype.onAudioPlay = function () {
  this.restartCount = 0;
};

AudioPlayer.prototype.onAudioPlaying = function () {
  this.currentTime = this.audio.currentTime; 
};

module.exports = AudioPlayer;
