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
		
	addEvent = (nick, event) ->
		$("#msgs").append("*** <i>#{nick} #{event}</i><br/>")
	
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
			$("#errmsg").text("Bad nickname")
			$("#errmsg").show()
		join: (msg) ->
			addEvent(msg.nick, "joined the channel")
		leave: (msg) ->
			addEvent(msg.nick, "left the channel")
		kick: (msg) ->
			addEvent(msg.nick, "was kicked by #{msg.op}")
		disconnected: (msg) ->
			$("#errmsg").text("You have been disconnected")
			$("#errmsg").show()
		kicked: (msg) ->
			$("#errmsg").text("You have been kicked from the channel")
			$("#errmsg").show()
		nick: (msg) ->
			addEvent(msg.oldnick, "is now known as #{msg.newnick}")
		auth: (msg) ->
			$("#passscreen").hide()
			$("#nickscreen").show()
			$("#errmsg").hide()
		noAuth: (msg) ->
			$("#errmsg").text("Wrong password")
			$("#errmsg").show()
			
				
		
	
	sendmsg = (msg) ->
		socket.send(JSON.stringify(msg))
		
	socket.on("message", (message) ->
		m = JSON.parse(message)
		events[m.msgType]?(m)
	)

	socket.on("connect", ->
		window.ircState = istate_nick
		$("#passscreen").show()	
	)

	
	$("#msgForm").submit( (event) ->
		event.preventDefault()
		sendmsg({msgType: "sendmsg", content: $("#msgBox").val()})
		addMessage(window.nick, $("#msgBox").val())
		$("#msgBox").val('')
	)
	
	
	$("#nickForm").submit( (event) ->
		event.preventDefault()
		sendmsg({msgType: "connect", nick: $("#nickBox").val()})
		$("#nickscreen").hide()
		$("#loadingscreen").show()
		$("#errmsg").hide()
	)
	
	
	$("#passForm").submit( (event) ->
		event.preventDefault()
		sendmsg({msgType: "password", password: $("#passBox").val()})
	)
	
)
