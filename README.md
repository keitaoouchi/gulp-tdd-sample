# RequireJSのモジュールをTDDで開発するための環境構築とGulpfile.coffee

## 付帯目標
* CoffeeScriptで書きたいので*.cofeeをウォッチして自動でコンパイルさせたい
* Sassとかも使いたい
* mochaをブラウザで走らせたいのでテスト用のサーバーをexpressで構築する
* LiveReloadでテスト用のページを更新させる
* 以上のタスクをgruntコマンド一発で立ち上げたい
* その環境構築をnpm installを含む最低限の準備で済ませたい

## 構成方針
```
.
├── devel
│   ├── coffee
│   ├── node_modules
│   ├── sass
│   └── test
│       ├── coffee
│       └── js
└── static
    ├── css
    ├── img
    ├── js
    └── vendors
```

コンパイルすると
devel/cofee -> static/js
devel/sass -> static/css
test/coffee -> test/js
に自動的に配置されるようにする。

devel/node_modulsはgulpで使うモジュール、static/vendorsにはbowerでインストールする3rdパーティーのファイル。

## サンプルソース

https://github.com/keitaoouchi/gulp-tdd-sample

## 試す

事前にbunlder、bowerの導入が必要。

```bash
npm install -g bower gulp
```

```bash
gem install bundler
```

```bash
git clone https://github.com/keitaoouchi/gulp-tdd-sample
cd gulp-tdd-sample/devel
npm install
gulp setup
gulp
```

そして
http://localhost:8080/hoge/fuga
へ。

## gulpの環境を作るためのpackage.json
devel以下に配置してnpm install

```json:package.json
{
  "name": "static",
  "version": "0.0.1",
  "description": "static files",
  "main": "index.js",
  "dependencies": {},
  "devDependencies": {
    "gulp": "3.8.8",
    "gulp-coffee": "2.2.0",
    "gulp-watch": "1.1.0",
    "gulp-compass": "2.0.0",
    "gulp-nodemon": "1.0.4",
    "gulp-notify": "2.0.0",
    "gulp-exec": "2.1.1",
    "gulp-livereload": "2.1.1",
    "gulp-plumber": "0.6.6",
    "express": "4.9.8",
    "jade": "1.7.0",
    "coffee-script": "1.8.0"
  }
}
```

## compass/sassを導入するためのGemfile
導入はgulpにやらせるのでGemfileをdevel直下に貼るだけ

```ruby:Gemfile
source 'http://rubygems.org'

gem 'sass'
gem 'compass'
```

## bowerで導入する3rdパーテーのライブラリをstatic/vendorsに配置する.bowerrc
devel直下に配置

```json:.bowerrc
{
  "directory": "./../static/vendors"
}
```

## bowerで導入するためのbower.jsonの一例
devel直下に配置する

```json:bower.json
{
  "name": "static",
  "version": "0.0.1",
  "ignore": [
    "**/.*",
    "node_modules",
    "components"
  ],
  "dependencies": {
    "jquery": "2.1.1",
    "backbone": "1.1.2",
    "requirejs-domready": "2.0.1",
    "requirejs": "2.1.14",
    "underscore": "1.6.0"
  },
  "devDependencies": {
    "mocha": "2.0.0",
    "chai": "1.9.2",
    "sinon": "http://sinonjs.org/releases/sinon-1.10.3.js"
  }
}
```

## gulpfile.coffee
やはりdevel直下に配置

```coffeescript:gulpfile.coffee
gulp = require 'gulp'
coffee = require 'gulp-coffee'
compass = require 'gulp-compass'
nodemon = require 'gulp-nodemon'
notify = require 'gulp-notify'
exec = require('child_process').exec
livereload = require 'gulp-livereload'
plumber = require 'gulp-plumber'
watch = require 'gulp-watch'

printout = (callback) ->
  (err, stdout, stderr) ->
    console.log stdout
    console.log stderr
    callback err

gulp.task 'setupGems', (cb) ->
  exec 'bundle install', printout(cb)

gulp.task 'setupBower', (cb) ->
  exec 'rm -rf ./../static/vendors && bower install', printout(cb)

gulp.task 'express', ->
  nodemon
    script: './test/server.js'

gulp.task 'coffee', ->
  src = './coffee/**/*.coffee'
  testSrc = './test/coffee/**/*.coffee'
  gulp.src(src)
      .pipe watch(src)
      .pipe plumber
        errorHandler: notify.onError("Error: <%= error.message %>")
      .pipe coffee
        bare: true
      .pipe gulp.dest('./../static/js')
      .pipe livereload()
  gulp.src(testSrc)
      .pipe watch(testSrc)
      .pipe plumber
        errorHandler: notify.onError("Error: <%= error.message %>")
      .pipe coffee
        bare:true
      .pipe gulp.dest('./test/js')
      .pipe livereload()

gulp.task 'compass', ->
  src = './sass/**/*.sass'
  testSrc = './test/sass/**/*.sass'
  gulp.src(src)
      .pipe watch(src)
      .pipe plumber
        errorHandler: notify.onError("Error: <%= error.message %>")
      .pipe compass
        bundle_exec:true,
        css: './../static/css'
        sass: './sass'
      .pipe livereload()
  gulp.src(testSrc)
      .pipe watch(testSrc)
      .pipe plumber
        errorHandler: notify.onError("Error: <%= error.message %>")
      .pipe compass
        bundle_exec:true
        css: './test/css'
        sass: './test/sass'
      .pipe livereload()

gulp.task 'default', ['compass', 'coffee', 'express']
gulp.task 'setup', ['setupGems', 'setupBower']
```

