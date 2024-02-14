local Framework = require(script.Parent.Parent.Parent.Parent);

local NotificationManager = {};
NotificationManager.__index = NotificationManager;

--// Sevices
local Workspace = game:GetService("Workspace");
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");

--// Instances
local LocalPlayer = Players.LocalPlayer;
local NotificationSounds = ReplicatedStorage.Shared.Sounds:WaitForChild("NotificationPanel");

--// Configuration
local NotificationTypes = {
	Message = {
		TemplateName = "MessageNotification",
		SoundName = "MessageNotification"
	},
	
	Request = {
		TemplateName = "RequestNotification",
		SoundName = "RequestNotification"
	}
};

function NotificationManager.Init()
	local self = setmetatable({}, NotificationManager);
	
	self.CurrentNotifications = {};
	self.NotificationUI = Framework.LocalClientStorage.NotificationPanel;
	self.NotificationUI.Parent = LocalPlayer.PlayerGui;
	
	self.NotificationUIComponents = {};
	for _, Component in pairs(self.NotificationUI:GetDescendants()) do
		self.NotificationUIComponents[Component.Name] = Component;
	end;
	
	return self;
end;

function NotificationManager:SendNotification(Type: string, Params: {})
	local NotificationData = NotificationTypes[Type];
	
	if NotificationData then
		local NewNotification = {};
		
		local NotificationFrame = self.NotificationUIComponents.NotificationTemplates:FindFirstChild(NotificationData.TemplateName):Clone();
		local NotificationUIBlur = require(NotificationFrame.UIBlur);
		
		NotificationFrame.Parent = self.NotificationUIComponents.NotificationsListFrame;
		NotificationFrame.NotificationText.Text = Params.Text;
		
		NotificationUIBlur:StartBlur();
		
		task.spawn(function()
			local NewSound = NotificationSounds[NotificationData.SoundName]:Clone();
			NewSound.Parent = Workspace.Sounds.Temp;
			NewSound:Play();
			NewSound.Ended:Wait();
			NewSound:Destroy();
		end);
		
		task.spawn(function()
			task.wait(0.1);
			TweenService:Create(NotificationFrame.TransitionFX, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.new(1, 0, 0, 0) }):Play();
			task.wait(0.2);
			TweenService:Create(NotificationFrame.TransitionFX2, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.new(1, 0, 0, 0) }):Play();
			
			TweenService:Create(NotificationFrame.TimeLeft, TweenInfo.new(Params.LifeTime or 2, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0.041, 0) }):Play();
			
			task.spawn(function()
				task.wait(0.25)
				NotificationFrame.NotificationText.Visible = false;
				task.wait(0.04);
				NotificationFrame.NotificationText.Visible = true;
				task.wait(0.07);
				NotificationFrame.NotificationText.Visible = false;
				task.wait(0.07);
				NotificationFrame.NotificationText.Visible = true;
			end);
			
			task.delay(Params.LifeTime or 2, function()
				if NotificationFrame then
					NewNotification.Destroy();
				end;
			end);
		end);

		NewNotification.Destroy = function()
			NotificationUIBlur:StopBlur();
			NotificationFrame:Destroy();
		end;
		
		table.insert(self.CurrentNotifications, NewNotification);
	end;
end;

function NotificationManager:ClearNotifications()
	for _, Notification in pairs(self.CurrentNotifications) do
		Notification.Destroy();
	end;
end;

return NotificationManager;
