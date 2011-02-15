http = require "http"
fs = require "fs"
config = require "./config"


fetch_static = (fname, res) ->
	filename = config.fsroot + "html" + fname
	fs.readFile(filename, (error, data) ->
		if error
			res.writeHead(400, {"Content-type" : "text/html"})
			res.end("<html><body><h1>404 :(</h1></body></html>")
		else
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
						
	)

	

srv = http.createServer( (req, res) ->
	if parse = /\/static((\/[^.][^\/]*)+)/.exec(req.url)
		fetch_static(parse[1], res)
	else
		res.writeHead(400, {"Content-type" : "text/plain"})
		res.end("404 :(. URL #{req.url}")
)

srv.listen(1234, "")
