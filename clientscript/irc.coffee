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
			$("#nickscreen").hide()
			$("#msgscreen").show()
		ircmsg: (msg) ->
			addMessage(msg.nick, msg.content)
		
	
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

	
	$("#msgBtn").click( (event) ->
		event.preventDefault()
		sendmsg({msgType: "sendmsg", content: $("#msgBox").val()})
		addMessage(window.nick, $("#msgBox").val())
		$("#msgBox").val('')
	)
	
	$("#nickBtn").click( (event) ->
		event.preventDefault()
		sendmsg({msgType: "connect", nick: $("#nickBox").val()})
	)
	
	
	$("#nickscreen").show()	
	
)
