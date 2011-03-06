express = require "express"
#connect = require "connect" #?
fs = require "fs"
config = require "./config"
coffee = require "coffee-script"
io = require "socket.io"
events = require "events"
webclient = require "./webclient"

gl = exports #globals

#TODO: Prevent upfucking of nick list

class Channel
	constructor: ->
		@connections = {}
		@channelEvents = new events.EventEmitter()
		#@channelEvents.setMaxListeners(0) #CHECK THIS
	addClient: (client) ->
		@connections[client.person.nick] = client
		@channelEvents.on("channelevent", client.handleChannelEvent)
		cevent = 
					eventType: "join"
					person: client.person
		this.event(cevent, client)
	delClient: (client) ->
		delete @connections[client.person.nick]
		@channelEvents.removeListener("channelevent", client.handleChannelEvent)
		cevent = 
				eventType: "leave"
				person: client.person
		this.event(cevent, client)
	nickAvail: (nick) -> not (nick of @connections) and (nick.length < 20) and not /[<>@&+]/.test(nick)
	event: (ev, source) -> @channelEvents.emit("channelevent", ev, source)
	names: -> @connections[conn].person for conn of @connections
	changeClientNick: (client, newperson) ->
		oldperson = client.person
		delete @connections[client.person.nick]
		@connections[newperson.nick] = client
		cevent = 
				eventType: "nickChange"
				oldperson: client.person
				newperson : newperson
		this.event(cevent, client)
		
	
channel = new Channel()


	

# STUFF TO DO WITH SERVING FILES
#err = (res, code, msg) ->
#	res.writeHead(code, {"Content-type" : "text/html"})
#	res.end("<html><body><h1>#{code} #{msg}</h1></body></html>")


		

app = express.createServer( )

app.configure ->
	app.use express.static(__dirname + "/html")
	app.use express.errorHandler({dumpExceptions: true, showStack: true})

app.get "/script/:fname.js", (req, res,next) ->
	filename = __dirname + "/clientscript/#{req.params.fname}.coffee"
	fs.readFile filename, "utf8", (error, data) ->
		if error
			#throw new Error("404 Not found  " + fname)
			next(error)
		else
			try
				jsource = coffee.compile(data)
				res.writeHead(200, {"Content-type" : "text/javascript"})
				res.end(jsource)
			catch error
				next(new Error("500 CoffeeScript compilation failed"))		
	


app.listen(config.httport, "")

socket = io.listen(app)

socket.on("connection", (client) ->
	z = new webclient.ClientHandler(client, channel, config)
)
