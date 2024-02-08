local Framework = require(script.Parent.Parent);

local FieldOfViewManager = {}
FieldOfViewManager.__index = FieldOfViewManager;

--// [ Locals: ]

--// Services
local Workspace = game:GetService("Workspace");
local TweenService = game:GetService("TweenService");

--// Instances
local Camera = Workspace.CurrentCamera;

--// [ Constructor: ]
function FieldOfViewManager.Init(): {}
	local self = setmetatable({}, FieldOfViewManager);

	self.FOVTable = {
		BaseFOV = 70,
		ImpulsedFOV = 0
	};

	return self;
end;

function FieldOfViewManager:_UpdateFOV(Speed: number)
	local FinalFOV = 0;
	for _, FOVAmount in pairs(self.FOVTable) do
		FinalFOV += FOVAmount;
	end;
	
	TweenService:Create(Camera, 
		TweenInfo.new(Speed), 
		{ FieldOfView = FinalFOV }):Play();
end;

--// [ Functions: ]
function FieldOfViewManager:SetFOV(IndexName: string, Amount: number, Speed: number)
	self.FOVTable[IndexName] = Amount;
	self:_UpdateFOV(Speed);
end;

function FieldOfViewManager:ImpulseFOV(Amount: number, Time: number)
	self.FOVTable.ImpulsedFOV += Amount;
	self:_UpdateFOV(0.15);
	
	task.delay(Time, function()
		self.FOVTable.ImpulsedFOV -= Amount;
		self:_UpdateFOV(0.25);
	end);
end;

return FieldOfViewManager