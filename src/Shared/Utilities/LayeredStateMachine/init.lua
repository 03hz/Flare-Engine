--// [ Types: ]

export type LayerData = {
	LayerName: string,
	Initial: string,
	States: {
		Default: {
			OnEntry: (any),
			OnExit: (any),
			UpdateLogic: (any)
		}
	}
	
}

export type NewLayer = {
	CurrentState: string,
	SetState: (State: any) -> string,
	Changed: RBXScriptSignal
}

export type NewGroup = {
	CreateLayer: (LayerData: LayerData) -> NewLayer,
	GetLayer: (Name: string) -> NewLayer
}

--// [ Flare-Engine: ]
local ServerScriptService = game:GetService("ServerScriptService");
local Framework = require(ServerScriptService:WaitForChild("src"):WaitForChild("Framework"));

local require = Framework:GetModulesFromCache();
local Signal = require("Signal");

--[=[
	A powerful state machine with layers.
	More about state machines: https://en.wikipedia.org/wiki/Finite-state_machine

	@class LayeredStateMachine
]=]

local LayeredStateMachine = {}
LayeredStateMachine.ClassName = "LayeredStateMachine"
LayeredStateMachine.CurrentGroups = {};

--// Services
local RunService = game:GetService("RunService");

--[=[
	Creates a new state machine group used for layers.
	
	@param Name string
	@within LayeredStateMachine
	@return NewGroup
]=]
function LayeredStateMachine:CreateGroup(Name: string): NewGroup
	local NewGroup = LayeredStateMachine.CurrentGroups[Name];
	NewGroup = {};
	NewGroup.Layers = {};

	function NewGroup:GetLayer(LayerName: string): NewLayer
		return NewGroup[LayerName] :: NewLayer;
	end;	
	
	function NewGroup:CreateLayer(LayerData: LayerData): NewLayer
		local NewLayer: NewLayer = NewGroup.Layers[LayerData.LayerName];
		NewLayer = {};
		NewLayer.States = {};
		setmetatable(NewLayer, NewGroup);

		for StateName, State in pairs(LayerData.States) do
			NewLayer.States[StateName] = State;
		end;

		--// Variables
		NewLayer.CurrentState = LayerData.Initial;
		NewLayer.CurrentUpdateLogicConnection = nil;
		NewLayer.Changed = Signal.new();
		
		--// Methods
		function NewLayer:SetState(State: string): string
			local OldState = NewLayer.States[NewLayer.CurrentState];
			local NewState = NewLayer.States[State];
					
			OldState.OnExit();
			if NewLayer.CurrentUpdateLogicConnection then
				NewLayer.CurrentUpdateLogicConnection:Disconnect();
			end;

			NewState.OnEntry();
			if type(NewState["UpdateLogic"]) == "function" then
				NewLayer.CurrentUpdateLogicConnection = RunService.RenderStepped:Connect(function()
					NewState.UpdateLogic();
				end);
			end;

			NewLayer.CurrentState = State;

			NewLayer.Changed:Fire(OldState, NewState);
		end;
		
		return NewLayer;
	end;

	function NewGroup:SetStates(States: {string})
		for Layer: string, State: string in pairs(States) do
			local FoundLayer: NewLayer = NewGroup.Layers[Layer];
			if FoundLayer then
				FoundLayer:SetState(State);
			end;
		end;
	end;

	return NewGroup;
end;

--[=[
	Gets a state machine group used for layers.

	```lua
	local Group = LayeredStateMachine:GetGroup("Name")
	```
	
	@param Name string
	@return NewGroup
]=]

function LayeredStateMachine:GetGroup(Name: string): NewGroup
	if LayeredStateMachine.CurrentGroups[Name] ~= nil then
		return LayeredStateMachine.CurrentGroups[Name];
	end;
end;

return LayeredStateMachine
