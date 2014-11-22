_ = require('underscore')
sha1 = require('sha1')
PauseOnTurnPlayer = require('./PauseOnTurnPlayer.coffee')
HumanPlayer = require('./HumanPlayer.coffee')
max = Math.max
min = Math.min

class Game
	board: []
	N: 5
	consecutiveMarksToWin: 3

	# players
	# onGameEnd
	filledCells: 0
	mark: 1 # 1 for O, 2 for X (and 0 for empty)
	onTurn: 0
	timeRemaining = 10


	constructor: (@players, @onGameEnd) ->
		names = _.map(@players, (player) -> player.name)
		names.sort (a, b) -> a - b
		@key = sha1(names.join('_'))

		@order = _.keys(@players)

		for i in [0..@N] by 1
			@board[i] = []
			for j in [0..@N] by 1
				@board[i][j] = 0

		_.each @players, (p) =>
			p.onGameLoaded(@board, @onTurn, @mark, @order, @N, @timeRemaining)

		@timer = setInterval this.timerTick, 1000
		@timeRemaining = 10


	timerTick: () =>
		@timeRemaining--
		if @timeRemaining == 0
			this.onTurnTimeout()


	replacePlayer: (name, newPlayer) ->
		delete @players[name]
		@players[newPlayer.name] = newPlayer
		@order[@order.indexOf(name)] = newPlayer.name

		newPlayer.onGameLoaded(@board, @onTurn, @mark, @order, @N, @timeRemaining)

		if @players[@order[@onTurn]] instanceof PauseOnTurnPlayer
			this.pause()

		if newPlayer instanceof HumanPlayer
			this.resume()


	pause: () ->
		clearInterval(@timer)
		@paused = true
		_.each @players, (p) ->
			p.onPause()


	resume: () =>
		@onTurn = (@onTurn + 1) % 3
		@mark = (@mark % 2) + 1 # Maintain XOXOXOXO order

		@timeRemaining = 10
		@timer = setInterval this.timerTick, 1000
		@paused = false
		_.each @players, (p) =>
			p.onResume(@onTurn, @mark)


	turn: (username, x, y) ->
		if username != @order[@onTurn] \
				|| @board[x][y] != 0 \
				|| x < 0 || x >= @N \
				|| y < 0 || y >= @N \
				|| @paused
			return

		@board[x][y] = @mark
		@filledCells++

		if this.isVictory(x, y)
			@players[username].onVictory('rum', x,y)

			_.each @players, (p) ->
				p.onLoss() if p.name != username

			clearInterval(@timer)
			@onGameEnd(@key, username)

		else if @filledCells == @N*@N
			_.each @players, (p) -> p.onTie()
			clearInterval(@timer)
			@onGameEnd(@key, null)
		else
			@onTurn = (@onTurn + 1) % 3
			_.each @players, (p) => p.onTurn(x, y, @mark, @order[@onTurn])
			@mark = (@mark % 2) + 1
			@timeRemaining = 10


	onTurnTimeout: () =>
		@onTurn = (@onTurn + 1) % 3
		@mark = (@mark % 2) + 1 # Maintain XOXOXOXO order
		_.each @players, (p) => p.onTurnTimeout(@mark, @order[@onTurn])
		@mark = (@mark % 2) + 1
		@timeRemaining = 10


	isVictory: (x, y) ->
		seqLen = @consecutiveMarksToWin

		# Horizontal
		consec = 0
		for i in [max(y-seqLen, 0) .. min(y+seqLen, @N - 1)] by 1
			if @board[x][i] == @board[x][y]
				consec++
				return true if consec >= seqLen
			else
				consec = 0

		# Vertical
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @N - 1)] by 1
			if @board[i][y] == @board[x][y]
				consec++
				return true if consec >= seqLen
			else
				consec = 0

		# / Diagonal
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @N - 1)] by 1
			for j in [max(y-seqLen, 0) .. min(y+seqLen, @N - 1)] by 1
				if x + y == i + j
					if @board[i][j] == @board[x][y]
						consec++
						return true if consec >= seqLen
					else
						consec = 0

		# \ Diagonal
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @N - 1)] by 1
			for j in [max(y-seqLen, 0) .. min(y+seqLen, @N - 1)] by 1
				if x - y == i - j
					if @board[i][j] == @board[x][y]
						consec++
						return true if consec >= seqLen
					else
						consec = 0

		return false


module.exports = Game
