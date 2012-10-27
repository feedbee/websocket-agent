AgentServerClient = function (pushCallback)
{
	var webSocket;

	this.connect = function(config)
	{
		if (!config)
		{
			config = {};
		}
		if (!config.uri)
		{
			config.uri = "ws://localhost:8080/";
		}

		webSocket = new WebSocket(config.uri);
		webSocket.onmessage = function(evt)
		{
			console.log("Message: " + evt.data);
			if (config.onMessageCallback)
			{
				config.onMessageCallback.call(this, event.data);
			}
			if (evt.data.indexOf('Push::') == 0)
			{
				pushCallback(evt.data.substr(6));
			}
		};
		webSocket.onclose = function() {
			console.log("Socket closed");
			if (config.onCloseCallback)
			{
				config.onCloseCallback.call(this);
			}
		};
		webSocket.onopen = function() {
			console.log("Connected...");
			if (config.onOpenCallback)
			{
				config.onOpenCallback.call(this);
			}
		};
		webSocket.onerror = function(event) {
			console.log("Error: " + event.data);
			if (config.onErrorCallback)
			{
				config.onErrorCallback.call(this, event.data);
			}
		};
	}

	this.disconnect = function()
	{
		webSocket.close();
	}

	this.stop = function()
	{
		webSocket.close();
		console.log("Disconnected...");
	}

	var sendCommand = function(command, agrs)
	{
		var argsStr = agrs ? '::' + agrs.join(',') : '';
		var cmdStr = command + argsStr
		webSocket.send(cmdStr);
		console.log("Command: " + cmdStr);
	}

	this.stop = function()
	{
		sendCommand("stop");
	}

	this.start = function()
	{
		sendCommand("start");
	}

	this.setInterval = function(interval)
	{
		sendCommand("interval", [interval]);
	}
};