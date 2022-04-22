--!strict
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = script.Parent

local Fusion = require(packages:WaitForChild("coldfusion"))
local Isotope = require(packages:WaitForChild("isotope"))
local Signal = require(packages:WaitForChild("signal"))
local Format = require(packages:WaitForChild("format"))
local Spritesheet = require(script:WaitForChild("Spritesheet"))

local GuiObject = {}
GuiObject.__index = GuiObject
setmetatable(GuiObject, Isotope)

function GuiObject:Destroy()
	Isotope.Destroy(self)
end

function GuiObject.new(config)
	local self = setmetatable(Isotope.new(config), GuiObject)
	self.Name = Isotope.import(config.Name, script.Name)
	self.ClassName = Fusion.Computed(function() return script.Name end)

	self.IconTransparency = Isotope.import(config.IconTransparency, 0)
	self.IconColor3 = Isotope.import(config.IconColor3, Color3.new(1,1,1))
	self.Icon = Isotope.import(config.Icon, nil)
	
	self.DotsPerInch = Fusion.Value(36)

	self.IconData = Fusion.Computed(self.Icon, self.DotsPerInch, function(key, dpi)
		local iconResolutions = Spritesheet[string.lower(key)] or {}
		return iconResolutions[dpi]
	end)

	local parameters = {
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		Image = Fusion.Computed(self.IconData, function(iconData)
			if not iconData then return "" end
			return iconData.Sheet
		end),
		ImageRectOffset = Fusion.Computed(self.IconData, function(iconData)
			if not iconData then return Vector2.new(0,0) end
			return Vector2.new(iconData.X, iconData.Y)
		end),
		ImageRectSize = Fusion.Computed(self.DotsPerInch, function(dpi)
			return Vector2.new(dpi, dpi)
		end),
		ImageColor3 = self.Color3,
	}

	for k, v in pairs(config) do
		if parameters[k] == nil and self[k] == nil then
			parameters[k] = v
		end
	end

	self.Instance = Fusion.new("ImageLabel")(parameters)

	self._Maid:GiveTask(self.Instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if not self.Instance or not self.Instance:IsDescendantOf(game) then return end
		local dpi = math.min(self.Instance.AbsoluteSize.X, self.Instance.AbsoluteSize.Y)
		local options = {36,48,72,96}
		local closest = 36
		local closestDelta = nil
	
		for i, res in ipairs(options) do
			if dpi % res == 0 or res % dpi == 0 then
				closest = res
				break
			elseif not closestDelta or math.abs(res - dpi) < closestDelta then
				closest = res
				closestDelta = math.abs(res - dpi)
			end
		end
	
		self.DotsPerInch:Set(closest)
	end))

	self:Construct()
	return self
end

return GuiObject