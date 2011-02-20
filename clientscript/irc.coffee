$(document).ready( ->	
	
	socket = new io.Socket()
	
	socket.connect()
	
	
	isScrolledBot = -> $("#msgs").height() <= $("#msgcont").height() + $("#msgcont").scrollTop()
	
	scrollBot = -> $("#msgcont").scrollTop($("#msgs").height()-$("#msgcont").height())
	
	treatHTML = (msg) -> msg.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
	
	addMessage = (person, msg) ->
		scrbot = isScrolledBot()
		msg = treatHTML(msg)
		nick = person.nick
		$("#msgs").append("<b>#{nick} (#{person.position}):</b> #{msg}<br />")
		console.log(scrbot)
		if scrbot
			scrollBot()
		
	addEvent = (person, event) ->
		nick = person.nick
		$("#msgs").append("*** <i>#{nick} #{event}</i><br/>")


	addPerson = (person) ->
		nick = person.nick
		nick2 = nick.replace("\"", "@")
		$("#nicks").append("<li data-nickname=\"#{nick2}\">#{nick}</li>")
	
	delPerson = (person) ->
		nick = person.nick
		nick2 = nick.replace("\"", "@")
		$("li[data-nickname=\"#{nick2}\"]").remove()
	
	events =
		connected: (msg) ->
			console.log(msg)
			window.person = msg.person
			$("#loadingscreen").hide()
			$("#msgscreen").slideDown()
			$("#msgBox").focus()
		message: (msg) ->
			addMessage(msg.person, msg.content)
		badNick: (msg) ->
			#for now
			#TODO: handle nick changes
			$("#loadingscreen").hide()
			$("#nickscreen").slideDown()
			$("#errmsg").text("Bad nickname")
			$("#errmsg").show()
		join: (msg) ->
			addPerson(msg.person)
			addEvent(msg.person, "joined the channel")
		leave: (msg) ->
			delPerson(msg.person)
			addEvent(msg.person, "left the channel")
		#kick: (msg) ->
		#	delNick(msg.nick)
		#	addEvent(msg.nick, "was kicked by #{msg.op}")
		#disconnected: (msg) ->
		#	$("#errmsg").text("You have been disconnected")
		#	$("#errmsg").show()
		#kicked: (msg) ->
		#	$("#errmsg").text("You have been kicked from the channel")
		#	$("#errmsg").show()
		#nick: (msg) ->
		#	delNick(msg.oldnick)
		#	addNick(msg.newnick)
		#	addEvent(msg.oldnick, "is now known as #{msg.newnick}")
		auth: (msg) ->
			$("#passscreen").slideUp()
			$("#nickscreen").slideDown()
			$("#nickBox").focus()
			$("#errmsg").hide()
		noAuth: (msg) ->
			$("#errmsg").text("Wrong password")
			$("#errmsg").show()
		names: (msg) ->
			for person in msg.names
				addPerson(person)
			
				
		
	
	sendmsg = (msg) ->
		socket.send(JSON.stringify(msg))
		
	socket.on("message", (message) ->
		m = JSON.parse(message)
		console.log(m)
		events[m.eventType]?(m)
	)

	socket.on("connect", ->
		$("#passscreen").show()
		$("#passbox").focus()	
	)

	
	$("#msgForm").submit( (event) ->
		event.preventDefault()
		if $("#msgBox").val()			
			sendmsg({msgType: "sendmsg", content: $("#msgBox").val()})
			addMessage(window.person, $("#msgBox").val())
			$("#msgBox").val('')
	)
	
	
	$("#nickForm").submit( (event) ->
		event.preventDefault()
		pers = 
			nick: $("#nickBox").val()
			position: $("#posBox").val()
			campus: $("#campBox").val()
		if $("#nickBox").val()
			sendmsg({msgType: "connect", person: pers})
			$("#nickscreen").slideUp()
			$("#loadingscreen").show()
			$("#errmsg").hide()
	)
	
	
	$("#passForm").submit( (event) ->
		event.preventDefault()
		if $("#passBox").val()
			sendmsg({msgType: "password", password: $("#passBox").val()})
	)
	
)
