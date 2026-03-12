--!native
--!optimize 2
local Framebuffer = {}
local AssetService = game:GetService("AssetService")
local Player = game:GetService("Players").LocalPlayer

Framebuffer.WIDTH = 1024
Framebuffer.HEIGHT = 768
Framebuffer.Dirty = false
local EditableImage = AssetService:CreateEditableImage({Size = Vector2.new(Framebuffer.WIDTH, Framebuffer.HEIGHT)})
local Memory = require("../Memory/Memory")

function Framebuffer.Initialize()
    local DisplayLabel: ImageLabel = Player.PlayerGui:WaitForChild("DisplayGUI"):WaitForChild("DisplayLabel")
    DisplayLabel.ImageContent = Content.fromObject(EditableImage) -- Now .ImageContent is reference to EditableImage
	DisplayLabel.Visible = true
end

function Framebuffer.Scan()
    if Memory.FramebufferAddress == 0 then return end   -- Invalid framebuffer address

	local region = buffer.create(Framebuffer.WIDTH * Framebuffer.HEIGHT * 4)
	buffer.copy(region, 0, Memory.Memory, Memory.FramebufferAddress, Framebuffer.WIDTH * Framebuffer.HEIGHT * 4)

	EditableImage:WritePixelsBuffer(Vector2.zero, Vector2.new(Framebuffer.WIDTH, Framebuffer.HEIGHT), region)
end

return Framebuffer