## devel/test/server.js

mochaをブラウザで走らせるためのサーバーをexpressで簡単に。

```js:test/server.js
var express = require('express');
var http = require('http');
var app = express();

app.set('port', process.env.PORT || 8080);
app.set('view engine', 'jade');
app.use(express.static('./../'));

app.get(/(.+)(\/.+)?/, function(req, res){
  var path = req.params[0].replace('/', '');
  res.render(__dirname + '/template', {target: path});
});

http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});
```

このサーバーでdevel/test/coffee/hoge/fuga-spec.coffeeのテスト結果をlocalhost:8080/hoge/fugaで閲覧してTDDする。livereloadしてるのでブラウザに適当な拡張入れるとリアルタイムに反映されるので嬉しい。

## require.jsの設定ファイルをcoffeeで書く

```coffeescript:devel/coffee/config.coffee
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
```

```coffeescript:devel/test/coffee/spec-config.coffee
require_test =
  paths:
    mocha: 'vendors/mocha/mocha'
    chai: 'vendors/chai/chai'
    sinon: 'vendors/sinon/index'
  shim:
    mocha:
      exports: 'mocha'
    chai:
      exports: 'chai'
    sinon:
      exports: 'sinon'

require = window.require || {}

for key, val of require_test.paths
  require.paths[key] = val
for key, val of require_test.shim
  require.shim[key] = val
```

## テスト対象となるモジュール例

ものすごくどうでもいい感じのモジュールをRequirejsで作ります。

```coffeescript:devel/hoge/fuga.coffee
define(
  'js/hoge/fuga',
  ['jquery', 'underscore', 'backbone'],
  ($, _, Backbone) ->
    'use strict'

    App =
      Models: {}
      Collections: {}
      Views: {}

    class App.Models.Fuga extends Backbone.Model

      initialize: (obj) ->
        @name = obj.name

    class App.Collections.Fugas extends Backbone.Collection

      model: App.Models.Fuga

    class App.Views.FugaView extends Backbone.View

      initialize: ->
        @listenTo(@collection, 'sync', @render)
        @collection.fetch()

      render: ->

    App.initialize = ->
    if Object.freeze? then Object.freeze App else App
)
```

## モジュールをテストするspec例

```coffeescript:devel/test/coffee/hoge/fuga-spec.coffee
require(['js/hoge/fuga', 'backbone', 'mocha', 'chai', 'sinon'], (App, Backbone, mocha, chai, sinon) ->
  'use strict'

  mocha.ui 'bdd'

  chai.should()

  describe 'App', ->
    it 'App.Models.FugaはBackbone.Modelを継承', ->
      App.Models.Fuga.prototype.should.be.an.instanceof Backbone.Model
    it 'App.Collections.FugasはBackbone.Collectionを継承', ->
      App.Collections.Fugas.prototype.should.be.an.instanceof Backbone.Collection
    it 'App.Views.FugaViewはBackbone.Viewを継承', ->
      App.Views.FugaView.prototype.should.be.an.instanceof Backbone.View

  describe 'App.Models.Fuga', ->

    fuga = null
    before ->
      fuga = new App.Models.Fuga({name: 'fuga'})

    it 'fugaのnameがfuga', ->
      fuga.name.should.be.equals 'fuga'

  describe 'App.View.FugaView', ->

    it '初期化時にcollectionをfetchする', ->
      iamspy = new App.Collections.Fugas()
      iamspy.fetch = sinon.spy()
      new App.Views.FugaView collection: iamspy
      iamspy.fetch.called.should.be.true

  mocha.run()

)
```

## mochaで結果を表示するためのjadeテンプレ

```jade:template.jade
doctype html
html
  head
    title (^q^) < #{target} のてすと
    link(rel='stylesheet', href='/static/vendors/mocha/mocha.css')
    link(rel='stylesheet', href='/devel/test/css/style.css')

  body
    div(class='title')
      h1 (^q^) < #{target} のてすと
    div(id='mocha')
    script(src='/static/js/config.js')
    script(src='/devel/test/js/spec-config.js')
    script(src='/static/vendors/requirejs/require.js')
    script(src='/devel/test/js/#{target}-spec.js')
```
