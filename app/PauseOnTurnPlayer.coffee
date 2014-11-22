class PauseOnTurnPlayer
	game: null

	constructor: (@name) ->


	onGameLoaded: () ->
		return

	onTurn: (x, y, mark, onTurn) ->
		if onTurn != @name
			return

		@game.pause()

	onPause: () ->
		return

	onResume: () ->
		return

	onTurnTimeout: (mark, onTurn) ->
		if onTurn != @name
			return

		@game.pause()

	onLoss: () ->
		return

	onTie: () ->
		return

	onVictory: () ->
		return

module.exports = PauseOnTurnPlayer