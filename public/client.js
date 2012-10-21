AgentServerClient = function (pushCallback)
{
	var webSocket;

	this.connect = function()
	{
		webSocket = new WebSocket("ws://localhost:8080/");
		webSocket.onmessage = function(evt)
		{
			console.log("Message: " + evt.data);
			if (evt.data.indexOf('Push::') == 0)
			{
				pushCallback(evt.data.substr(6));
			}
		};
		webSocket.onclose = function() { console.log("Socket closed"); };
		webSocket.onopen = function() {
		  console.log("Connected...");
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