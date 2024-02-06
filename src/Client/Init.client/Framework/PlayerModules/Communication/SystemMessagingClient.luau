local Framework = require(script.Parent.Parent.Parent);

local SystemMessagingClient = {}
SystemMessagingClient.__index = SystemMessagingClient;

local TextChatService = game:GetService("TextChatService");
local GeneralChatChannel = TextChatService.TextChannels:WaitForChild("RBXGeneral");

--// Utilities
local require = Framework:GetModulesFromCache();
local Network = require("Network");

function SystemMessagingClient.Init(): self
	local self = setmetatable({}, SystemMessagingClient);
	
	Network:BindEvents({
		SendSystemMessage = function(MessageData)
			GeneralChatChannel:DisplaySystemMessage("<font color=\"rgb(255, 226, 64)\">" .. "[" .. (MessageData.Prefix or "SYSTEM") .. "]: " .. MessageData.Message .. "</font>");
			
			--[[StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = "[" .. (MessageData.Prefix or "SYSTEM") .. "]: " .. MessageData.Message,
				Color = MessageData.Color or Color3.fromRGB(255, 226, 64),
				Font = MessageData.Font or Enum.Font.SourceSansBold,
				TextSize = MessageData.TextSize or 18
			});]]
		end,
		
		SoftShutdownInitiated = function()
			local SoftShutdownUI = require("SoftShutdownUI");
			
		end,
	});
	
	return self;
end;

return SystemMessagingClient
