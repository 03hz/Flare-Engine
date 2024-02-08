local Framework = require(script.Parent.Parent);

local KeybindManager = {}
KeybindManager.__index = KeybindManager;

--// [ Locals: ]

--// Services
local UserInputService = game:GetService("UserInputService");

--// Requires
local require = Framework:GetModulesFromCache();
local Maid = require("Maid");

--// Configuration
local Keybinds = require(script:WaitForChild("Keybinds"));

--// [ Constructor: ]
function KeybindManager.Init(): {}
	local self = setmetatable({}, KeybindManager);

	self._runtimeMaid = Maid.new();
	
	self.BoundKeys = {};
	for Key, _ in pairs(Keybinds) do
		self.BoundKeys[Key] = {};
	end;
	
	self._runtimeMaid:GiveTask(UserInputService.InputBegan:Connect(function(Input, gpe)
		if gpe then return; end;
		local BoundKeyData = self.BoundKeys[Input.KeyCode];
		if BoundKeyData ~= nil then
			BoundKeyData.OnActivated();
		end
	end));
	
	self._runtimeMaid:GiveTask(UserInputService.InputEnded:Connect(function(Input, gpe)
		if gpe then return; end;
		local BoundKeyData = self.BoundKeys[Input.KeyCode];
		if BoundKeyData ~= nil then
			BoundKeyData.OnEnded();
		end
	end));

	return self;
end;

--// [ Functions: ]
function KeybindManager:BindKey(Bind: string, OnActivated: any?, OnEnded: any?)
	if not Keybinds[Bind] then return; end;
	
	local Keybind = Keybinds[Bind].BindKey;
	self.BoundKeys[Keybind] = {};
	local BoundKeyData = self.BoundKeys[Keybind];
	
	BoundKeyData["OnActivated"] = OnActivated;
	BoundKeyData["OnEnded"] = OnEnded;
end;

function KeybindManager:UnbindKey(Bind: string)
	if not Keybinds[Bind] then return; end;
	
	local Keybind = Keybinds[Bind].BindKey;
	self.BoundKeys[Keybind] = nil;
end;

return KeybindManager