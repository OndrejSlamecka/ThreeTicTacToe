sha1 = require('sha1')
LocalStrategy = require('passport-local').Strategy

module.exports = (passport, passwords) ->
	# used to serialize the user for the session
	passport.serializeUser (user, done) ->
		done null, user.name
		return

	# used to deserialize the user
	passport.deserializeUser (name, done) ->
		done null, {name: name}
		return

	strategy = new LocalStrategy({ passReqToCallback : true }, # allows us to pass back the entire request to the callback
		(req, username, password, done) ->
			if username of passwords and passwords[username] == sha1(password)
				done(null, {name : username})
			else
				done(null, false)
			return
	)

	passport.use('local', strategy)
