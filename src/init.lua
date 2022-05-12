--!strict
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = script.Parent

local Isotope = require(packages:WaitForChild("isotope"))
local Signal = require(packages:WaitForChild("signal"))
local Spritesheet = require(script:WaitForChild("Spritesheet"))

local GuiObject = {}
GuiObject.__index = GuiObject
setmetatable(GuiObject, Isotope)

function GuiObject:Destroy()
	Isotope.Destroy(self)
end

function GuiObject.new(config)
	local self = setmetatable(Isotope.new(config), GuiObject)
	self.Name = self:Import(config.Name, "IconLabel")
	self.ClassName = self._Fuse.Computed(function() return script.Name end)

	self.IconTransparency = self:Import(config.IconTransparency, 0)
	self.IconColor3 = self:Import(config.IconColor3, Color3.new(1,1,1))
	self.Icon = self:Import(config.Icon, nil)
	
	self.DotsPerInch = self._Fuse.Value(36)

	self.IconData = self._Fuse.Computed(self.Icon, self.DotsPerInch, function(key, dpi)
		if not key then return {} end
		local iconResolutions = Spritesheet[string.lower(key)] or {}
		return iconResolutions[dpi]
	end)

	local parameters = {
		Name = self.Name,
		BackgroundTransparency = 1,
		Image = self._Fuse.Computed(self.IconData, function(iconData)
			if not iconData or not iconData.Sheet then return "" end
			return "rbxassetid://"..iconData.Sheet
		end),
		ImageRectOffset = self._Fuse.Computed(self.IconData, function(iconData)
			if not iconData then return Vector2.new(0,0) end
			return Vector2.new(iconData.X, iconData.Y)
		end),
		ImageRectSize = self._Fuse.Computed(self.DotsPerInch, function(dpi)
			return Vector2.new(dpi, dpi)
		end),
		ImageColor3 = self.Color3,
	}

	for k, v in pairs(config) do
		if parameters[k] == nil and self[k] == nil then
			parameters[k] = v
		end
	end

	self.Instance = self._Fuse.new("ImageLabel")(parameters)

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
	return self.Instance
end

return GuiObject