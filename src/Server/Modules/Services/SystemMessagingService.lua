local ServerScriptService = game:GetService("ServerScriptService");
local Framework = require(ServerScriptService:WaitForChild("src"):WaitForChild("Framework"));

local SystemMessagingService = {}
SystemMessagingService.__index = SystemMessagingService;

type MessageData = {
	Prefix: string?,
	Message: string,
	Color: Color3?,
	Font: Font?,
	TextSize: number?
}

local require = Framework:GetModulesFromCache();
local Network = require("Network");

function SystemMessagingService:SendServerNotification(NotificationType: string, NotificationData: {})
	if NotificationData then
		Network:FireAllClients("SendSystemNotification", NotificationType, NotificationData);
	end;
end;

return SystemMessagingService
