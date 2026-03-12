local RunService = game:GetService("RunService")
local Framebuffer = require(
	game:GetService("ReplicatedStorage")
		:WaitForChild("Shared"):WaitForChild("GPU"):WaitForChild("Framebuffer")
)

Framebuffer.Initialize()

RunService.PreRender:Connect(function()
	if not Framebuffer.Dirty then return end
	Framebuffer.Scan()
end)

return 1