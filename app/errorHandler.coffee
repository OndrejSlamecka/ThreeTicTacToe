module.exports = (app) ->
	# catch 404 and forward to error handler
	app.use (req, res, next) ->
		err = new Error("Not Found")
		err.status = 404
		next err
		return

	# error handlers

	# development error handler
	# will print stacktrace
	if app.get("env") is "development"
		app.use (err, req, res, next) ->
			res.status err.status or 500
			res.render "error",
				message: err.message
				error: err

			return

	# production error handler
	# no stacktraces leaked to user
	app.use (err, req, res, next) ->
		res.status err.status or 500
		res.render "error",
			message: err.message
			error: {}

		return
