$(document).ready( ->
	socket = new io.Socket("localhost")

	socket.connect()

	socket.on("message", (message) ->
		$("#msgs").append("#{message}<br />")
	)

	$("#msgBtn").click( (event) ->
		event.preventDefault()
		socket.send($("#msgBox").val())
	)
)
