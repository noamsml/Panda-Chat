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
				from: imsg.person.nick
			this.emitMessage(wmsg)
			
	handleIRCJoin: (imsg) =>
		console.log("JOINED")
		wmsg = 
			msgType: "connect"
		this.emitMessage(wmsg)
		
	autoJoin: (imsg) =>
		console.log "joining"
		@connected = true
		@ircClient?.join(config.channel, config.key)
	
	emitMessage: (message) ->
		@webClient.send(JSON.stringify(message))
	
	quit: () =>
		@ircClient?.quit("Web client closed")
		
	
	handleError: (imsg) ->
		console.log("err")
	
	MESSAGE_sendmsg: (wmsg) =>
		console.log "sending"
		@ircClient?.privmsg(config.channel, wmsg.content)
	
	MESSAGE_connect: (wmsg) =>
		console.log "connecting"
		@ircClient = new irc({server: "irc.freenode.net", nick: wmsg.nick})
		
		@ircClient.addListener("001", this.autoJoin)
		@ircClient.addListener("join", this.handleIRCJoin)
		@ircClient.addListener("privmsg", this.handleIRCMessage)
		@ircClient.addListener("error", this.handleIRCMessage)
		
		@ircClient.connect()
		
	
		
		



srv.listen(1234)

socket = io.listen(srv)

socket.on("connection", (client) ->
	z = new ClientHandler(client)
)
