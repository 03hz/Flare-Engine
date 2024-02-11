--[=[
	Flare-Engine Server Framework. Used for bootstrapping the game and accessing modules externally or internally.
	
	Server framework is loaded via server script:

	```lua
	local ServerScriptService = game:GetService("ServerScriptService");
	local Framework = require(ServerScriptService:WaitForChild("src"):WaitForChild("Framework")).bootstrapGame();
	```

	@class FlareServer
	@server
]=]

local FlareServer = {}
FlareServer.__index = FlareServer;
FlareServer.ClassName = "FlareServer";
FlareServer.__gameIsLoaded = false;

--// [ Locals: ]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ReplicatedFirst = game:GetService("ReplicatedFirst");
local ServerScriptService = game:GetService("ServerScriptService");
local RunService = game:GetService("RunService");

--// Directories
local src = ServerScriptService:FindFirstChild("src");
local Server, Client, Shared = src:WaitForChild("Server"), src:WaitForChild("Client"), src:WaitForChild("Shared");

--// [ Types: ]
local Types = require(script.Types);

type self = {
	CachedModules: typeof({}),
	GameSignals: { RBXScriptSignal }
}

--[=[
	Framework self type.

	@type self { CachedModules: typeof({}), GameSignals: { RBXScriptSignal }

	@within FlareServer
]=]

export type FrameworkType = typeof(setmetatable({} :: self, FlareServer));

--[=[
	Framework type.

	@type FrameworkType typeof(setmetatable({} :: self, FlareServer))
	@within FlareServer
]=]

--// [ Functions: ]

--[=[
	Flare-Engine Game Bootstrapper.

	@within FlareServer
	@return FrameworkType?
	@server
]=]

function FlareServer.bootstrapGame(): FrameworkType?
	if FlareServer.__gameIsLoaded or not RunService:IsServer() then return; end;

	local self = setmetatable(FlareServer, {} :: FrameworkType);

	self.CachedModules = {};
	self.GameSignals = {};
	
	do
		debug.profilebegin("Flare-Engine Bootstrap");
		local LoadingStartTick = tick();
		
		--// Caching modules into a table
		self:_ObserveAndCacheDirectory(Server);
		self:_ObserveAndCacheDirectory(Shared);

		--// Unpacking modules
		local SharedFolder = ReplicatedStorage:FindFirstChild("Shared");
		if not SharedFolder then
			SharedFolder = Instance.new("Folder");
			SharedFolder.Name = "Shared";
			SharedFolder.Parent = ReplicatedStorage;
		end;
		
		self:_UnpackModules(Shared, SharedFolder);
		self:_UnpackModules(Client, ReplicatedFirst);

		--// Loading modules
		self:_PreloadModuleDirectory(Server:WaitForChild("Modules"));

		FlareServer.__gameIsLoaded = true;
		local LoadingFinishTick = tick();
		debug.profileend();
		print("[Server]: Framework initialization took: " .. LoadingFinishTick - LoadingStartTick .. "s");
	end;

	return self;
end;

--[=[
	Framework variable storing every single cached module.

	@prop CachedModules {}
	@within FlareServer
]=]

--[=[
	Framework variable storing framework signals.

	@prop GameSignals {}
	@within FlareServer
]=]

--[=[
	Returns if the game has loaded.

	@return boolean
]=]

function FlareServer.gameIsLoaded(): boolean
	return FlareServer.__gameIsLoaded;
end;

--// [ Script Runtime: ]

--[=[
	Returns a function to require utilities and modules within framework.

	```lua
	local ServerScriptService = game:GetService("ServerScriptService");
	local Framework = require(ServerScriptService:WaitForChild("src"):WaitForChild("Framework"));

	local require = Framework:GetModulesFromCache();

	local Maid = require("Maid");
	local newMaid = Maid.new(); --> Maid

	local Spring = require("Spring");
	local newSpring = Spring.new(); --> Spring
	```

	@return RequireType
]=]

function FlareServer:GetModulesFromCache(): Types.RequireType
	return function(Args: string | ModuleScript): {}
		if type(Args) == "string" then
			local FoundModule = self.CachedModules[Args];

			if FoundModule ~= nil and type(FoundModule) ~= "table" then
				return require(FoundModule);
			else
				return FoundModule;
			end;
		else
			return require(Args);
		end;
	end;
end;

--// [ Internal: ]

function FlareServer:_ObserveAndCacheDirectory(Directory: Instance): ()
	for _, Module: Instance in ipairs(Directory:GetDescendants()) do
		coroutine.wrap(function()
			if Module:IsA("ModuleScript") then
				self.CachedModules[Module.Name] = Module;
			end;
		end)();
	end;
end;

function FlareServer:_PreloadModuleDirectory(Directory: Instance): ()
	local ModuleList = {};

	--// Requiring the modules
	for _, Module: Instance? in ipairs(Directory:GetDescendants()) do
		if Module and Module:IsA("ModuleScript") 
			and Module.Parent and not Module.Parent:IsA("ModuleScript") then

			--// Validating module
			local success, err = pcall(function()
				local RequiredModule = require(Module);

				if (type(RequiredModule) == "table") then
					ModuleList[Module.Name] = RequiredModule;
				end;
			end);

			if not success and err then
				warn(Module.Name .. "Has failed to load. Error: " .. err);
			end;
		end;
	end;

	--// Initiating modules
	for Name: string, Module: Types.BaseRuntimeModule in pairs(ModuleList) do
		if (type(Module["Init"]) == "function") then
			ModuleList[Name] = Module.Init();
		end;
		
		self.CachedModules[Name] = ModuleList[Name];
	end;

	--// Starting modules
	for Name: string, Module: Types.BaseRuntimeModule in pairs(ModuleList) do
		coroutine.wrap(function()
			if (type(Module["Start"]) == "function") then
				Module:Start();
			end;
		end)();
	end;
end;

function FlareServer:_UnpackModules(Modules: Instance, Directory: Instance?): ()
	for _, Module: Instance in ipairs(Modules:GetChildren()) do
		coroutine.wrap(function()
			Module.Parent = Directory;
		end)();
	end;
	
	Modules:Destroy();
end;

return FlareServer :: FrameworkType;