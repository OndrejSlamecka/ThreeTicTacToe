_ = require('underscore')
PauseOnTurnPlayer = require('./PauseOnTurnPlayer.coffee')
HumanPlayer = require('./HumanPlayer.coffee')
victoryPassword = require('./config/victory-pass.js')
max = Math.max
min = Math.min

class Game
	boardWidth: 30
	boardHeight: 15
	consecutiveMarksToWin: 5


	constructor: (@players, @onGameEnd) ->
		@onTurn = 0
		@board = []
		@filledCells = 0
		@mark = 1 # 1 for O, 2 for X (and 0 for empty)
		@timeRemaining = 10

		names = _.map(@players, (player) -> player.name)
		names.sort()
		@key = names.join('_')

		@order = _.keys(@players)

		for i in [0..@boardHeight] by 1
			@board[i] = []
			for j in [0..@boardWidth] by 1
				@board[i][j] = 0

		_.each @players, (p) =>
			p.onGameLoaded(this.getGameInfo())

		@timer = setInterval this.timerTick, 1000
		@timeRemaining = 10


	timerTick: () =>
		@timeRemaining--
		if @timeRemaining == 0
			this.onTurnTimeout()


	replacePlayer: (name, newPlayer) ->
		delete @players[name]
		newPlayer.game = this
		@players[newPlayer.name] = newPlayer
		@order[@order.indexOf(name)] = newPlayer.name

		if not(newPlayer instanceof HumanPlayer) && !@paused
			this.pause()

		allHumans = true
		for name, player of @players
			if not (player instanceof HumanPlayer)
				allHumans = false
				break

		if allHumans
			@onTurn = (@order.indexOf(newPlayer.name) + 1) % 3 # The next player in order is on turn
			this.resume()

		newPlayer.onGameLoaded(this.getGameInfo())


	getGameInfo: () ->
		return {
			'board': @board,
			'onTurn': @onTurn,
			'mark': @mark,
			'players': @order,
			'boardHeight': @boardHeight,
			'boardWidth': @boardWidth,
			'timeRemaining': @timeRemaining,
			'paused': @paused
		}


	pause: () ->
		clearInterval(@timer)
		@paused = true
		@leavableTimeout = setTimeout () =>
			@leavable = true
		, 30*1000 # Also present in client_src/game.coffee

		_.each @players, (p) ->
			p.onPause()


	resume: () =>
		@leavable = false
		clearTimeout(@leavableTimeout)

		@timeRemaining = 10
		clearInterval(@timer)
		@timer = setInterval this.timerTick, 1000
		@paused = false
		_.each @players, (p) =>
			p.onResume(@onTurn, @mark)


	disband: () -> this.tie() if @leavable


	tie: () ->
		_.each @players, (p) -> p.onTie()
		clearInterval(@timer)
		@onGameEnd(@key, null)


	turn: (username, x, y) ->
		if username != @order[@onTurn] \
				|| @board[x][y] != 0 \
				|| x < 0 || x >= @boardHeight \
				|| y < 0 || y >= @boardWidth \
				|| @paused
			return

		console.log username + ' played in game ' + this.key

		@board[x][y] = @mark
		@filledCells++

		if this.isVictory(x, y)
			@players[username].onVictory(victoryPassword, x,y)

			_.each @players, (p) ->
				p.onLoss() if p.name != username

			clearInterval(@timer)
			@onGameEnd(@key, username)

		else if @filledCells == @N*@N
			this.tie()
		else
			@onTurn = (@onTurn + 1) % 3
			_.each @players, (p) => p.onTurn(x, y, @mark, @order[@onTurn])
			@mark = (@mark % 2) + 1
			@timeRemaining = 10


	onTurnTimeout: () =>
		@onTurn = (@onTurn + 1) % 3
		_.each @players, (p) => p.onTurnTimeout(@mark, @order[@onTurn])
		@mark = (@mark % 2) + 1
		@timeRemaining = 10


	isVictory: (x, y) ->
		seqLen = @consecutiveMarksToWin

		# Horizontal
		consec = 0
		for i in [max(y-seqLen, 0) .. min(y+seqLen, @boardWidth - 1)] by 1
			if @board[x][i] == @board[x][y]
				consec++
				return true if consec >= seqLen
			else
				consec = 0

		# Vertical
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @boardHeight - 1)] by 1
			if @board[i][y] == @board[x][y]
				consec++
				return true if consec >= seqLen
			else
				consec = 0

		# / Diagonal
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @boardHeight - 1)] by 1
			for j in [max(y-seqLen, 0) .. min(y+seqLen, @boardWidth - 1)] by 1
				if x + y == i + j
					if @board[i][j] == @board[x][y]
						consec++
						return true if consec >= seqLen
					else
						consec = 0

		# \ Diagonal
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @boardHeight - 1)] by 1
			for j in [max(y-seqLen, 0) .. min(y+seqLen, @boardWidth - 1)] by 1
				if x - y == i - j
					if @board[i][j] == @board[x][y]
						consec++
						return true if consec >= seqLen
					else
						consec = 0

		return false


module.exports = Game
