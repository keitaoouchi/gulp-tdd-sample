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