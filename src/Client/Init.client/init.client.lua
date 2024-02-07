local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;

script.Parent = LocalPlayer.PlayerScripts;
local Framework = require(script:WaitForChild("Framework")).loadClient();