http = require "http"
fs = require "fs"
config = require "./config"
coffee = require "coffee-script"
io = require "socket.io"
events = require "events"

gl = exports #globals

class Channel
	constructor: ->
		@connections = {}
		@channelEvents = new events.EventEmitter()
		#@channelEvents.setMaxListeners(0) #CHECK THIS
	addClient: (client) ->
		@connections[client.person.nick] = client
		@channelEvents.on("channelevent", client.handleChannelEvent)
	delClient: (client) ->
		delete @connections[client.person.nick]
		@channelEvents.removeListener("channelevent", client.handleChannelEvent)
	nickAvail: (nick) -> not (nick of @connections) and (nick.length < 20) and not /[<>@&+]/.test(nick)
	event: (ev, source) -> @channelEvents.emit("channelevent", ev, source)
	names: -> @connections[conn].person for conn of @connections
	
channel = new Channel()

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
	if req.url == "/"
		fetch_file("html/index.html", res, treat_static)
	else if parse = /^\/static((\/[^.][^\/]*)+)$/.exec(req.url)
		fetch_file("html/#{parse[1]}", res, treat_static)
	else if parse = /^\/script((\/[^.][^\/]*)+)[.]js$/.exec(req.url)
		fetch_file("clientscript/#{parse[1]}.coffee", res, treat_coffee)
	else
		err(res, 404, "Was Not found '#{req.url}'")
)

#STUFF TO DO WITH HANDLING IRC

class ClientHandler
	constructor: (@webClient) ->
		@person = null #also used to check if you're in the channel
		@passworded = false
		
		@webClient.on("message", this.handleWebMessage)
		@webClient.on("disconnect", this.disconnect)
		
	handleWebMessage: (wmsg) =>
		message = JSON.parse(wmsg)
		if this["MESSAGE_" + message.msgType]?
			this["MESSAGE_" + message.msgType](message)
		else
			console.log("Bad message")
	
	handleChannelEvent: (chevent, source) =>
		if source != this
			this.emitMessage(chevent)
		else
			console.log("Message ignored by #{@person.nick}")
			console.log(chevent)

	
	disconnect: () =>
		channel.delClient(this)
		cevent = 
			eventType: "leave"
			person: @person
		channel.event(cevent, this)
		
	
	MESSAGE_sendmsg: (wmsg) =>
		if @passworded and @person
			cevent =
				eventType: "message"
				person: @person
				content: wmsg.content
			channel.event(cevent, this)
				
	
	MESSAGE_connect: (wmsg) =>
		if not @passworded
			wmsg_ret = 
				eventType: "denied"
		else
			if channel.nickAvail(wmsg.person.nick)
				@person = wmsg.person
				channel.addClient(this)
				wmsg_ret =
					eventType: "connected"
					person: @person
				
				this.emitMessage(wmsg_ret)
				
				cevent = 
					eventType: "join"
					person: @person
				channel.event(cevent,this)
				
				wmsg_ret = 
					eventType: "names"
					names: channel.names()
			else
				wmsg_ret =
					eventType: "badNick"
					person: @person
		this.emitMessage(wmsg_ret)
			
			
			
			
	MESSAGE_password: (wmsg) =>
		if config.password == wmsg.password
			#console.log("AUTH'D")
			@passworded = true
			wmsg_ret =
				eventType: "auth"
		else
			#console.log("NOAUTH #{wmsg.password}")
			wmsg_ret =
				eventType: "noAuth"
		this.emitMessage(wmsg_ret)
		
	emitMessage: (message) ->
		@webClient.send(JSON.stringify(message))



srv.listen(config.httport, "")

socket = io.listen(srv)

socket.on("connection", (client) ->
	z = new ClientHandler(client)
)
