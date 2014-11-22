
class CountdownTimer
	constructor: (@el, @time) ->
		@remaining = @time


	start: (rem = @time) ->
		@remaining = rem
		@el.html(@remaining)
		if @interval?
			clearInterval(@interval)
		@interval = setInterval this.decrease, 1000


	stop: () ->
		clearInterval(@interval)


	decrease: () =>
		@remaining--
		@el.html(@remaining)

		if @remaining == 0
			this.stop()


module.exports = CountdownTimer
