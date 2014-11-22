$ = require('jquery')
CountdownTimer = require('./CountdownTimer.coffee')

window.WebSocket = window.WebSocket || window.MozWebSocket
connection = new window.WebSocket('ws://' + window.location.hostname + ':3010') # host contains port number, we don't want that

markSign = (mark) -> if mark == 1 then 'O' else 'X'

username = null
onTurn = null
mark = 1
timer = new CountdownTimer($('#timer'), 10)

onCellClick = (event) ->
	if onTurn != username
		return

	$td = $(this)

	payload = JSON.stringify({
		'turn': {'x': $td.data('x'), 'y': $td.data('y')}
	})

	connection.send(payload)


updateOnTurnStatus = (timeRemaining) ->
	$('#turn-status').html(if onTurn == username then "You're on turn!" else "It's not your turn.")
	$('#turn-mark').html(markSign(mark))
	timer.start(timeRemaining)

handlers = {}
handlers.identify = (data) -> username = data

handlers.playersInQueue = (data) ->
	$('#playersInQueue').html(data)

handlers.game = (data) ->
	$('#section-lobby').slideUp()
	$('#section-game').slideDown()

	onTurn = data.players[data.onTurn]

	code = ''
	for i in [0..data.boardSize - 1] by 1
		code += '<tr>'
		for j in [0..data.boardSize - 1] by 1
			code += '<td id="cell-' + i + '-' + j + '" data-x="' + i + '" data-y="' + j + '"></td>'
		code += '</tr>\n'
	$('#game').html(code)
	$('td').on 'click', onCellClick

	updateOnTurnStatus(data.timeRemaining)

handlers.turn = (data) ->
	onTurn = data.onTurn

	if !data.timeout # Player's turn timeouted
		$('#cell-' + data.x + '-' + data.y).html(markSign(mark))

	mark = (data.mark % 2) + 1

	updateOnTurnStatus()

handlers.victory = (data) ->
	$('#tie').slideUp()
	$('#cell-' + data.x + '-' + data.y).html(markSign(mark))
	$('#password').html(data.password)
	$('#victory').slideDown()

handlers.loss = () ->
	$('#tie').slideUp() # May have been shown from before
	$('#loss').show()
	$('#section-lobby').slideDown()
	$('#section-game').slideUp()

handlers.tie = () ->
	$('#loss').slideUp() # May have been shown from before
	$('#tie').show()
	$('#section-lobby').slideDown()
	$('#section-game').slideUp()

connection.onmessage = (event) ->
	payload = JSON.parse(event.data)
	for key of payload
		handlers[key](payload[key])


connection.onerror = (error) ->
	console.log error
connection.onclose = (close) ->
	console.log 'connection closed' # TODO: PRettier!


