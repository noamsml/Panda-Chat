$(document).ready( ->
	istate_conn = 1
	istate_nick = 2
	istate_chat = 3
	
	window.ircState = istate_conn
	
	socket = new io.Socket("localhost")
	
	socket.connect()
	
	
	isScrolledBot = -> $("#msgs").height() <= $("#msgcont").height() + $("#msgcont").scrollTop()
	
	scrollBot = -> $("#msgcont").scrollTop($("#msgs").height()-$("#msgcont").height())
	
	addMessage = (nick, msg) ->
		scrbot = isScrolledBot()
		msg = msg.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
		$("#msgs").append("<b>&lt;#{nick}&gt;</b> #{msg}<br />")
		console.log(scrbot)
		if scrbot
			scrollBot()
		
	addEvent = (nick, event) ->
		$("#msgs").append("*** <i>#{nick} #{event}</i><br/>")


	addNick = (nick) ->
		nick2 = nick.replace("\"", "@")
		$("#nicks").append("<li data-nickname=\"#{nick2}\">#{nick}</li>")
	
	delNick = (nick) ->
		nick2 = nick.replace("\"", "@")
		$("li[data-nickname=\"#{nick2}\"]").remove()
	
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
			addNick(msg.nick)
			addEvent(msg.nick, "joined the channel")
		leave: (msg) ->
			delNick(msg.nick)
			addEvent(msg.nick, "left the channel")
		kick: (msg) ->
			delNick(msg.nick)
			addEvent(msg.nick, "was kicked by #{msg.op}")
		disconnected: (msg) ->
			$("#errmsg").text("You have been disconnected")
			$("#errmsg").show()
		kicked: (msg) ->
			$("#errmsg").text("You have been kicked from the channel")
			$("#errmsg").show()
		nick: (msg) ->
			delNick(msg.oldnick)
			addNick(msg.newnick)
			addEvent(msg.oldnick, "is now known as #{msg.newnick}")
		auth: (msg) ->
			$("#passscreen").hide()
			$("#nickscreen").show()
			$("#errmsg").hide()
		noAuth: (msg) ->
			$("#errmsg").text("Wrong password")
			$("#errmsg").show()
		names: (msg) ->
			for nick in msg.nicks
				addNick(nick)
			
				
		
	
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
		if $("#msgBox").val()			
			sendmsg({msgType: "sendmsg", content: $("#msgBox").val()})
			addMessage(window.nick, $("#msgBox").val())
			$("#msgBox").val('')
	)
	
	
	$("#nickForm").submit( (event) ->
		event.preventDefault()
		if $("#nickBox").val()
			sendmsg({msgType: "connect", nick: $("#nickBox").val()})
			$("#nickscreen").hide()
			$("#loadingscreen").show()
			$("#errmsg").hide()
	)
	
	
	$("#passForm").submit( (event) ->
		event.preventDefault()
		if $("#passBox").val()
			sendmsg({msgType: "password", password: $("#passBox").val()})
	)
	
)
