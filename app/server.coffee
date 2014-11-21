_ = require('underscore')
express = require('express')
app = express()
passport = require('passport')
session = require('express-session')
MemoryStore = session.MemoryStore
WebSocketServer = require('ws').Server
sha1 = require('sha1')
RedisStore = require('connect-redis')(session)
Game = require('./Game.coffee')

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

gameKey = (playersNames) ->
	playersNames.sort (a, b) -> a - b
	return sha1(playersNames.join('_'))

Queue = {}
Games = {}
UsersGames = {}

onGameEnd = (key) ->
	f = (winner) ->
		for name, conn of Games[key].players
			delete UsersGames[name]
			if name != winner
				enqueue(name, conn)

		delete Games[key]
	return f

enqueue = (username, ws) ->
	# The following code is supposed to be atomic... is it?
	Queue[username] = ws
	if _.size(Queue) < 3
		_.each Queue, (conn) ->
			conn.send(JSON.stringify({'playersInQueue' : _.size(Queue)}))
	else
		playersNames = _.keys(Queue)
		key = gameKey(playersNames)
		Games[key] = new Game(Queue, onGameEnd(key))
		Queue = {}

		for name in playersNames
			UsersGames[name] = key


wss.on('connection', (ws) ->
	sessionFromReq ws.upgradeReq, (s) ->
		username = s.passport.user
		ws.send(JSON.stringify({'identify':username}))

		enqueue(username, ws)

		ws.on('message', (data) ->
			payload = JSON.parse(data)

			if 'turn' of payload
				turn = payload.turn
				if UsersGames[username]? # user may be clicking a dead game
					Games[UsersGames[username]].turn(username, turn.x, turn.y)
		)

		ws.on('close', (code, message) ->
			# Games[UsersGames[username]].replaceWithDummy(username)
		)
)
