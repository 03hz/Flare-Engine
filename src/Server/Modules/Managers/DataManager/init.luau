local ServerScriptService = game:GetService("ServerScriptService");
local Framework = require(ServerScriptService:WaitForChild("src"):WaitForChild("Framework"));

local DataManager = {}
DataManager.__index = DataManager;

--// [ Variables: ]

--// Services
local Players = game:getService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService")

--// Utilities
local require = Framework:GetModulesFromCache();
local ProfileService = require("ProfileService");
local Network = require("Network");
local Maid = require("Maid");

--// Default profile
local DefaultProfile = require(script:WaitForChild("DefaultDataProfile"));

--// [ Constructor: ]
function DataManager.Init(): self
	local self = setmetatable({}, DataManager);
	
	self._runtimeMaid = Maid.new();
	
	--// Data store
	self.PlayerDataProfileStore = ProfileService.GetProfileStore(
		"PlayerData",
		DefaultProfile
	)

	self.DataProfiles = require(script:WaitForChild("CurrentProfiles"));

	--// Connections
	for _, Player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:PlayerAdded(Player);
		end);
	end;

	self._runtimeMaid:GiveTask(Players.PlayerAdded:Connect(function(Player)
		self:PlayerAdded(Player);
	end));

	self._runtimeMaid:GiveTask(Players.PlayerRemoving:Connect(function(Player)
		self:PlayerRemoving(Player);
	end));

	return self;
end;

--// [ Functions: ]

--// On player added function
function DataManager:PlayerAdded(Player)
	local Profile = self.PlayerDataProfileStore:LoadProfileAsync("Player_" .. Player.UserId);
	
	if Profile ~= nil then
		Profile:AddUserId(Player.UserId); 
		Profile:Reconcile();
		Profile:ListenToRelease(function()
			self.DataProfiles[Player] = nil;
			Player:Kick();
		end);

		if Player:IsDescendantOf(Players) == true then
			self.DataProfiles[Player] = Profile;
			self:OnLoaded(Player, Profile);
		else
			Profile:Release();
		end
	else
		Player:Kick();
	end;
end;

--// Run on player stats loaded
function DataManager:OnLoaded(Player, Profile)
	local NewClientDataLoadedBool = Instance.new("BoolValue");
	NewClientDataLoadedBool.Parent = Player;
	NewClientDataLoadedBool.Name = "ClientDataLoaded";
	NewClientDataLoadedBool.Value = true;
end;

--// On player removing function
function DataManager:PlayerRemoving(Player)
	local Profile = self.DataProfiles[Player];
	if Profile ~= nil then
		Profile:Release();
	end;
end;

function DataManager:SearchTable(Table, Directory)
	for	_, Value in pairs(Directory) do
		Table = Table[Value];
	end;

	return Table;
end;

--// Retrieve data from specified directory
function DataManager:Get(Player, Directory)
	local ReturnData = DataManager:SearchTable(self.DataProfiles[Player].Data, Directory);

	if ReturnData ~= nil then
		return ReturnData;
	else
		warn("[DataManager]: Data not found.");
		return nil;
	end;
end;

return DataManager