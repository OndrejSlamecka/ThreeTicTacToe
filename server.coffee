process.title = "tictactoe-realtime-server"
webSocketServer = require("websocket").server
http = require("http")

class Room
	board = []
	users = []



class Server
	constructor: () ->
		@rooms = []
		@lobby = []

		httpServer = http.createServer() # (request, response) -> # Dummy HTTP server. TODO: Add dummy page
		httpServer.listen 3010
		webSocketServer = new webSocketServer(httpServer: httpServer) # WebSocket server a layer above HTTP server. http://tools.ietf.org/html/rfc6455#page-6

		webSocketServer.on 'request', this.onRequest


	onRequest: (request) =>
		if !this.verifyUser(request)
			request.reject()
		else
			connection = request.accept(null, request.origin)
			this.onConnect(connection)


	verifyUser: (request) =>
		return true

	onConnect: (connection) =>
		# Message received


		'''
		connection.on 'message', (data) =>
			if gameId? && @rooms[gameId].hasClient(user.id)
				@rooms[gameId].onReceive(data, user.id)

		connection.on 'close', () =>
			if gameId? && @rooms[gameId].hasClient(user.id)
				@rooms[gameId].deleteClient(user.id)

				if @rooms[gameId].users.length == 0
					delete @rooms[gameId]
		'''


new Server()
