local StarterGui = game:GetService("StarterGui")

local success = false
while not success do
	success = pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Bluu",
			Text = "this script is currently not available.",
			Duration = 5
		})
	end)
	task.wait(0.1)
end
