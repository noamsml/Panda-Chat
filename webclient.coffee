class ClientHandler
	constructor: (@webClient, @channel, @config) ->
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
		#else
		#	console.log("Message ignored by #{@person.nick}")
		#	console.log(chevent)
	
	disconnect: () =>
		if @person
			@channel.delClient(this)
	
	MESSAGE_sendmsg: (wmsg) =>
		if @person
			cevent =
				eventType: "message"
				person: @person
				content: wmsg.content
			@channel.event(cevent, this)
				
	
	MESSAGE_connect: (wmsg) =>
		if @person
			return #Quick and dirty
			
		if not @passworded
			wmsg_ret = 
				eventType: "denied"
		else
			if @channel.nickAvail(wmsg.person.nick)
				@person = wmsg.person
				@channel.addClient(this)
				wmsg_ret =
					eventType: "connected"
					person: @person
				this.emitMessage(wmsg_ret)
				
				wmsg_ret = 
					eventType: "names"
					names: @channel.names()
			else
				wmsg_ret =
					eventType: "badNick"
					person: @person
		this.emitMessage(wmsg_ret)
			
			
			
			
	MESSAGE_password: (wmsg) =>
		if @config.password == wmsg.password #Move this outside of webclient code?
			#console.log("AUTH'D")
			@passworded = true
			wmsg_ret =
				eventType: "auth"
		else
			#console.log("NOAUTH #{wmsg.password}")
			wmsg_ret =
				eventType: "noAuth"
		this.emitMessage(wmsg_ret)
	
	MESSAGE_changeNick: (wmsg) =>
			if @channel.nickAvail(wmsg.newperson.nick)
				@channel.changeClientNick(this, wmsg.newperson)
				@person = wmsg.newperson
				wmsg_ret =
					eventType: "selfChangeNick"
					newperson : @person
			else
				wmsg_ret = 
					eventType: "badNick"
					person: wmsg.newperson
			this.emitMessage(wmsg_ret)
				
		
	emitMessage: (message) ->
		@webClient.send(JSON.stringify(message))



exports.ClientHandler = ClientHandler
