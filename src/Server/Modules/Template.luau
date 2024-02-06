local ServerScriptService = game:GetService("ServerScriptService");
local Framework = require(ServerScriptService:WaitForChild("src"):WaitForChild("Framework"));

local Template = {}
Template.__index = Template;

function Template.Init(): self
	--// Optional
	--// Utilities, connections
	local self = setmetatable({}, Template);

	--// Script
	
	return self;
end;

function Template:Start() 
	--// Optional
	--// Runtime modules, other connections
	
	--// Script
	
end;

return Template
