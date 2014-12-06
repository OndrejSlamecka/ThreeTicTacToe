_ = require('underscore')
Game = require('./Game.coffee')
HumanPlayer = require('./HumanPlayer.coffee')
PauseOnTurnPlayer = require('./PauseOnTurnPlayer.coffee')

class GameManager
	queue: {}
	games: {}
	playersGames: {}
	lastGameCreated: null

	onGameEnd: (key, winner) =>
		players = @games[key].players
		delete @games[key]
		for name, player of players
			player.game = null
			delete @playersGames[player.name]
			if name != winner && player instanceof HumanPlayer && player.connection.readyState == player.connection.OPEN
				this.enqueue(player)


	enqueue: (player) ->
		# The following code is supposed to be atomic... is it?
		@queue[player.name] = player
		if _.size(@queue) < 3
			_.each(@queue, (player) => player.onEnqueue(_.size(@queue)))
		else
			game = new Game(@queue, this.onGameEnd)
			@games[game.key] = game
			console.log 'Created game ' + game.key
			for name, player of @queue
				player.game = game
				@playersGames[player.name] = game.key
			@queue = {}
			@lastGameCreated = new Date()


	addHumanPlayer: (player) ->
		if @playersGames[player.name]?
			console.log player.name + ' reconnected to ' + @playersGames[player.name] + ' ' + @games[@playersGames[player.name]].board[0][0]
			@games[@playersGames[player.name]].replacePlayer('substitute_' + player.name, player)
		else
			this.enqueue(player)

		player.connection.on 'close', (code, message) =>
			delete @queue[player.name] if @queue[player.name]?
			if player.game?
				dummy = new PauseOnTurnPlayer('substitute_' + player.name)
				dummy.game = player.game
				player.game.replacePlayer(player.name, dummy)


	getLastGameCreation: () -> @lastGameCreated
	getQueueSize: () -> _.size(@queue)


module.exports = GameManager
