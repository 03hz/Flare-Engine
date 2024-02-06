task.wait(1)

local lsm = require(script.Parent)
local newg = lsm:CreateGroup("a")
local newl = newg:CreateLayer({
	LayerName = "test",
	Initial = "Idle",
	States = {
		Idle = {
			OnEntry = function()
				print("idle entered")
			end,
			
			OnExit = function()
				print("idle exited")
			end,
			
			Events = {
				Running = "Running"
			}
		},
		
		Running = {
			OnEntry = function()
				print("run entered")
			end,

			OnExit = function()
				print("run exited")
			end,

			Events = {
				Idle = "Idle"
			}
		}
	}
})

local newl2 = newg:CreateLayer({
	LayerName = "test2",
	Initial = "NoAction",
	States = {
		NoAction = {
			OnEntry = function()
				print("noaction entered")
			end,

			OnExit = function()
				print("noaction exited")
			end,

			Events = {
				Dashing = "Dashing"
			}
		},

		Dashing = {
			OnEntry = function()
				print("dashing entered")
			end,

			OnExit = function()
				print("dashing exited")
			end,

			Events = {
				Idle = "Default"
			}
		}
	}
})

newl.Changed:Connect(function(old, new)
	print("old event: ", old, ", new event: ", new)
end)


newl:SetState("Running")

wait(1)

newl:SetState("Idle")
wait(1)
newl:SetState("Running")

wait(1)
newl2:SetState("Dashing")