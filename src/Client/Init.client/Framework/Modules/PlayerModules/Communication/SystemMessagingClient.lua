local Framework = require(script.Parent.Parent.Parent.Parent);

local SystemMessagingClient = {}
SystemMessagingClient.__index = SystemMessagingClient;

--// Utilities
local require = Framework:GetModulesFromCache();
local Network = require("Network");

function SystemMessagingClient:Start()
	local NotificationManager = require("NotificationManager");

	Network:BindEvents({
		SendSystemNotification = function(NotificationType: string, NotificationData: {})
			NotificationManager:SendNotification(NotificationType, NotificationData);
		end,
		
		SoftShutdownInitiated = function()
			--// local SoftShutdownUI = require("SoftShutdownUI");
			--// Do something
		end,
	});
end;

return SystemMessagingClient
