gulp = require 'gulp'
gutil = require 'gulp-util'
plumber = require 'gulp-plumber'
runSeqeuence = require 'run-sequence'
gif = require 'gulp-if'

rename = require 'gulp-rename'
fs = require 'fs'
clean = require 'gulp-clean'
copy = require 'gulp-copy'

handlebars = require 'gulp-compile-handlebars'
Handlebars = require 'handlebars'
htmlmin = require 'gulp-minify-html'

sass = require 'gulp-sass'

coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'

sourcemaps = require 'gulp-sourcemaps'

reload = require 'gulp-livereload'


config = {
	port: 9091,
	production: false
	imgpath: "/images"
}

site = {
	title: "Televised",
	description: "Televised makes it easy to keep track of your favorite TV shows.",
	keywords: "iphone,app,store,television,tv,show,telly,episodes,guide,track,entertainment,summary,week,watch,airtime,local,apple,itunes,ipad,robocat,thetvdb,tvrage"
	url: "http://televisedapp.com",
	fb: {
		appName: "Televised",
		appId: "549884491706231"
	}
}

reload_script = '<script src="//localhost:{{ config.port }}/livereload.js"></script>'

build_path = "./public"

paths = {
	copyfile: "{downloads/*,favicon.ico,apple-touch-icon.png}",
	handlebars: "./{**/,}*.handlebars",
	sass: "assets/css/{**/,}*.{scss,sass}",
	coffee: "assets/js/**/*.coffee",
	js: "assets/js/**/*.js",
	images: "assets/images/**/*.{jpg,png}"
}

retinaPath = (path) ->
	comps = path.split('.')
	"#{comps[0]}@2x.#{comps[1]}"

onError = (err) ->
	console.log err

isFile = (str) ->
	!str.match "\n" && fs.existsSync str

readPartial = (name) ->
	path = 'partials/' + name + '.handlebars'
	val = fs.readFileSync path, 'utf8' if isFile path

	val

gulp.task 'clean', (cb) ->
	gulp.src(build_path)
		.pipe(plumber { errorHandler: onError } )
		.pipe(clean { force: false, read: true } )
		

gulp.task 'scripts', ->
	gulp.src(paths.coffee)
		.pipe(sourcemaps.init())
		.pipe(coffee({bare: true}))
		.pipe(concat('app.js'))
		.pipe(gif(config.production, uglify()))
		.pipe(sourcemaps.write('./maps'))
		.pipe(gulp.dest("#{build_path}/js"))
		.pipe(reload())

	gulp.src(paths.js)
		.pipe(sourcemaps.init())
		.pipe(concat('vendor.js'))
		.pipe(gif(config.production, uglify()))
		.pipe(sourcemaps.write('./maps'))
		.pipe(gulp.dest("#{build_path}/js/"))
		.pipe(reload())

gulp.task 'images', ->
	gulp.src(paths.images)
		.pipe(plumber({
			errorHandler: onError
		}))
	.pipe(gulp.dest("#{build_path}/images"))
		.pipe(reload())

gulp.task 'sass', ->
	sass_paths = ['./assets/css/vendor/bourbon', './assets/css/vendor/neat']
	sass_config = { 
		includePaths:  sass_paths,
		imagePath: config.imgpath
	}

	if config.production
		sass_config['outputStyle'] = 'compressed'
		sass_config['sourceComments'] = false

	gulp.src(paths.sass)
		.pipe(plumber({ errorHandler: onError }))
		.pipe(sourcemaps.init())
		.pipe(sass(sass_config))
		.pipe(sourcemaps.write('./maps'))
		.pipe(gulp.dest("#{build_path}/css"))
		.pipe(reload())

gulp.task 'html', ->
	data = {
		config: config,
		site: site,
		template: {
			title: "TV Shows Weekly"
		}
	}

	options = {
		ignorePartials: true,
		partials: {
			reload: reload_script
			header: readPartial('header'),
			footer: readPartial('footer'),
		},
		helpers: {
			img: (path, retina = true, cls = null) ->
				rp = retinaPath(path)
				str = "<img src=\"#{config.imgpath}/#{path}\""
				str += " data-at2x=\"#{rp}\"" if retina
				str += " class=\"#{cls}\"" if typeof cls == 'string'
				str += ">"

				return str
		}
	}

	gulp.src([paths.handlebars, '!partials/*', "!node_modules/**/*"])
		.pipe(plumber({ errorHandler: onError }))
		.pipe(handlebars(data, options))
		.pipe(rename { extname: ".html" })
		.pipe(gif(config.production, htmlmin()))
		.pipe(gulp.dest(build_path))
		.pipe(reload())

gulp.task 'copy', ->
	gulp.src(paths.copyfile)
		.pipe(copy(build_path))

gulp.task 'watch', ->
	reload.listen(config.port)

	gulp.watch paths.copyfile, ['copy']
	gulp.watch paths.coffee, ['scripts']
	gulp.watch paths.js, ['scripts']
	gulp.watch paths.handlebars, ['html']
	gulp.watch paths.sass, ['sass']
	gulp.watch paths.images, ['images']

gulp.task 'set-production', ->
	config.production = true

gulp.task 'cleanbuild', ->
	runSeqeuence 'clean', 'build'

gulp.task 'build', ['html', 'sass', 'scripts', 'images', 'copy']
gulp.task 'release', ['set-production', 'cleanbuild']

gulp.task 'default', ['cleanbuild', 'watch']
