require =
  baseUrl: '/static'
  paths:
    jquery: 'vendors/jquery/dist/jquery.min'
    underscore: 'vendors/underscore/underscore'
    backbone: 'vendors/backbone/backbone'
    domReady: 'vendors/requirejs-domready/domReady'
  shim:
    underscore:
      exports: '_'
    backbone:
      deps: ["jquery", "underscore"]
      exports: "Backbone"
