http = require "http"
fs = require "fs"
config = require "./config"
coffee = require "coffee-script"

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
		res.writeHead(400, {"Content-type" : "text/plain"})
		res.end("404 :(. URL #{req.url}")
)

srv.listen(1234, "")
