local Framework = require(script.Parent.Parent.Parent);

local MovementHandler = {}
MovementHandler.__index = MovementHandler;

--// [ Variables: ]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

--// Utilities
local require = Framework:GetModulesFromCache();
local Maid = require("Maid");

--// Directories
local Animations = ReplicatedStorage.Animations; -- Directory
local FootstepSounds = nil; -- Directory

--// Configuration
local Config = {
	["JUMP_COOLDOWN"] = 1.1,

	["WALK_SPEED"] = 11,
	["SPRINT_SPEED"] = 23,
	["CROUCH_SPEED"] = 6,

	["SPRINT_ANIMATION"] = Animations.Sprint,
	["CROUCHING_ANIMATION"] = Animations.Crouch,
	["LANDED_ANIMATION"] = Animations.Land
}

local States = {
	["Idle"] = {
		["Sprinting"] = "Sprinting", 
		["Crouching"] = "Crouching"
	},

	["Sprinting"] = {
		["Idle"] = "Idle", 
		["Crouching"] = "Crouching"
	},

	["Crouching"] = {
		["Idle"] = "Idle", 
		["Sprinting"] = "Sprinting"
	}
}

--// [ Constructor: ]
function MovementHandler.Init(): {}
	local self = setmetatable({}, MovementHandler);

	local KeybindManager = require("KeybindManager");
	local FieldOfViewManager = require("FieldOfViewManager");

	--// Variables
	self.CurrentState = "Idle"
	self.LastJump = time();
	self.Animations = {
		["SPRINTING"] = Framework.GameVariables.Humanoid:LoadAnimation(Config.SPRINT_ANIMATION),
		["CROUCHING"] = Framework.GameVariables.Humanoid:LoadAnimation(Config.CROUCHING_ANIMATION),
		["LANDED"] = Framework.GameVariables.Humanoid:LoadAnimation(Config.LANDED_ANIMATION)
	}
	
	for _, Animation in pairs(self.Animations) do
		Animation.Priority = Enum.AnimationPriority.Idle;
	end;

	self.Animations.LANDED.Priority = Enum.AnimationPriority.Movement;
	
	--// Setup
	self._runtimeMaid = Maid.new();
	Framework.GameVariables.Humanoid.WalkSpeed = Config.WALK_SPEED;

	for State, _ in pairs(States) do
		Framework.GameVariables.Humanoid:SetAttribute(State, false);
	end;

	Framework.GameVariables.Humanoid:SetAttribute(self.CurrentState, true);
	
	--// Footstep sounds
	--[[MovementHandler._runtimeMaid:GiveTask(self.GameVariables.Humanoid.AnimationPlayed:Connect(function(PlayedTrack)
		if PlayedTrack.Name ~= "WalkAnim" then return; end;
		PlayedTrack:GetMarkerReachedSignal("FOOTSTEP"):Connect(function()
			if CurrentState == "Idle" then
				self:PlayFootstepSound();
			end;
		end);
	end));

	for _, Animation in pairs(Animations) do
		MovementHandler._runtimeMaid:GiveTask(Animation:GetMarkerReachedSignal("FOOTSTEP"):Connect(function()
			self:PlayFootstepSound();
		end));
	end;]]

	--// Binds
	KeybindManager:BindKey("Sprint", function()
		self:SetState("Sprinting");
	end, function()
		if self.CurrentState == "Sprinting" then
			self:SetState("Idle");
		end;
	end);
	
	KeybindManager:BindKey("Crouch", function()
		if Framework.GameVariables.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			self:SetState("Crouching");
		end;
	end, function()
		if self.CurrentState == "Crouching" then
			self:SetState("Idle");
		end;
	end);

	--// State connections
	self._runtimeMaid:GiveTask(Framework.GameVariables.Humanoid:GetAttributeChangedSignal("Sprinting"):Connect(function()
		local NewValue = Framework.GameVariables.Humanoid:GetAttribute("Sprinting");

		if NewValue then
			TweenService:Create(Framework.GameVariables.Humanoid, TweenInfo.new(0.35), {WalkSpeed = Config.SPRINT_SPEED}):Play();
		else
			TweenService:Create(Framework.GameVariables.Humanoid, TweenInfo.new(0.2), {WalkSpeed = Config.WALK_SPEED}):Play();

			if self.Animations.SPRINTING.IsPlaying then
				self.Animations.SPRINTING:Stop(0.2);
			end;

			FieldOfViewManager:SetFOV("MovementFOV", 0, 0.4);
		end;
	end));

	--// Crouching
	self._runtimeMaid:GiveTask(Framework.GameVariables.Humanoid:GetAttributeChangedSignal("Crouching"):Connect(function()
		local NewValue = Framework.GameVariables.Humanoid:GetAttribute("Crouching");

		if NewValue == true then
			self.Animations.CROUCHING:Play(0.2);
			TweenService:Create(Framework.GameVariables.Humanoid, TweenInfo.new(0.2), {WalkSpeed = Config.CROUCH_SPEED}):Play();
			TweenService:Create(Framework.GameVariables.Humanoid, TweenInfo.new(0.2), {HipHeight = -1}):Play();
			Framework.GameVariables.Humanoid.JumpPower = 0;
			FieldOfViewManager:SetFOV("MovementFOV", -5, 0.6);
		else
			self.Animations.CROUCHING:Stop(0.2);
			TweenService:Create(Framework.GameVariables.Humanoid, TweenInfo.new(0.2), {WalkSpeed = Config.WALK_SPEED}):Play();
			TweenService:Create(Framework.GameVariables.Humanoid, TweenInfo.new(0.2), {HipHeight = 0}):Play();
			Framework.GameVariables.Humanoid.JumpPower = 48;
			FieldOfViewManager:SetFOV("MovementFOV", 0, 0.7);
		end;
	end));

	--// Sprinting
	self._runtimeMaid:GiveTask(Framework.GameVariables.Humanoid.Running:Connect(function(Speed)
		if Speed >= 10 and self.CurrentState == "Sprinting" and not self.Animations.SPRINTING.IsPlaying then
			self.Animations.SPRINTING:Play(0.35);
			FieldOfViewManager:SetFOV("MovementFOV", 10, 0.5);
		elseif Speed >= 10 and self.CurrentState ~= "Sprinting" and self.Animations.SPRINTING.IsPlaying then
			self.Animations.SPRINTING:Stop(0.2);
			FieldOfViewManager:SetFOV("MovementFOV", 0, 0.6);
		elseif Speed < 10 and self.Animations.SPRINTING.IsPlaying then
			self.Animations.SPRINTING:Stop(0.2);
			FieldOfViewManager:SetFOV("MovementFOV", 0, 0.6);
		end;
	end));

	--// Other connections
	self._runtimeMaid:GiveTask(Framework.GameVariables.Humanoid.StateChanged:Connect(function(OldState, NewState)
		if NewState == Enum.HumanoidStateType.Freefall and self.Animations.SPRINTING.IsPlaying then
			self.Animations.SPRINTING:Stop(0.2);
		end;

		if self.CurrentState == "Crouching" then
			if NewState == Enum.HumanoidStateType.Swimming or 
				NewState == Enum.HumanoidStateType.Freefall or
				NewState == Enum.HumanoidStateType.Seated or 
				NewState == Enum.HumanoidStateType.Climbing then
				self:SetState("Idle");
			end;
		end;
	end));

	--// Jump cooldown
	self._runtimeMaid:GiveTask(Framework.GameVariables.Humanoid.Changed:connect(function(Property)
		if Property and Property == "Jump" and Framework.GameVariables.Humanoid.Jump then
			local CurrentTime = time();

			if self.LastJump + Config.JUMP_COOLDOWN > CurrentTime then
				Framework.GameVariables.Humanoid.Jump = false;
			else
				FieldOfViewManager:ImpulseFOV(2, 0.1);
				self.LastJump = CurrentTime;
			end;
		end;
	end));

	--// Crouching animation speed
	self._runtimeMaid:GiveTask(RunService.RenderStepped:Connect(function()
		if Framework.GameVariables.Humanoid and (self.Animations.CROUCHING and self.Animations.CROUCHING.IsPlaying) then
			if Framework.GameVariables.Humanoid.MoveDirection.Magnitude == 0 then
				self.Animations.CROUCHING:AdjustSpeed(0);
			else
				self.Animations.CROUCHING:AdjustSpeed(1);
			end;
		end;
	end));

	--// Landed
	self._runtimeMaid:GiveTask(Framework.GameVariables.Humanoid.StateChanged:Connect(function(OldState, NewState)
		if OldState == Enum.HumanoidStateType.Freefall and NewState == Enum.HumanoidStateType.Landed and Framework.GameVariables.Character:FindFirstChild("HumanoidRootPart").Velocity.Y < -45 then
			--FootstepSounds:WaitForChild("Landed"):Play();
		end;
	end));
	
	--// Cleanup
	self._runtimeMaid:GiveTask(Framework.GameVariables.Humanoid.Died:Connect(function()
		KeybindManager:UnbindKey("Sprint");
		KeybindManager:UnbindKey("Crouch");
		
		self._runtimeMaid:DoCleaning();
		setmetatable(self, nil);
	end));
	
	return self;
end;

--// [ Functions: ]
function MovementHandler:GetCurrentState()
	return self.CurrentState;
end;

function MovementHandler:SetState(State)
	local StateData = States[self.CurrentState];

	if StateData[State] then
		Framework.GameVariables.Humanoid:SetAttribute(self.CurrentState, false);
		Framework.GameVariables.Humanoid:SetAttribute(State, true);
		self.CurrentState = StateData[State];
	end;
end;

function MovementHandler:PlayFootstepSound()
	local FloorMaterial = Framework.GameVariables.Humanoid.FloorMaterial;
	if not FloorMaterial then 
		FloorMaterial = "Air"; 
	end;
	
	local Material = string.split(tostring(FloorMaterial), "Enum.Material.")[2];

	local MaterialSounds = FootstepSounds:FindFirstChild(Material)
	if MaterialSounds then
		MaterialSounds = MaterialSounds:GetChildren();
	else
		MaterialSounds = FootstepSounds:FindFirstChild("Concrete"):GetChildren();
	end;

	MaterialSounds[math.random(1, #MaterialSounds)]:Play();
end;

return MovementHandler
