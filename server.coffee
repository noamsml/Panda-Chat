http = require "http"
fs = require "fs"
config = require "./config"
coffee = require "coffee-script"
io = require "socket.io"
irc = require "irc-js"

gl = exports #globals


connections = []

# STUFF TO DO WITH SERVING FILES
err = (res, code, msg) ->
	res.writeHead(code, {"Content-type" : "text/html"})
	res.end("<html><body><h1>#{code} #{msg}</h1></body></html>")

fetch_file = (fname, res, callback) ->
	filename = config.fsroot + fname
	fs.readFile(filename, "utf8", (error, data) ->
		if error
			err(res,404,"Not Found")
		else
			callback(res,data,filename)			
	)
	
treat_static =  (res, data, filename) ->
	ctype = if fparse = /.([a-zA-Z]+)$/.exec(filename)
				switch fparse[1]
					when "txt" 
						"text/plain"
					when "html"
						"text/html"
					when "jpg", "jpeg"
						"image/jpeg"
					when "png"
						"image/png"
					when "js"
						"text/javascript"
					else
						"application/octet-stream" #?
			else
				"text/plain"
	res.writeHead(200, {"Content-type" : ctype})
	res.end(data)

	
treat_coffee = (res, data, filename) ->
	try
		jsource = coffee.compile(data)
		res.writeHead(200, {"Content-type" : "text/javascript"})
		res.end(jsource)
	catch error
		err(res,500,"CoffeScript Compilation Failed: #{error}")
		

srv = http.createServer( (req, res) ->
	if parse = /^\/static((\/[^.][^\/]*)+)$/.exec(req.url)
		fetch_file("html/#{parse[1]}", res, treat_static)
	else if parse = /^\/script((\/[^.][^\/]*)+)[.]js$/.exec(req.url)
		fetch_file("clientscript/#{parse[1]}.coffee", res, treat_coffee)
	else
		err(res, 404, "Not found")
)

#STUFF TO DO WITH HANDLING IRC

class ClientHandler
	constructor: (@webClient) ->
		
		@ircClient = null
		@nick = null
		@passworded = null
		
		@connected = false
		
		@webClient.on("message", this.handleWebMessage)
		@webClient.on("disconnect", this.quit)
		
		
		
		
	handleWebMessage: (wmsg) =>
		message = JSON.parse(wmsg)
		if this["MESSAGE_" + message.msgType]?
			this["MESSAGE_" + message.msgType](message)
		else
			console.log("Bad message")
	
	handleIRCMessage: (imsg) =>
			console.log("MESSAGE")
			wmsg = 
				msgType: "ircmsg"
				content: imsg.params[1]
				nick: imsg.person.nick
			this.emitMessage(wmsg)
	
	
	handleIRCJoin: (imsg) =>
		if imsg.person.nick == @nick
			wmsg = 
				msgType: "connect"
				nick: @nick
		else
			wmsg = 
				msgType: "join"
				nick: imsg.person.nick
		this.emitMessage(wmsg)
	
	handleBadNick: (imsg) =>
		wmsg = 
			msgType: "badnick"
			nick: imsg.params[1]
		this.emitMessage(wmsg)
	
	handleIRCNick: (imsg) =>
		if imsg.person.nick == @nick
			@nick = imsg.params[0]
			wmsg =
				msgType: "changeNick"
				nick: imsg.params[1]
		else
			wmsg =
				msgType: "nick"
				newnick: imsg.params[1]
				oldnick: imsg.person.nick
		this.emitMessage(wmsg)
	
	handleIRCLeave: (imsg) =>
		wmsg =
			msgType: "leave"
			nick: imsg.person.nick
		this.emitMessage(wmsg)
	
	handleIRCKick: (imsg) =>
		if imsg.params[1] == @nick
			wmsg =
				msgType: "kicked"
			@connected = false
			@ircClient?.quit("kicked")
		else
			wmsg =
				msgType: "kick"
				op: imsg.person.nick
				nick: imsg.params[1]
		this.emitMessage(wmsg)
		
	autoJoin: (imsg) =>
		@connected = true
		@ircClient?.join(config.channel, config.key)
	
	handleError: (imsg) ->
		console.log("err #{imsg.params[0]}")
	
	emitMessage: (message) ->
		@webClient.send(JSON.stringify(message))
	
	quit: () =>
		@ircClient?.quit("Web client closed")
		@connnected = false
		
	handleDisconnect: =>
		wmsg = 
			msgType: "disconnected"
		@connected = false
	
	
	MESSAGE_sendmsg: (wmsg) =>
		if @connected
			console.log "sending"
			@ircClient?.privmsg(config.channel, wmsg.content)
	
	MESSAGE_connect: (wmsg) =>
		if not @passworded
			wmsg_ret = 
				msgType: "denied"
			this.emitMessage(wmsg_ret)
		else if @connected
			@ircClient.nick(wmsg.nick)
			@nick = wmsg.nick
		else
			console.log "connecting"
			console.log wmsg
			@ircClient = new irc({server: "irc.freenode.net", nick: wmsg.nick})
			@nick = wmsg.nick
			
			@ircClient.addListener("001", this.autoJoin)
			@ircClient.addListener("join", this.handleIRCJoin)
			@ircClient.addListener("part", this.handleIRCLeave)
			@ircClient.addListener("quit", this.handleIRCLeave)
			@ircClient.addListener("nick", this.handleIRCNick)
			@ircClient.addListener("kick", this.handleIRCKick)
			@ircClient.addListener("privmsg", this.handleIRCMessage)
			@ircClient.addListener("433", this.handleBadNick)
			@ircClient.addListener("error", this.handleError)
			@ircClient.addListener("disconnect", this.handleDisconnect)
			
			@ircClient.connect()
	MESSAGE_password: (wmsg) =>
		if config.password == wmsg.password
			#console.log("AUTH'D")
			@passworded = true
			wmsg_ret =
				msgType: "auth"
		else
			#console.log("NOAUTH #{wmsg.password}")
			wmsg_ret =
				msgType: "noAuth"
		this.emitMessage(wmsg_ret)



srv.listen(1234)

socket = io.listen(srv)

socket.on("connection", (client) ->
	z = new ClientHandler(client)
)
