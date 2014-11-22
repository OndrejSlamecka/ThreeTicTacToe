_ = require('underscore')
express = require('express')
app = express()
passport = require('passport')
session = require('express-session')
MemoryStore = session.MemoryStore
WebSocketServer = require('ws').Server
redis = require('redis')
RedisStore = require('connect-redis')(session)
Game = require('./Game.coffee')

client = redis.createClient()

store = new RedisStore
	host:'127.0.0.1',
	port:6379,
	prefix:'nodejs_sess'

path = require('path')
favicon = require('serve-favicon')
logger = require('morgan')
cookieParser = require('cookie-parser')('mytinylittlesecreteis:')
bodyParser = require('body-parser')

passwords = require('./config/passwords.js')
require('./passport.coffee')(passport, passwords)

app.use(logger('dev'))
app.use(express.static(path.join(__dirname, '../public')))
app.use(cookieParser)
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

app.use(session({
	store: store,
	key: 'sid',
	secret: 'mytinylittlesecreteis:',
	cookie: { httpOnly: false }
}))
app.use(passport.initialize())
app.use(passport.session())

# view engine setup
app.set('views', path.join(__dirname, '../views'))
app.set('view engine', 'hbs')

require('./routes.coffee')(app, passport)
require('./errorHandler.coffee')(app)

server = app.listen(3000, ->
	host = server.address().address
	port = server.address().port
	console.log 'Listening at http://%s:%s', host, port
	return
)

sessionFromReq = (req, cb) ->
	cookieParser req, null, (err) ->
		store.get req.signedCookies['sid'], (err, session) ->
			cb(session)

wss = new WebSocketServer({
	server: server,
	port: 3010,
	verifyClient: (info, cb) ->
		sessionFromReq info.req, (session) ->
			if session? && 'user' of session.passport
				cb(true)
			else
				cb(false, 401, 'Could not authenticate')

})

HumanPlayer = require('./HumanPlayer.coffee')
DummyPlayer = require('./DummyPlayer.coffee')

Queue = {}
Games = {}

client.del 'user_game:a'
client.del 'user_game:b'
client.del 'user_game:c'

onGameEnd = (key, winner) ->
	players = Games[key].players
	delete Games[key]
	for name, player of players
		player.game = null
		client.del 'user_game:' + player.name
		if name != winner && name != 'dummy' && player.connection.readyState == player.connection.OPEN
			enqueue(player)


enqueue = (player) ->
	# The following code is supposed to be atomic... is it?
	Queue[player.name] = player
	if _.size(Queue) < 3
		_.each(Queue, (player) -> player.onEnqueue(_.size(Queue)))
	else
		game = new Game(Queue, onGameEnd)
		Games[game.key] = game
		for name, player of Queue
			player.game = game
			client.set('user_game:' + player.name, game.key)
		Queue = {}


wss.on('connection', (ws) ->
	sessionFromReq ws.upgradeReq, (s) ->
		s.passport.game = 'asd'
		player = new HumanPlayer(s.passport.user, ws)

		client.get ('user_game:' + player.name), (err, reply) =>
			if reply && Games[reply.toString()]?
				Games[reply.toString()].replacePlayer('dummy', player)
			else
				enqueue(player)


		ws.on('close', (code, message) ->
			delete Queue[player.name] if Queue[player.name]?
			if player.game?
				dummy = new DummyPlayer
				dummy.game = player.game
				player.game.replacePlayer(player.name, dummy)
		)
)
