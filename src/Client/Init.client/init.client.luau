local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;

script.Parent = LocalPlayer.PlayerScripts;
local ClientFramework = require(script:WaitForChild("Framework"));
ClientFramework.loadClient();