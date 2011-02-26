$(document).ready( ->	
	
	socket = new io.Socket()
	
	socket.connect()
	
	window.lastnick = null
	
	window.nicklist = [] #we start with a naive implementation, and optimize it later
	
	isScrolledBot = -> $("#msgs").height() <= $("#msgcont").height() + $("#msgcont").scrollTop()
	
	scrollBot = -> $("#msgcont").scrollTop($("#msgs").height()-$("#msgcont").height()+7)
	
	treatHTML = (msg) -> msg.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
	
	addMessage = (person, msg) ->
		scrbot = isScrolledBot()
		msg = treatHTML(msg)
		nick = person.nick
		if nick != window.lastnick
			$("#msgs").append("<div class='nickline floatcontainer'>#{nick} <span class='meta'>#{person.position}, #{person.campus}<br />")
		$("#msgs").append("<div class='message'>#{msg}</div>")
		window.lastnick = nick
		console.log(scrbot)
		if scrbot
			scrollBot()
		
	addEvent = (person, event) ->
		nick = person.nick
		$("#msgs").append("*** <i>#{nick} #{event}</i><br/>")
		window.lastnick = null
	
	moveNIckform =  () ->
		$("#nickForm").appendTo($("#nickchangewindow")).unbind("submit").submit( (event) ->
			event.preventDefault()
			pers = getNickformPerson()
			sendmsg(
				msgType: "changeNick"
				newperson: pers
			)
		)
		$("#nickForm > input[type=submit]").val("Change nickname")
	
	getNickformPerson = () ->
		pers = 
			nick: $("#nickBox").val()
			position: $("#posBox").val()
			campus: $("#campBox").val()
		return pers
	
	toggleNCWin = ->
		$(".nickchange").toggleClass("nch_activated")
		if $("#nickchangewindow").is(":visible")
			$("#nickchangewindow").hide()
		else
			$("#nickchangewindow").show()

	nickify =  ->
			$("#nickindicator").empty()
			$("#nickindicator").append("You're signed in as #{treatHTML(window.person.nick)} <a href='#' class='nickchange'>(Change nicknames)</a>")
			$(".nickchange").click(->
				event.preventDefault()
				toggleNCWin()
			)
		
	addPerson = (person) ->
		nick = person.nick
		nick2 = nick.replace("\"", "@")
		$("#nicks").append("<li data-nickname=\"#{nick2}\">#{nick}</li>")
		#INEFFICIENT, OPTIMIZE
		window.nicklist.push(nick)
	
	delPerson = (person) ->
		nick = person.nick
		nick2 = nick.replace("\"", "@")
		$("li[data-nickname=\"#{nick2}\"]").remove()
		window.nicklist = window.nicklist.filter((n) -> n != nick) 
	
	events =
		connected: (msg) ->
			console.log(msg)
			window.person = msg.person
			$("#loadingscreen").hide()
			$("#msgscreen").slideDown()
			$("#msgBox").focus()
			nickify()
			moveNIckform()
		message: (msg) ->
			addMessage(msg.person, msg.content)
		badNick: (msg) ->
			#check if we're already in
			if not window.person
				$("#loadingscreen").hide()
				$("#nickscreen").slideDown()
				$("#errmsg").text("Bad nickname")
				$("#errmsg").show()
			else
				$("#nc_err").show()
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
		nickChange: (msg) ->
			delPerson(msg.oldperson)
			addPerson(msg.newperson)
			addEvent(msg.oldperson, "is now known as #{msg.newperson.nick}") #TODO: Nicer handling of person change
			
		selfChangeNick: (msg) ->
			delPerson(window.person)
			addPerson(msg.newperson)
			addEvent(window.person, "is now known is #{msg.newperson.nick}")
			window.person = msg.newperson
			toggleNCWin()
			
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
		pers = getNickformPerson()
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
	
	$("#msgBox").keydown( (event) ->
		if (event.which == 9)
			event.preventDefault()
			curloc = $("#msgBox").caret().start
			before = $("#msgBox").val().substring(0, curloc)
			after = $("#msgBox").val().substring(curloc)
			console.log(before)
			console.log(after)
			
			start = /([^ ,.?!]+)$/.exec(before)[1]
			if start? and start != ""
				matchingnicks = window.nicklist.filter((n) -> n.substring(0, start.length) == start)
				console.log(matchingnicks)
				if (matchingnicks.length != 0)
					$("#msgBox").val(before + matchingnicks[0].substring(start.length) + after)
					newloc = curloc+matchingnicks[0].length - start.length
					$("#msgBox").caret(newloc, newloc)
					
	)
	
	$("#nickch_close").click( (event) ->
			event.preventDefault()
			$("#nickchangewindow").hide()
			$(".nickchange").toggleClass("nch_activated")
		)
	
)
