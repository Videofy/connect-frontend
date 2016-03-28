var async = {};
var ap = require('ap');
var each = require('each');
async.map = require('async-map');

module.exports = function (o) {
  o = o || {};
  o.view = o.view || o.createView;
  o.element = o.element || o.createElement;

  return function (v) {
    function container(view) {
      var tag = ap.call(view, o.tag);
      return ap.call(view, o.container) || tag? view.$(tag) : view.$el;
    }

    function insert(subview, $container) {
      if (o.append)
        $container.append(subview);
      else
        $container.prepend(subview);
    }

    function getEl(view, model) {
      var subview, el;
      if (o.view) {
        subview = o.view.call(view, model);
        subview.render();
        el = subview.el;
      }
      else {
        el = o.element.call(view, model);
      }

      return el;
    }

    function one(collection, $container, model, view) {
      var el = getEl(view, model);
      insert(el, $container);
      view.trigger("add:collection:view", collection, el, model);
    }

    function all(collection, view) {
      var $container = container(view);
      var frag = document.createDocumentFragment();

      var render = function(model, cb) {
        _.defer(function(){
          var el = getEl(view, model);
          cb(null, el);
        });
      };

      async.map(collection.models, render, function(err, els){
        each(els, function(el){
          frag.appendChild(el);
        });

        insert(frag, $container);
        view.trigger("rendered:collection", collection, $container. frag);
      });
    }

    v.init(function (opts) {
      opts = opts || {};
      var self = this;
      var a = ap.bind(this);
      var collection = a(o.collection) || this.collection;

      var prerender = collection.length > 0;

      this.on('render', function(){
        if (collection.length > 0) all(collection, self);
      });

      collection.on('add', function ( model ) {
        one(collection, container(self), model, self);
      });

      collection.on('reset', function(){
        all(collection, self);
      });

      collection.on('sort', function(){
        all(collection, self);
      });

    });
  };
};
