_ = require('underscore')
Game = require('./Game.coffee')
PauseOnTurnPlayer = require('./PauseOnTurnPlayer.coffee')

class GameManager
	queue: {}
	games: {}

	constructor: (@db) ->


	onGameEnd: (key, winner) ->
		players = @games[key].players
		delete @games[key]
		for name, player of players
			player.game = null
			@db.del 'user_game:' + player.name
			if name != winner && name != 'dummy' && player.connection.readyState == player.connection.OPEN
				this.enqueue(player)


	enqueue: (player) ->
		# The following code is supposed to be atomic... is it?
		@queue[player.name] = player
		if _.size(@queue) < 3
			_.each(@queue, (player) => player.onEnqueue(_.size(@queue)))
		else
			game = new Game(@queue, this.onGameEnd)
			@games[game.key] = game
			for name, player of @queue
				player.game = game
				@db.set('user_game:' + player.name, game.key)
			@queue = {}


	addHumanPlayer: (player) ->
		@db.get ('user_game:' + player.name), (err, reply) =>
			if reply && @games[reply.toString()]?
				@games[reply.toString()].replacePlayer('substitute_' + player.name, player)
			else
				this.enqueue(player)


		player.connection.on 'close', (code, message) =>
			delete @queue[player.name] if @queue[player.name]?
			if player.game?
				dummy = new PauseOnTurnPlayer('substitute_' + player.name)
				dummy.game = player.game
				player.game.replacePlayer(player.name, dummy)



module.exports = GameManager