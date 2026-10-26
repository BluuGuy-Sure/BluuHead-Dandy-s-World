local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local lp = Players.LocalPlayer
local Target = 6131807720

if lp.UserId == Target then
	StarterGui:SetCore("SendNotification", {
		Title = "Bluu",
		Text = "You're Banned. (Test for you; Spooky bacon.)",
		Duration = 10,
	})
else
  StarterGui:SetCore("SendNotification", {
      Title = "Bluu",
      Text = "Script is Unavailable."
      Duration = 10,
    })
end
