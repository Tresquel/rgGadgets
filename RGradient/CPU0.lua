-- Made by stachu
local vcmain = gdt.VideoChip0 -- Main screen
local vccol1 = gdt.VideoChip1 -- Color preview 1
local vccol2 = gdt.VideoChip2 -- Color preview 2
local weightKnob = gdt.Knob0 -- How much of one color is on the gradient
local r1Slider = gdt.Slider0
local g1Slider = gdt.Slider1
local b1Slider = gdt.Slider2

local r2Slider = gdt.Slider3
local g2Slider = gdt.Slider4
local b2Slider = gdt.Slider5

weightKnob.Value = 0 -- Reset to 0 on start (0.5 weight)

local gradientPD = PixelData.new(vcmain.Width, vcmain.Height, color.black)

function updateGradient(r1, g1, b1, r2, g2, b2)
	local weight = (weightKnob.Value + 100) / 200 -- Make it range from 0 to 1
  for y = 0, vcmain.Height do
    for x = 0, vcmain.Width do
      local progressX = x / vcmain.Width * weight
      local progressY = y / vcmain.Height * weight
			
      local r = math.floor(r1 * (1 - progressX) + r2 * progressX)
      local g = math.floor(g1 * (1 - progressX) + g2 * progressX)
      local b = math.floor(b1 * (1 - progressX) + b2 * progressX)
			
      local finalR = math.floor(r * (1 - progressY) + r2 * progressY)
      local finalG = math.floor(g * (1 - progressY) + g2 * progressY)
      local finalB = math.floor(b * (1 - progressY) + b2 * progressY)
			
      gradientPD:SetPixel(x, y, Color(finalR, finalG, finalB))
    end
  end
end

-- update function is repeated every time tick
function update()
	-- Get color values
	local r1 = r1Slider.Value * 2.55
	local g1 = g1Slider.Value * 2.55
	local b1 = b1Slider.Value * 2.55
	local color1 = Color(r1, g1, b1)
	
	local r2 = r2Slider.Value * 2.55
	local g2 = g2Slider.Value * 2.55
	local b2 = b2Slider.Value * 2.55
	local color2 = Color(r2, g2, b2)
	
	-- Fill the screens with the selected color
	vccol1:Clear(color1)
	vccol2:Clear(color2)
	-- Draw gradient
	updateGradient(r1, g1, b1, r2, g2, b2)
	vcmain:SetPixelData(gradientPD)
end