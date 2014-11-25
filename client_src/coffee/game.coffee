$ = require('jquery')
CountdownTimer = require('./CountdownTimer.coffee')

window.WebSocket = window.WebSocket || window.MozWebSocket

connection = null
connect = () ->
	connection = new window.WebSocket('ws://' + window.location.hostname + ':3010') # host contains port number, we don't want that

	connection.onmessage = (event) ->
		payload = JSON.parse(event.data)
		for key of payload
			handlers[key](payload[key])

	connection.onopen = () ->
		$('.disconnected-warning').hide()

	#connection.onerror = (error) ->	setTimeout connect, 5*1000

	connection.onclose = (close) ->
		$('.disconnected-warning').show()
		$('#section-lobby').slideDown()
		$('#section-game').slideUp()
		setTimeout connect, 1000

connect()

markSign = (mark) ->
	if mark == 1
		return 'O'
	else if mark == 2
		return 'X'
	else
		return ''

gameLoaded = false
players = null
username = null
onTurn = null
mark = 1
timer = new CountdownTimer($('#timer'), 10)
paused = false
leaveAndJoinQueueTimeout = null

$('#leaveAndJoinQueue').on 'click', (ev) ->
	ev.preventDefault()
	payload = JSON.stringify({
		'leaveAndJoinQueue': true
	})
	connection.send(payload)


onCellClick = (event) ->
	if onTurn != username || paused
		return

	$td = $(this)

	payload = JSON.stringify({
		'turn': {'x': $td.data('x'), 'y': $td.data('y')}
	})

	connection.send(payload)


updateOnTurnStatus = (timeRemaining) ->
	$ts = $('#turn-status')
	if onTurn == username
		$ts.html("You're on turn!")
		$ts.removeClass('label-default')
		$ts.addClass('label-success')
	else
		$ts.html("It's not your turn.")
		$ts.removeClass('label-success')
		$ts.addClass('label-default')

	$('#turn-mark').html(markSign(mark))
	timer.start(timeRemaining)

handlers = {}
handlers.identify = (data) -> username = data

handlers.pause = (data) ->
	paused = true
	timer.stop()
	$('#pause').slideDown()

	if leaveAndJoinQueueTimeout == null
		leaveAndJoinQueueTimeout = setTimeout () ->
			$('#leaveAndJoinQueue').slideDown()
		, 30*1000 # Also present in app/Game.coffee

handlers.resume = (data) ->
	if !gameLoaded
		return

	paused = false
	onTurn = players[data.onTurn]
	mark = data.mark
	timer.start()
	$('#pause').slideUp()

	clearTimeout(leaveAndJoinQueueTimeout)
	$('#leaveAndJoinQueue').hide()

	updateOnTurnStatus()

handlers.playersInQueue = (data) ->
	$('#playersInQueue').html(data)

handlers.game = (data) ->
	gameLoaded = true
	$('#pause').hide()
	$('#loss').hide()
	$('#tie').hide()
	$('#leaveAndJoinQueue').hide()

	$('#section-lobby').slideUp()
	$('#section-game').slideDown()

	players = data.players
	onTurn = players[data.onTurn]
	mark = data.mark

	code = ''
	for i in [0..data.boardSize - 1] by 1
		code += '<tr>'
		for j in [0..data.boardSize - 1] by 1
			code += '<td id="cell-' + i + '-' + j + '" data-x="' + i + '" data-y="' + j + '">' + markSign(data.board[i][j]) + '</td>'
		code += '</tr>\n'
	$('#game').html(code)
	$('td').on 'click', onCellClick

	updateOnTurnStatus(data.timeRemaining)

	if data.paused? && data.paused
		handlers.pause()

handlers.turn = (data) ->
	onTurn = data.onTurn

	timer.start()
	if !data.timeout # Player's turn timeouted
		$('#cell-' + data.x + '-' + data.y).html(markSign(mark))

	mark = (data.mark % 2) + 1
	updateOnTurnStatus()

handlers.victory = (data) ->
	$('#cell-' + data.x + '-' + data.y).html(markSign(mark))
	$('#password').html(data.password)
	$('#victory').slideDown()

handlers.loss = () ->
	$('#loss').show()
	$('#section-lobby').slideDown()
	$('#section-game').slideUp()

handlers.tie = () ->
	$('#tie').show()
	$('#section-lobby').slideDown()
	$('#section-game').slideUp()


