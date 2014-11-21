module.exports = (app, passport) ->

	isLoggedIn = (req, res, next) ->
		if (req.isAuthenticated())
			return next()
		else
			res.redirect('/login')


	app.get '/login', (req, res) ->
		res.render('login')
		return

	app.post '/login', passport.authenticate('local', { successRedirect: '/', failureRedirect: '/login' })

	app.get '/logout', (req, res) ->
		req.logout()
		res.redirect('/')
		return

	app.get '/', isLoggedIn, (req, res) ->
		res.render('index')
		return
