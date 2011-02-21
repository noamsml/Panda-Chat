http = require "http"
fs = require "fs"
config = require "./config"
coffee = require "coffee-script"
io = require "socket.io"
events = require "events"
webclient = require "./webclient"

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


srv.listen(config.httport, "")

socket = io.listen(srv)

socket.on("connection", (client) ->
	z = new webclient.ClientHandler(client, channel)
)
