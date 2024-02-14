local ServerScriptService = game:GetService("ServerScriptService");
local Framework = require(ServerScriptService:WaitForChild("src"):WaitForChild("Framework"));

local ServerStatusManager = {}
ServerStatusManager.__index = ServerStatusManager;

--// Services
local Players = game:GetService("Players");
local ServerStorage = game:GetService("ServerStorage");
local RunService = game:GetService("RunService");
local MarketplaceService = game:GetService("MarketplaceService");

--// Utilities
local require = Framework:GetModulesFromCache();
local Maid = require("Maid");
local Promise = require("Promise");

--// Configuration
local Configuration = {
	CheckForUpdateInterval = 60,
	UpdateTimeWarningTable = {"1 minutes", "30 seconds", "15 seconds", 
		"5 seconds", "4 seconds", "3 seconds", "2 seconds", "1 seconds"},
	SoftShutdownPlaceID = 16017998700
}

function ServerStatusManager.Init(): {}
	local self = setmetatable({}, ServerStatusManager);

	self.TeleportServiceUtils = require(script:WaitForChild("TeleportServiceUtils"));
	self.TimeUtils = require(script:WaitForChild("TimeUtils"));

	self._runtimeMaid = Maid.new();
	self._teleportPromise = Promise.new();

	self._isScheduledToRestart = false;

	return self;
end;

function ServerStatusManager:Start()
	local SystemMessagingService = require("SystemMessagingService");

	self:_SetupServerStats();

	--// Watch for game updates
	task.spawn(function()
		while task.wait(Configuration.CheckForUpdateInterval) do
			if self._isScheduledToRestart then
				break;
			end;

			local Outdated = self:_CheckForGameUpdate();

			if Outdated then
				self._isScheduledToRestart = true;

				local TimeTillUpdate = self.TimeUtils.GetSecondsFromTimeString(Configuration.UpdateTimeWarningTable[1]);

				for _, Time in pairs(Configuration.UpdateTimeWarningTable) do
					task.spawn(function()
						local ConvertedTime = self.TimeUtils.GetSecondsFromTimeString(Time);
						task.wait(TimeTillUpdate - ConvertedTime);

						SystemMessagingService:SendServerNotification("Message", {
							Text = `Server will be restarting in {Time}.`
						});
					end);
				end;

				task.wait(TimeTillUpdate);

				local NewPromise = self:_InitiateServerRestart();
				NewPromise:Wait()
			end;
		end;
	end);
end;

function ServerStatusManager:_InitiateServerRestart()
	local ServerPlayers = Players:GetPlayers();
	if RunService:IsStudio() or #ServerPlayers == 0 or game.JobId == "" then
		return self._teleportPromise.resolved();
	end;

	local TeleportOptions = Instance.new("TeleportOptions");
	TeleportOptions.ShouldReserveServer = true;
	TeleportOptions:SetTeleportData({
		isSoftShutdownReserveServer = true;
	});

	local RemainingPlayers = {}
	local PlayerAddedCollector = Players.PlayerAdded:Connect(function(Player)
		table.insert(RemainingPlayers, Player);
	end);

	return self._teleportPromise.spawn(function(resolve, _reject)
		task.delay(1, resolve);
	end):Then(function()
		return self.TeleportServiceUtils.promiseTeleport(Configuration.SoftShutdownPlaceID, ServerPlayers, TeleportOptions);
	end)
		:Then(function(TeleportResult)
			PlayerAddedCollector:Disconnect();

			local newTeleportOptions = Instance.new("TeleportOptions");
			newTeleportOptions.ServerInstanceId = TeleportResult.PrivateServerId;
			newTeleportOptions.ReservedServerAccessCode = TeleportResult.ReservedServerAccessCode;
			newTeleportOptions:SetTeleportData({
				isSoftShutdownReserveServer = true;
			});

			local promises = {};

			if #RemainingPlayers > 0 then
			table.insert(promises, self.TeleportServiceUtils.promiseTeleport(Configuration.SoftShutdownPlaceID, RemainingPlayers, newTeleportOptions));
		end;

			self._runtimeMaid:GiveTask(Players.PlayerAdded:Connect(function(player)
				table.insert(promises, self.TeleportServiceUtils.promiseTeleport(Configuration.SoftShutdownPlaceID, { player }, newTeleportOptions));
			end));

			return self._teleportPromise.spawn(function(resolve)
				while #Players:GetPlayers() > 0 and self:_ContainsPending(promises) do
				task.wait(1);
			end;
				resolve();
			end);
		end);
end;

function ServerStatusManager:_ContainsPending(promises)
	for _, Item in pairs(promises) do
		if Item:IsPending() then
			return true;
		end;
	end;

	return false;
end;

function ServerStatusManager:_CheckForGameUpdate()
	return ServerStatusManager.ServerStats["ServerGameVersion"].Value ~= MarketplaceService:GetProductInfo(game.PlaceId).Updated;
end;

function ServerStatusManager:_SetupServerStats()
	local ServerStatsFolder = Instance.new("Folder");
	ServerStatsFolder.Name = "ServerStats";
	ServerStatsFolder.Parent = ServerStorage;
	self._runtimeMaid:GiveTask(ServerStatsFolder);

	local ServerVersion = Instance.new("StringValue");
	ServerVersion.Name = "ServerGameVersion";
	ServerVersion.Parent = ServerStatsFolder;
	
	task.spawn(function()
		ServerVersion.Value = MarketplaceService:GetProductInfo(game.PlaceId).Updated;
	end);

	ServerStatusManager.ServerStats = {}
	for _, Stat: any in pairs(ServerStatsFolder:GetDescendants()) do
		ServerStatusManager.ServerStats[Stat.Name] = Stat;
	end;
end;

return ServerStatusManager
