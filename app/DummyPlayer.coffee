class DummyPlayer
	game: null

	constructor: () ->
		@name = 'dummy'

	onGameLoaded: () ->
		return

	onTurn: (x, y, mark, onTurn) ->
		if onTurn != 'dummy'
			return

		for i in [0..@game.N - 1] by 1
			for j in [0..@game.N - 1] by 1
				if @game.board[i][j] == 0
					@game.turn('dummy', i, j)

	onTurnTimeout: () ->
		return


module.exports = DummyPlayer