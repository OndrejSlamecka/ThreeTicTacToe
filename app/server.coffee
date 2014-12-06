express = require('express')
app = express()
passport = require('passport')
session = require('express-session')
MemoryStore = session.MemoryStore
WebSocketServer = require('ws').Server
RedisStore = require('connect-redis')(session)

store = new RedisStore
	host:'127.0.0.1',
	port:6379,
	prefix:'nodejs_sess'

path = require('path')
favicon = require('serve-favicon')
logger = require('morgan')
cookieParser = require('cookie-parser')('mytinylittlesecreteis:')
bodyParser = require('body-parser')

# Game setup
GameManager = require('./GameManager.coffee')
HumanPlayer = require('./HumanPlayer.coffee')

gm = new GameManager()

# HTTP server
passwords = require('./config/passwords.js')
require('./passport.coffee')(passport, passwords)

#app.use(logger('dev'))
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

require('./routes.coffee')(app, passport, gm)
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

wss.on 'connection', (ws) ->
	sessionFromReq ws.upgradeReq, (s) ->
		player = new HumanPlayer(s.passport.user, ws)
		gm.addHumanPlayer(player)

