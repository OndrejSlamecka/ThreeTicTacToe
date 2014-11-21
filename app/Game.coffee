_ = require('underscore')
max = Math.max
min = Math.min

class Game
	board: []
	N: 20
	mark: 1 # 1 for O, 2 for X
	onTurn: 0

	constructor: (@players, @onGameEnd) ->
		for i in [0..@N] by 1
			@board[i] = []
			for j in [0..@N] by 1
				@board[i][j] = 0

		playerList = {}
		i = 0
		for key of @players
			playerList[i++] = key

		payload = JSON.stringify({
			'game' : {
				'onTurn' : _.keys(@players)[@onTurn],
				'mark': @mark,
				'players': playerList,
				'boardSize' : @N
			}
		})

		@timeoutId = setTimeout this.onTurnTimeout, 10*1000 # duplicate from turn method...

		this.broadcast(payload)

	turn: (username, x, y) ->
		if username != _.keys(@players)[@onTurn] || @board[x][y] != 0
			return

		clearTimeout(@timeoutId)

		@board[x][y] = @mark

		if this.isVictory(x, y)
			payload = JSON.stringify({'victory': {'password': 'heslo je rum', 'x': x, 'y': y}})
			@players[username].send(payload)

			payload = JSON.stringify({'loss': true})
			for name, conn of @players
				if name != username
					conn.send(payload)

			@onGameEnd(username)

		else if this.isBoardFull()
			payload = JSON.stringify({'tie': true})
			this.broadcast(payload)
			@onGameEnd(null)
		else
			@onTurn = (@onTurn + 1) % 3

			payload = JSON.stringify('turn': { 'timeout': false, 'x': x, 'y': y, 'mark': @mark, 'onTurn': _.keys(@players)[@onTurn] })
			this.broadcast(payload)

			@mark = (@mark % 2) + 1

			@timeoutId = setTimeout this.onTurnTimeout, 10*1000

	onTurnTimeout: () =>
		@onTurn = (@onTurn + 1) % 3

		@mark = (@mark % 2) + 1 # Maintain XOXOXOXO order

		payload = JSON.stringify('turn': { 'timeout': true, 'mark': @mark, 'onTurn': _.keys(@players)[@onTurn] })
		this.broadcast(payload)

		@mark = (@mark % 2) + 1

		@timeoutId = setTimeout this.onTurnTimeout, 10*1000


	isVictory: (x, y) ->
		seqLen = 3

		# Horizontal
		consec = 0
		for i in [max(y-seqLen, 0) .. min(y+seqLen, @N)] by 1
			if @board[x][i] == @board[x][y]
				consec++
				return true if consec >= seqLen
			else
				consec = 0

		# Vertical
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @N)] by 1
			if @board[i][y] == @board[x][y]
				consec++
				return true if consec >= seqLen
			else
				consec = 0

		# / Diagonal
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @N)] by 1
			for j in [max(y-seqLen, 0) .. min(y+seqLen, @N)] by 1
				if x + y == i + j
					if @board[i][j] == @board[x][y]
						consec++
						return true if consec >= seqLen
					else
						consec = 0

		# \ Diagonal
		consec = 0
		for i in [max(x-seqLen, 0) .. min(x+seqLen, @N)] by 1
			for j in [max(y-seqLen, 0) .. min(y+seqLen, @N)] by 1
				if x - y == i - j
					if @board[i][j] == @board[x][y]
						consec++
						return true if consec >= seqLen
					else
						consec = 0

		return false

	broadcast: (payload) ->
		_.each @players, (conn) -> conn.send payload

module.exports = Game
