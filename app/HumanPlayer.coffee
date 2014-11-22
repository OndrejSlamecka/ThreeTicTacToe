class HumanPlayer
	game: null

	constructor: (@name, @connection) ->
		@connection.send(JSON.stringify({'identify':@name}))
		@connection.on 'message', this.wsMessageReceived


	wsMessageReceived: (data) =>
		payload = JSON.parse(data)

		if 'turn' of payload
			turn = payload.turn
			@game.turn(@name, turn.x, turn.y) if @game?


	onEnqueue: (n) ->
		@connection.send(JSON.stringify({'playersInQueue' : n}))


	onGameLoaded: (board, onTurn, mark, playersNames, boardSize, timeRemaining) ->
		payload = JSON.stringify({
			'game': {
				'board': board,
				'onTurn': onTurn,
				'mark': mark,
				'players': playersNames,
				'boardSize': boardSize,
				'timeRemaining': timeRemaining
			}
		})
		@connection.send(payload)


	onPause: () ->
		payload = JSON.stringify({'pause':true})
		@connection.send(payload)


	onResume: (onTurn, mark) ->
		payload = JSON.stringify({
			'resume': {
				'onTurn': onTurn,
				'mark': mark
			}
		})
		@connection.send(payload)


	onVictory: (password, x,y) ->
		payload = JSON.stringify({'victory': {'password': password, 'x': x, 'y': y}})
		@connection.send(payload)


	onLoss: () ->
		payload = JSON.stringify({'loss': true})
		@connection.send(payload)


	onTie: () ->
		payload = JSON.stringify({'tie': true})
		@connection.send(payload)


	onTurn: (x, y, mark, onTurn) ->
		payload = JSON.stringify({
			'turn': {
				'timeout': false,
				'x': x,
				'y': y,
				'mark': mark,
				'onTurn': onTurn
			}
		})
		@connection.send(payload)


	onTurnTimeout: (mark, onTurn) ->
		payload = JSON.stringify({
			'turn': {
				'timeout': true,
				'mark': mark,
				'onTurn': onTurn
			}
		})
		@connection.send(payload)


module.exports = HumanPlayer