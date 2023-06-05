-- Retro Gadgets
local base64 = require("base64.lua")
local vc:VideoChip = gdt.VideoChip0
local cpu:CPU = gdt.CPU0
local wifi:Wifi = gdt.Wifi0
local button:LedButton = gdt.LedButton0

local font = gdt.ROM.System.SpriteSheets.StandardFont
local videoData = nil
local videoData = ""
local data = nil
local currentFrame = 0
local timeBetweenFrames = 0
local timePassed = 0
local fpsTimePassed = 0
local fpsFrames = 0

function decodeVideo()
	local data = {}
	data.signature = videoData:sub(1, 7)
	data.width = string.unpack("I", string.sub(videoData, 8, 11))
	data.frameAmount = string.unpack("I", string.sub(videoData, 12, 15))
	data.framerate = string.unpack("B", string.sub(videoData, 16, 17))
	timeBetweenFrames = 1 / data.framerate
	local paletteStartIndex = 17
	data.palette = {}
	
	for i = paletteStartIndex, paletteStartIndex + 256 * 3, 3 do
		local r = videoData:byte(i, i)
		local g = videoData:byte(i + 1, i + 1)
		local b = videoData:byte(i + 2, i + 2)
		table.insert(data.palette, Color(r, g, b))
	end

	data.frames = {}
	local frameSize = data.width * vc.Height
	local vdStartIndex = videoData:find("VIDEODATA")
	
	for frame=0, data.frameAmount - 1 do
		local frameIndex = vdStartIndex + frameSize * frame
		local frameData = {}
		for i=1, frameSize do
			table.insert(frameData, videoData:sub(frameIndex + i, frameIndex + i):byte(1,1))
		end
		table.insert(data.frames, frameData)
	end
	
	return data
end

function drawFrame(frame)
	local pd = PixelData.new(vc.Width, vc.Height, color.clear)
	local frameData = data.frames[frame]
	local widthDifference = vc.Width - data.width
	local x = -1
	local y = 0
	for i=1, #frameData do
		x += 1
		if (i - 8) % data.width == 0 then
			x = math.floor(widthDifference / 2)
			y += 1
		end
		if data.palette[frameData[i] + 1] ~= nil then
			-- vc:SetPixel(vec2(x,y), data.palette[frameData[i] + 1]) -- uncomment this line if you want 3 fps
			pd:SetPixel(x, y, data.palette[frameData[i] + 1])
		else
			desk.ShowWarning("error while setting pixel", false)
		end
	end
	vc:SetPixelData(pd)
end

wifi:WebGet("http://localhost:8080")

function update()
	if button.ButtonDown then
		wifi:WebGet("http://localhost:8080")
	end
	
	if data ~= nil then
		timePassed += cpu.DeltaTime
		if timePassed >= timeBetweenFrames then
			fpsTimePassed += cpu.DeltaTime
			fpsFrames += 1
			currentFrame = if currentFrame < data.frameAmount then currentFrame + 1 else 1
			timePassed -= timeBetweenFrames
			drawFrame(currentFrame)
		end
		if fpsTimePassed >= 1 then
			fpsTimePassed -= 1
			fpsFrames = 0
		end
		if gdt.Switch0.State then
			vc:DrawText(vec2(0,0), font, tostring(math.floor(fpsFrames / fpsTimePassed)), color.green, color.black)
		end
	end
end

function eventChannel1(sender:Wifi, arg:WifiWebResponseEvent)
	if arg.ResponseCode == 200 and arg.ContentType == "video/rgv" then
		videoData = base64.decode(arg.Text)
		data = decodeVideo()
	else
		print(arg.ResponseCode)
		print(arg.ErrorMessage)
	end
end