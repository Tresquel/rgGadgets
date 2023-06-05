--power
local PowerBut = gdt.LedButton2
--color buttons
local ColorButtons = {}

ColorButtons.Red = gdt.LedButton4
ColorButtons.Green = gdt.LedButton5
ColorButtons.Blue = gdt.LedButton7
ColorButtons.White = gdt.LedButton6
ColorButtons.Orange = gdt.LedButton9
ColorButtons.LightGreen = gdt.LedButton10
ColorButtons.Cyan = gdt.LedButton8
ColorButtons.Grey = gdt.LedButton11
ColorButtons.Pink = gdt.LedButton3
ColorButtons.DarkGreen = gdt.LedButton16
ColorButtons.LightBlue = gdt.LedButton18
ColorButtons.DarkGrey = gdt.LedButton17

local diy1 = gdt.LedButton12
--sliders
local RSlider = gdt.Slider2
local GSlider = gdt.Slider1
local BSlider = gdt.Slider0
--colors
local Colors = {}

Colors.Red = Color(255, 0, 0)
Colors.Green = Color(0, 255, 0)
Colors.Blue = Color(0, 0, 255)
Colors.White = Color(255, 255, 255)
Colors.Orange = Color(255, 144, 0)
Colors.LightGreen = Color(130, 255, 130)
Colors.Cyan = Color(0, 205, 255)
Colors.Grey = Color(128, 128, 128)
Colors.Pink = Color(255, 0, 255)
Colors.DarkGreen = Color(100, 165, 45)
Colors.LightBlue = Color(120, 220, 255)
Colors.DarkGrey = Color(50, 50, 50)

local DIYMode = false

-- update function is repeated every time tick
function update()
	if PowerBut.ButtonUp then
		desk.SetLampState(not desk.GetLampState())
	end
	for k, v in pairs(ColorButtons) do
		if v.ButtonUp then
			DIYMode = false
			desk.SetLampColor(Colors[k])
		end
	end
	if diy1.ButtonUp then DIYMode = true end
	if DIYMode then
		R = math.round(RSlider.Value * 2.55)
		G = math.round(GSlider.Value * 2.55)
		B = math.round(BSlider.Value * 2.55)
		col = Color(R, G, B)
		desk.SetLampColor(col)
	end
end