-- Retro Gadgets
local json = require("json.lua")

local cpu = gdt.CPU0
local wifi = gdt.Wifi0
local flash = gdt.FlashMemory0

-- Bottom to top
local minute1 = {
	gdt.Led2,
	gdt.Led3,
	gdt.Led5,
	gdt.Led6
}

local minute10 = {
	gdt.Led0,
	gdt.Led1,
	gdt.Led4,
}

local hour1 = {
	gdt.Led7,
	gdt.Led10,
	gdt.Led11,
	gdt.Led12,
}

local hour10 = {
	gdt.Led8,
	gdt.Led9
}

local time = {
  year = 0,
	month = 0,
  day = 0,
  hour = 0,
  minute = 0,
  seconds = 61,
  milliseconds = 0,
  datetime = "",
  date = "",
  time = "",
  time_zone = "",
  dayOfWeek = "",
  dstActive = false
} -- Template so that you can easily access the values from the IDE

local ip = nil -- needed for correct date and time
local starttime = 1

local flashData = flash:Load() -- load cached info
if flashData["ip"] ~= nil then
	ip = flashData["ip"]
	time = flashData["time"]
	time.seconds = 61
end

function GetTime()
	if wifi.AccessDenied == true then
		desk.ShowError("No wifi", false)
	end
	if ip == nil then
		wifi:WebGet("https://api.ipify.org?format=json")
	end
	if ip ~= nil and time.seconds + cpu.Time - starttime > 60 then
		wifi:WebGet("https://timeapi.io/api/Time/current/ip?ipAddress="..ip)
		starttime = cpu.Time
	end
end

-- update function is repeated every time tick
function update()
	GetTime()
	-- Update minutes
	for i, led in ipairs(minute1) do
		led.State = getBinaryState(time.minute % 10, i)
	end

	for i, led in ipairs(minute10) do
		led.State = getBinaryState(math.floor(time.minute / 10), i)
	end

	-- Update hours
	for i, led in ipairs(hour1) do
		led.State = getBinaryState(time.hour % 10, i)
	end

	for i, led in ipairs(hour10) do
		led.State = getBinaryState(math.floor(time.hour / 10), i)
	end
end

function getBinaryState(digit, position)
	local binaryDigit = bit32.band(bit32.rshift(digit, position - 1), 1)
	return binaryDigit == 1
end

function eventChannel1(sender, arg : WifiWebResponseEvent)
	if arg.ResponseCode == 200 then
		data = json.decode(arg.Text)
		
		if data["time"] then 
			time = data
			-- Cache for faster startup time
			local flashData = flash:Load()
			flashData["time"] = data
			flash:Save(flashData)
		end
		
		if data["ip"] then 
			ip = data["ip"]
			-- Cache for faster startup time
			local flashData = flash:Load()
			flashData["ip"] = data["ip"]
			flash:Save(flashData)
		end
	else
		desk.ShowError("Error while receiving request: " .. tostring(arg.ResponseCode), false)
	end
end