$(document).ready( ->
	istate_conn = 1
	istate_nick = 2
	istate_chat = 3
	
	window.ircState = istate_conn
	
	socket = new io.Socket("localhost")
	
	socket.connect()
	
	addMessage = (nick, msg) ->
		msg = msg.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
		$("#msgs").append("<b>&lt;#{nick}&gt;</b> #{msg}<br />")
	
	events =
		connect: (msg) ->
			console.log(msg)
			window.nick = msg.nick
			$("#loadingscreen").hide()
			$("#msgscreen").show()
			$("#msgBox").focus()
		ircmsg: (msg) ->
			addMessage(msg.nick, msg.content)
		badnick: (msg) ->
			#for now
			#TODO: handle nick changes
			$("#loadingscreen").hide()
			$("#nickscreen").show()
			$("#nickerror").show()
		
	
	sendmsg = (msg) ->
		socket.send(JSON.stringify(msg))
		
	socket.on("message", (message) ->
		m = JSON.parse(message)
		events[m.msgType]?(m)
	)

	socket.on("connect", ->
		window.ircState = istate_nick
		$("#nickscreen").show()
	)

	
	$("#msgForm").submit( (event) ->
		event.preventDefault()
		sendmsg({msgType: "sendmsg", content: $("#msgBox").val()})
		addMessage(window.nick, $("#msgBox").val())
		$("#msgBox").val('')
	)
	
	
	
	
	$("#nickBtn").click( (event) ->
		event.preventDefault()
		sendmsg({msgType: "connect", nick: $("#nickBox").val()})
		$("#nickscreen").hide()
		$("#loadingscreen").show()
	)
	
	
	$("#nickscreen").show()	
	
)
