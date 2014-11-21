
module.exports = (grunt) ->
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.loadNpmTasks('grunt-coffeeify')

	grunt.initConfig
		coffeeify:
			options:
				debug: !!grunt.option('dev')
			dist:
				src: 'client_src/coffee/*.coffee'
				dest: 'public/bundle.js'

		watch:
			options:
				livereload: !!grunt.option('dev')

			coffee:
				files: ['client_src/coffee/*.coffee']
				tasks: ['coffeeify']

	grunt.registerTask 'build', ['coffeeify']
