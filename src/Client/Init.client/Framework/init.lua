--[=[
	Flare-Engine Client Framework. Handles client modules.
	
	Client framework is loaded via client script that has been replicated by the server:

	```lua
	local Players = game:GetService("Players");
	local LocalPlayer = Players.LocalPlayer;

	script.Parent = LocalPlayer.PlayerScripts;
	local Framework = require(script:WaitForChild("Framework")).loadClient();
	```

	@class FlareClient
	@client
]=]

local FlareClient = {}
FlareClient.__index = FlareClient;
FlareClient.ClassName = "FlareClient";
FlareClient.__gameIsLoaded = false;

--// [ Locals: ]

--// Services and requires
local Workspace = game:GetService("Workspace");
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");

--// Folders
local ModuleFolder = script:WaitForChild("Modules");
local CharacterModules = ModuleFolder:WaitForChild("CharacterModules");
local PlayerModules = ModuleFolder:WaitForChild("PlayerModules");

--// [ Types: ]
local Types = require(script.Types);

type self = {
	CachedModules: typeof({}),
	
	GameVariables: {
		LocalPlayer: Player,
		Character: Model?,
		Humanoid: Humanoid?,
		Camera: Camera
	},
	
	GameSignals: { RBXScriptSignal },
	LocalClientStorage: Instance
}

--[=[
	Framework self type.

	@type self { CachedModules: typeof({}), GameVariables: { LocalPlayer: Player, Character: Model?, Humanoid: Humanoid?, Camera: Camera }, GameSignals: { RBXScriptSignal }, LocalClientStorage: Instance }

	@within FlareClient
]=]

export type FrameworkType = typeof(setmetatable({} :: self, FlareClient));

--[=[
	Framework type.

	@type FrameworkType typeof(setmetatable({} :: self, FlareClient))
	@within FlareClient
]=]

--// [ Constructor: ]

--[=[
	Flare-Engine Client module loader.

	@within FlareClient
	@return FrameworkType?
	@client
]=]

function FlareClient.loadClient(): FrameworkType?
	if FlareClient.__gameIsLoaded or not RunService:IsClient() then return; end;
	
	local self = setmetatable(FlareClient, {} :: FrameworkType);

	self.CachedModules = {};
	self.GameSignals = {};
	self.GameVariables = {
		LocalPlayer = Players.LocalPlayer,
		Character = nil,
		Humanoid = nil,
		Camera = Workspace.CurrentCamera
	};

	self.LocalClientStorage = script:WaitForChild("LocalClientStorage");
	
	do
		debug.profilebegin("Flare-Engine Bootstrap");
		local LoadingStartTick = tick();

		--// Caching modules into a table
		self:_ObserveAndCacheDirectory(ModuleFolder);
		self:_ObserveAndCacheDirectory(script:WaitForChild("Utilities"));
		self:_ObserveAndCacheDirectory(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utilities"));
		
		--// Loading modules
		self:_PreloadModuleDirectory(PlayerModules);

		if self.GameVariables.LocalPlayer.Character then
			self.GameVariables.Character = self.GameVariables.LocalPlayer.Character;
			self.GameVariables.Humanoid = self.GameVariables.Character:WaitForChild("Humanoid");

			coroutine.wrap(function()
				self:_PreloadModuleDirectory(CharacterModules);
			end)();
		end;

		self._runtimeMaid = require(self.CachedModules["Maid"]).new();
		self._runtimeMaid:GiveTask(self.GameVariables.LocalPlayer.CharacterAdded:Connect(function(Character)
			self.GameVariables.Character = Character;
			self.GameVariables.Humanoid = Character:WaitForChild("Humanoid");
			
			coroutine.wrap(function()
				self:_PreloadModuleDirectory(CharacterModules);
			end)();
		end));

		--// Finalizing
		local NewActor = Instance.new("Actor");
		script.Parent = NewActor;
		NewActor.Parent = nil;
		--// script.Parent = nil;

		FlareClient.__gameIsLoaded = true;
		local LoadingFinishTick = tick();
		debug.profileend();
		print("[Client]: Framework initialization took: " .. LoadingFinishTick - LoadingStartTick .. "s");
	end;
end;

--[=[
	Framework variable storing every single cached module.

	@prop CachedModules {}
	@within FlareClient
]=]

--[=[
	Framework variable storing framework signals.

	@prop GameSignals {}
	@within FlareClient
]=]

--[=[
	Framework a table containing client changing variables.

	@prop GameVariables { LocalPlayer: Player, Character: Model?, Humanoid: Humanoid?, Camera: Camera };
	@within FlareClient
]=]

--[=[
	Local client storage. Mainly used to store Guis.

	@prop LocalClientStorage Instance;
	@within FlareClient
]=]

--// [ Modules: ]

--// [ External: ]

--[=[
	Returns if the client has loaded.

	@return boolean
]=]

function FlareClient.gameIsLoaded(): boolean
	return FlareClient.__gameIsLoaded;
end;

--// [ Script Runtime: ]

--[=[
	Returns a function to require utilities and modules within framework.

	```lua
	local Framework = require(script.Parent.Parent:WaitForChild("Framework")); --// Script must be a descendant of your framework module

	local require = Framework:GetModulesFromCache();

	local Maid = require("Maid");
	local newMaid = Maid.new(); --> Maid

	local Spring = require("Spring");
	local newSpring = Spring.new(); --> Spring
	```

	@return RequireType
]=]

function FlareClient:GetModulesFromCache(): Types.RequireType
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
function FlareClient:_ObserveAndCacheDirectory(Directory: Instance): ()
	for _, Module: Instance in ipairs(Directory:GetDescendants()) do
		coroutine.wrap(function()
			if Module:IsA("ModuleScript") then
				self.CachedModules[Module.Name] = Module;
			end;
		end)();
	end;
end;

function FlareClient:_PreloadModuleDirectory(Directory: Instance): ()
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
			
			if not success then
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

return FlareClient :: FrameworkType;