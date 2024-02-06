--// [ Types: ]

export type LayerData = {
	LayerName: string,
	Initial: string,
	States: {
		Default: {
			OnEntry: (any),
			OnExit: (any),
			Events: {},
			IgnoreEvents: {}?
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

--[=[
	Creates a new state machine group used for layers.
	
	@param Name string
	@within LayeredStateMachine
	@return NewGroup
]=]
function LayeredStateMachine:CreateGroup(Name: string): NewGroup
	local NewGroup = LayeredStateMachine.CurrentGroups[Name];
	NewGroup = {};
	NewGroup.ActiveStates = {};

	function NewGroup:GetLayer(Name: string): NewLayer
		return NewGroup[Name] :: NewLayer;
	end;	

	function NewGroup:CreateLayer(LayerData: LayerData): NewLayer
		local NewLayer: NewLayer = NewGroup[LayerData.LayerName];
		NewLayer = {};
		setmetatable(NewLayer, NewGroup);

		for Name, State in pairs(LayerData.States) do
			NewGroup.ActiveStates[Name] = State;
		end;

		--// Variables
		NewLayer.CurrentState = LayerData.Initial;
		NewLayer.Changed = Signal.new();
		
		--// Methods
		function NewLayer:SetState(State: string): string
			local OldStateName = NewLayer.CurrentState;
			local OldState = NewGroup.ActiveStates[OldStateName];

			if OldState.Events[State] then
				local FoundState = OldState.Events[State];
				local NewState = NewGroup.ActiveStates[FoundState]
				
				OldState.OnExit();
				NewState.OnEntry();
				NewLayer.CurrentState = FoundState;

				NewLayer.Changed:Fire(OldStateName, FoundState);
			end;
		end;
		
		return NewLayer;
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
