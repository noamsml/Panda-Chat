$(document).ready( ->
	
	nickname = "noamsml|web2"
	
	addMessage = (nick, message) ->
		message = message.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
		$("#msgs").append("<b>&lt;#{nick}&gt;</b> #{message}<br />")
	
	socket = new io.Socket("localhost")

	socket.connect()

	socket.on("message", (message) ->
		m = JSON.parse(message)
		if m.msgType == "ircmsg"
			addMessage(m.from, m.content)
	)
	
	socket.on("connect", ->
		socket.send(JSON.stringify({msgType: "connect", nick: nickname }))
	)

	$("#msgBtn").click( (event) ->
		event.preventDefault()
		socket.send(JSON.stringify({msgType: "sendmsg", content: $("#msgBox").val()}))
		addMessage(nickname, $("#msgBox").val())
		$("#msgBox").val('')
	)
)
