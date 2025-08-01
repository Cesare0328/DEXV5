-- < Fix for module threads not being supported since synapse x > --
local script = getgenv().Dex:WaitForChild("PropertiesFrame"):WaitForChild("Properties")
-- < Aliases > --
local math_floor = math.floor
local math_ceil = math.ceil
local math_max = math.max
local string_len = string.len
local string_sub = string.sub
local string_gsub = string.gsub
local string_split = string.split
local string_format = string.format
local string_find = string.find
local string_lower = string.lower
local table_concat = table.concat
local table_insert = table.insert
local table_sort = table.sort
local Instance_new = Instance.new
local Color3_fromRGB = Color3.fromRGB
local Color3_new = Color3.new
local UDim2_new = UDim2.new
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new
local NumberRange_new = NumberRange.new
local BrickColor_palette = BrickColor.palette
local wait = task.wait
-- < Services > --
local CollectionService = cloneref(game:GetService("CollectionService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local ContentProvider = cloneref(game:GetService("ContentProvider"))
local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
-- < Bindables > --
local Bindables = script.Parent.Parent:WaitForChild("Bindables", 300)
local GetApi_Bindable = Bindables:WaitForChild("GetApi", 300)
local GetSpecials_Bindable = Bindables:WaitForChild("GetSpecials", 300)
local GetSelection_Bindable = Bindables:WaitForChild("GetSelection", 300)
local GetSetting_Bindable = Bindables:WaitForChild("GetSetting", 300)
local GetAwaiting_Bindable = Bindables:WaitForChild("GetAwaiting", 300)
local SelectionChanged_Bindable = Bindables:WaitForChild("SelectionChanged", 300)
local SetAwaiting_Bindable = Bindables:WaitForChild("SetAwaiting", 300)
local GetPrint_Bindable = Bindables:WaitForChild("GetPrint", 300)
-- < Specials > --
local Specials = GetSpecials_Bindable:Invoke()
local checkrbxlocked = Specials.checkrbxlocked
local getpropertylist = Specials.getpropertylist
-- < Source > --
local Gui = script.Parent.Parent
local PropertiesFrame = script.Parent
local ExplorerFrame = Gui:WaitForChild("ExplorerPanel")
local print = GetPrint_Bindable:Invoke()
-- RbxApi Stuff
local maxChunkSize = 100 * 1000

local function getCurrentApiJson()
	local jsonStr
	local success = pcall(function()
		jsonStr = game:HttpGet("https://raw.githubusercontent.com/Cesare0328/DEXV5/refs/heads/main/API-DUMP.JSON", true)
	end)
	if success then
		return jsonStr
	else
		print("[DEX] Json loading failed!")
	end
end

local function splitStringIntoChunks(jsonStr)
	local t = {}
	for i = 1, math_ceil(string_len(jsonStr)/maxChunkSize) do
		table_insert(t, string_sub(jsonStr, (i - 1) * maxChunkSize + 1, i * maxChunkSize))
	end
	return t
end

local apiChunks = splitStringIntoChunks(getCurrentApiJson())

local function getRbxApi()
	local function GetApiRemoteFunction(index)
		if (apiChunks[index]) then 
			return apiChunks[index], #apiChunks
		else
			return
		end
	end

	local function getApiJson()
		local apiTable = {}
		local firstPage, pageCount = GetApiRemoteFunction(1)
		table_insert(apiTable, firstPage)
		for i = 2, pageCount do
			local page = GetApiRemoteFunction(i)
			table_insert(apiTable, page)
		end
		return table_concat(apiTable)
	end

	local json = getApiJson()
	local apiDump = HttpService:JSONDecode(json)

	local Classes = {
		boolean = {},
		BrickColor = {},
		Color3 = {},
		default = {}
	}

	local function sortAlphabetic(t, property)
		table_sort(t,function(x,y)
			return tostring(x[property]) < tostring(y[property])
		end)
	end

	local function getProperties(classInstance, ClassName, RbxApi)
		local Blacklist = {
			Attributes = true, -- added custom tab for attributes
			Tags = true -- added custom tab for tags
		}
		local Binary = {
			Tags = true,
			AttributesSerialize = true,
			AttributesReplicate = true,
			SmoothGrid = true,
			PhysicsGrid = true,
			MaterialColors = true,
			RawJoinData = true,
			LODData = true,
			ChildData = true,
			MeshData = true,
			ModelMeshData = true,
			PhysicsData = true
		}
		local Properties = {
			{
				ValueType = "Vector3",
				CurrentValue = Vector3.zero,
				Name = "Size",
				Readable = "Size",
				Tags = {},
				Class = "BasePart"
			},
			{
				ValueType = "Enum",
				CurrentValue = Enum.PartType.Block,
				Name = "Shape",
				Readable = "Shape",
				Tags = {},
				Class = "BasePart"
			},
			{
				ValueType = "boolean",
				CurrentValue = false,
				Name = "RobloxLocked",
				Special = checkrbxlocked,
				Tags = {"readonly"},
				Class = "Instance"
			},
			{
				ValueType = "string",
				CurrentValue = "",
				Name = "PhysicalConfigData",
				Special = getpcdprop,
				Tags = {"readonly"},
				Class = "TriangleMeshPart"
			}
		}
		local gottenprops = getpropertylist(classInstance)

		for key, prop in ipairs(Properties) do
		for i, name in pairs(gottenprops) do
			if not prop then continue end
        		if name == prop.Name then
            		gottenprops[i] = nil
        		end
    		end
		end
		for Property, is_scriptable in next, gottenprops do
			local Tags = {}
			local Success, Value = pcall(gethiddenproperty, classInstance, Property)
			local Value_Type = typeof(Value)
			if not Success then
				Value = ""
			end
			local PropertyData = RbxApi.Classes[classInstance.ClassName][Property]
			if PropertyData and PropertyData.Tags then
				Tags = PropertyData.Tags
			end
			table_insert(Properties, {
				ValueType = Value_Type,
				CurrentValue = Value,
				Name = gottenprops[Property],
				Binary = Binary[Property] and true,
				Tags = Tags,
				Class = ClassName
			})
		end
		for prop,_ in pairs(Blacklist) do
			for index, data in pairs(Properties) do
				if data.Name == prop then
					table.remove(Properties, index)
				end
			end
		end
		sortAlphabetic(Properties, "Name")
		return Properties
	end

	for _, Class in next, apiDump.Classes do
		Classes[Class.Name] = {}
		for _, Member in next, Class.Members do
			if Member.MemberType == "Property" then
				Classes[Class.Name][Member.Name] = Member
			end
		end
		for _, Member in next, apiDump.Classes[1].Members do
			if Member.MemberType == "Property" then
				Classes[Class.Name][Member.Name] = Member
			end
		end
	end

	return {
		Classes = Classes,
		GetProperties = getProperties,
		InstanceClasses = apiDump.Classes
	}
end
-- Modules
local Permissions, RbxApi = {
	CanEdit = true
}, getRbxApi()
-- Styles
local Styles = {
	Font = Enum.Font.Arial,
	Margin = 5,
	Black = Color3_fromRGB(0,0,5),
	Black2 = Color3_fromRGB(24,24,29),
	White = Color3_fromRGB(244,244,249),
	White2 = Color3_fromRGB(200,200,205),
	Hover = Color3_fromRGB(2,128,149),
	Hover2 = Color3_fromRGB(5,102,146)
}

local Row = {
	Font = Styles.Font,
	FontSize = Enum.FontSize.Size12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor = Styles.White,
	TextColorOver = Styles.White2,
	TextLockedColor = Color3_fromRGB(155, 155, 160),
	Height = 24,
	BorderColor = Color3_fromRGB(54, 54, 55),
	BackgroundColor = Styles.Black2,
	BackgroundColorAlternate = Color3_fromRGB(32, 32, 37),
	BackgroundColorMouseover = Color3_fromRGB(40, 40, 45),
	TitleMarginLeft = 15
}

local DropDown = {
	Font = Styles.Font,
	FontSize = Enum.FontSize.Size14,
	TextColor = Color3_fromRGB(255, 255, 255),
	TextColorOver = Styles.White2,
	TextXAlignment = Enum.TextXAlignment.Left,
	Height = 16,
	BackColor = Styles.Black2,
	BackColorOver = Styles.Hover2,
	BorderColor = Color3_fromRGB(45, 45, 50),
	BorderSizePixel = 2,
	ArrowColor = Color3_fromRGB(80, 80, 83),
	ArrowColorOver = Styles.Hover
}

local BrickColors = {
	BoxSize = 13,
	BorderSizePixel = 1,
	BorderColor = Color3_fromRGB(53, 53, 55),
	FrameColor = Color3_fromRGB(53, 53, 55),
	Size = 20,
	Padding = 4,
	ColorsPerRow = 8,
	OuterBorder = 1,
	OuterBorderColor = Styles.Black
}

task.wait(1)

local ContentUrl = "rbxassetid://"

local propertiesSearch = PropertiesFrame.Header.TextBox

local AwaitingObjectValue = false
local AwaitingObjectObj, AwaitingObjectProp

function searchingProperties()
	return (propertiesSearch.Text ~= "" and propertiesSearch.Text ~= "Filter Properties") and true or false
end

local function GetSelection()
	local selection = GetSelection_Bindable:Invoke()
	return (#selection == 0) and {} or selection
end
-- Number
local function Round(number, decimalPlaces)
	return tonumber(string_format("%." .. (decimalPlaces or 0) .. "f", number))
end
-- Data Type Handling
local function ToString(value, type)
	if type == "float" then
		return tostring(Round(value,2))
	elseif type == "Content" then
		return (string_find(value,"/asset")) and string_sub(value, string_find(value, "=") + 1) or tostring(value)
	elseif type == "Vector2" then
		return string_format("%g, %g", value.X, value.Y)
	elseif type == "Vector3" then
		return string_format("%g, %g, %g",value.X,value.Y,value.Z)
	elseif type == "Color3" then
		return string_format("%d, %d, %d", value.R * 255, value.G * 255, value.B * 255)
	elseif type == "UDim2" then
		return string_format("{%d, %d}, {%d, %d}", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
	else
		return tostring(value)
	end
end

local function ToValue(value,type)
	if type == "EnumItem" then
		local HasEnum = string_split(value, ".")[1] == "Enum"
		if HasEnum then
			return Enum[string_split(value, ".")[2]][string_split(value, ".")[3]]
		end
		if #string_split(value, ".") == 1 then
			return tostring(value)
		end
	elseif type == "Vector2" then
		local list = string_split(value,",")
		if #list < 2 then return nil end
		return Vector2_new(tonumber(list[1]) or 0, tonumber(list[2]) or 0)
	elseif type == "Vector3" then
		local list = string_split(value,",")
		if #list < 3 then return nil end
		return Vector3_new(tonumber(list[1]) or 0, tonumber(list[2]) or 0, tonumber(list[3]) or 0)
	elseif type == "Color3" then
		local list = string_split(value,",")
		if #list < 3 then return nil end
		return Color3_fromRGB(tonumber(list[1]) or 0, tonumber(list[2]) or 0, tonumber(list[3]) or 0)
	elseif type == "UDim2" then
		local list = string_split(string_gsub(string_gsub(value, "{", ""),"}",""),",")
		if #list < 4 then return nil end
		return UDim2_new(tonumber(list[1]) or 0, tonumber(list[2]) or 0, tonumber(list[3]) or 0, tonumber(list[4]) or 0)
	elseif type == "Content" then
		if tonumber(value) ~= nil then
			value = ContentUrl .. value
		end
		return value
	elseif type == "float" or type == "int" or type == "double" or type == "number" then
		return tonumber(value)
	elseif type == "string" then
		return value
	elseif type == "NumberRange" then
		local list = string_split(value,",")
		if #list == 1 then
			if tonumber(list[1]) == nil then return nil end
			return NumberRange_new(tonumber(list[1]) or 0)
		end
		if #list < 2 then return nil end
		return NumberRange_new(tonumber(list[1]) or 0, tonumber(list[2]) or 0)
	else
		return nil
	end
end
-- Tables
local function CopyTable(T)
	local t2 = {}
	local T_mt = getrawmetatable(T)
	for k,v in next, T do
		t2[k] = v
	end
	if T_mt then
		setrawmetatable(t2, T_mt)
	end
	return t2
end

local function SortTable(T)
	table_sort(T, function(x,y) 
		return tostring(x.Name) < tostring(y.Name)
	end)
end
-- Spritesheet
local Sprite = {
	Width = 13,
	Height = 13
}

local Spritesheet = {
	Image = "rbxassetid://128896947",
	Height = 256,
	Width = 256
}

local Images = {
	"unchecked",
	"checked",
	"unchecked_over",
	"checked_over",
	"unchecked_disabled",
	"checked_disabled"
}

local function SpritePosition(spriteName)
	local x, y = 0, 0
	for _,v in ipairs(Images) do
		if (v == spriteName) then
			return {x, y}
		end
		x += Sprite.Height
		if (x + Sprite.Width) > Spritesheet.Width then
			x = 0
			y += Sprite.Height
		end
	end
end

local function GetCheckboxImageName(checked, readOnly, mouseover)
	if checked then
		if readOnly then
			return "checked_disabled"
		elseif mouseover then
			return "checked_over"
		else
			return "checked"
		end
	else
		if readOnly then
			return "unchecked_disabled"
		elseif mouseover then
			return "unchecked_over"
		else
			return "unchecked"
		end
	end
end

local MAP_ID = 418720155
-- Gui Controls --
local function Create(ty,data)
	local obj = typeof(ty) == 'string' and Instance_new(ty) or ty
	for k, v in next, data do
		if typeof(k) == 'number' then
			v.Parent = obj
		else
			obj[k] = v
		end
	end
	return obj
end

local Icon

do
	local iconMap = 'rbxassetid://' .. MAP_ID

	ContentProvider:Preload(iconMap)

	local function iconDehash(h)
		return math_floor(h/14%14), math_floor(h%14)
	end

	function Icon(IconFrame,index)
		local row,col = iconDehash(index)
		local mapSize = Vector2_new(256,256)
		local pad,border = 2,1
		local iconSize = 16

		local class = 'Frame'

		if typeof(IconFrame) == 'string' then
			class = IconFrame
			IconFrame = nil
		end

		if not IconFrame then
			IconFrame = Create(class,{
				Name = "Icon",
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Create('ImageLabel',{
					Name = "IconMap",
					Active = false,
					BackgroundTransparency = 1,
					Image = iconMap,
					Size = UDim2_new(mapSize.X / iconSize, 0, mapSize.Y / iconSize, 0)
				})
			})
		end
		IconFrame.IconMap.Position = UDim2_new(-col - (pad*(col+1) + border)/iconSize,0,-row - (pad*(row+1) + border)/iconSize,0)
		return IconFrame
	end
end

local function CreateCell(fullSize)
	local tableCell = Instance_new("Frame")
	tableCell.Size = UDim2_new(fullSize and 1 or .5, -1, 1, 0)
	tableCell.BackgroundColor3 = Row.BackgroundColor
	tableCell.BorderColor3 = Row.BorderColor
	return tableCell
end

local function CreateLabel(readOnly)
	local label = Instance_new("TextLabel")
	label.Font = Row.Font
	label.FontSize = Row.FontSize
	label.TextColor3 = readOnly and Row.TextLockedColor or Row.TextColor
	label.TextXAlignment = Row.TextXAlignment
	label.BackgroundTransparency = 1
	return label
end

local function CreateTextButton(readOnly, onClick)
	local button = Instance_new("TextButton")
	button.Font = Row.Font
	button.Active = true
	button.FontSize = Row.FontSize
	button.TextColor3 = (readOnly) and Row.TextLockedColor or Row.TextColor
	button.TextXAlignment = Row.TextXAlignment
	button.BackgroundTransparency = 1
	if not readOnly then
		button.Activated:Connect(onClick)
	end
	return button
end

local function CreateObject(readOnly)
	local button = Instance_new("TextButton")
	button.Font = Row.Font
	button.Active = true
	button.FontSize = Row.FontSize
	button.TextColor3 = readOnly and Row.TextLockedColor or Row.TextColor
	button.TextXAlignment = Row.TextXAlignment
	button.BackgroundTransparency = 1
	local cancel = Create(Icon('ImageButton', 177),{
		Name = "Cancel",
		Visible = false,
		Position = UDim2_new(1,-20,0,0),
		Size = UDim2_new(0,20,0,20),
		Parent = button
	})
	return button
end

local function CreateTextBox(readOnly)
	if readOnly then
		return CreateLabel(readOnly)
	else
		local box = Instance_new("TextBox")
		box.ClearTextOnFocus = GetSetting_Bindable:Invoke("ClearProps")
		box.Font = Row.Font
		box.FontSize = Row.FontSize
		box.TextXAlignment = Row.TextXAlignment
		box.BackgroundTransparency = 1
		box.TextColor3 = Row.TextColor
		return box
	end
end

local function CreateDropDownItem(text, onClick)
	local button = Instance_new("TextButton")
	button.Font = DropDown.Font
	button.FontSize = DropDown.FontSize
	button.TextColor3 = DropDown.TextColor
	button.TextXAlignment = DropDown.TextXAlignment
	button.BackgroundColor3 = DropDown.BackColor
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Active = true
	button.Text = text
	button.MouseEnter:Connect(function()
		button.TextColor3 = DropDown.TextColorOver
		button.BackgroundColor3 = DropDown.BackColorOver
	end)
	button.MouseLeave:Connect(function()
		button.TextColor3 = DropDown.TextColor
		button.BackgroundColor3 = DropDown.BackColor
	end)
	button.Activated:Connect(function()
		onClick(text)
	end)
	return button
end

local function CreateDropDown(choices, currentChoice, readOnly, onClick)
	local frame = Instance_new("Frame")
	frame.Name = "DropDown"
	frame.Size = UDim2_new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Active = true

	local menu, arrow, expanded, margin = nil, nil, false, DropDown.BorderSizePixel

	local button = Instance_new("TextButton")
	button.Font = Row.Font
	button.Active = true
	button.FontSize = Row.FontSize
	button.TextXAlignment = Row.TextXAlignment
	button.BackgroundTransparency = 1
	button.TextColor3 = readOnly and Row.TextLockedColor or Row.TextColor
	button.Text = currentChoice
	button.Size = UDim2_new(1, -2 * Styles.Margin, 1, 0)
	button.Position = UDim2_new(0, Styles.Margin, 0, 0)
	button.Parent = frame

	local function showArrow(color)
		if arrow then
			arrow:Destroy()
		end

		local graphicTemplate = Create('Frame',{
			Name="Graphic",
			BorderSizePixel = 0,
			BackgroundColor3 = color
		})

		local graphicSize = 8

		arrow = ArrowGraphic(graphicSize,'Down',true,graphicTemplate)
		arrow.Position = UDim2_new(1,-graphicSize * 2,.5,-graphicSize/2)
		arrow.Parent = frame
	end

	local function hideMenu()
		expanded = false
		showArrow(DropDown.ArrowColor)
		if menu then
			menu:Destroy()
		end
	end

	local function showMenu()
		expanded = true
		menu = Instance_new("Frame")
		menu.Size = UDim2_new(1, -2 * margin, 0, #choices * DropDown.Height)
		menu.Position = UDim2_new(0, margin, 0, Row.Height + margin)
		menu.BackgroundTransparency = 0
		menu.BackgroundColor3 = DropDown.BackColor
		menu.BorderColor3 = DropDown.BorderColor
		menu.BorderSizePixel = DropDown.BorderSizePixel
		menu.Active = true
		menu.ZIndex = 5
		menu.Parent = frame

		local parentFrameHeight = menu.Parent.Parent.Parent.Parent.Size.Y.Offset
		local rowHeight = menu.Parent.Parent.Parent.Position.Y.Offset
		if (rowHeight + menu.Size.Y.Offset) > math_max(parentFrameHeight,PropertiesFrame.AbsoluteSize.Y) then
			menu.Position = UDim2_new(0, margin, 0, -1 * (#choices * DropDown.Height) - margin)
		end

		local function choice(name)
			onClick(name)
			hideMenu()
		end

		for i,name in next, choices do
			local option = CreateDropDownItem(name, function()
				choice(name)
			end)
			option.Size = UDim2_new(1, 0, 0, 16)
			option.Position = UDim2_new(0, 0, 0, (i - 1) * DropDown.Height)
			option.ZIndex = menu.ZIndex
			option.Parent = menu
		end
	end

	showArrow(DropDown.ArrowColor)

	if not readOnly then
		button.MouseEnter:Connect(function()
			button.TextColor3 = Row.TextColor
			showArrow(DropDown.ArrowColorOver)
		end)
		button.MouseLeave:Connect(function()
			button.TextColor3 = Row.TextColor
			if not expanded then
				showArrow(DropDown.ArrowColor)
			end
		end)
		button.Activated:Connect(function()
			(expanded and hideMenu or showMenu)()
		end)
	end

	return frame,button
end

local function CreateBrickColor(readOnly, onClick)
	local frame = Instance_new("Frame")
	frame.Size = UDim2_new(1,0,1,0)
	frame.BackgroundTransparency = 1

	local colorPalette = Instance_new("Frame")
	colorPalette.BackgroundTransparency = 0
	colorPalette.SizeConstraint = Enum.SizeConstraint.RelativeXX
	colorPalette.Size = UDim2_new(1, -2 * BrickColors.OuterBorder, 1, -2 * BrickColors.OuterBorder)
	colorPalette.BorderSizePixel = BrickColors.BorderSizePixel
	colorPalette.BorderColor3 = BrickColors.BorderColor
	colorPalette.Position = UDim2_new(0, BrickColors.OuterBorder, 0, BrickColors.OuterBorder + Row.Height)
	colorPalette.ZIndex = 5
	colorPalette.Visible = false
	colorPalette.BorderSizePixel = BrickColors.OuterBorder
	colorPalette.BorderColor3 = BrickColors.OuterBorderColor
	colorPalette.Parent = frame

	local function show()
		colorPalette.Visible = true
	end

	local function hide()
		colorPalette.Visible = false
	end

	local function toggle()
		colorPalette.Visible = not colorPalette.Visible
	end

	local colorBox = Instance_new("TextButton")
	colorBox.Position = UDim2_new(0, Styles.Margin, 0, Styles.Margin)
	colorBox.Active = true
	colorBox.AutoButtonColor = readOnly and false or true
	colorBox.Size = UDim2_new(0, BrickColors.BoxSize, 0, BrickColors.BoxSize)
	colorBox.Text = ""
	colorBox.Parent = frame

	if not readOnly then
		colorBox.Activated:Connect(toggle)
	end

	local spacingBefore = (Styles.Margin * 2) + BrickColors.BoxSize

	local propertyLabel = CreateTextButton(readOnly, function()
		if not readOnly then
			toggle()
		end
	end)
	propertyLabel.Size = UDim2_new(1, (-1 * spacingBefore) - Styles.Margin, 1, 0)
	propertyLabel.Position = UDim2_new(0, spacingBefore, 0, 0)
	propertyLabel.Parent = frame

	local size = (1 / BrickColors.ColorsPerRow)

	for index = 0, 127 do
		local brickColor = BrickColor_palette(index)

		local brickColorBox = Instance_new("TextButton")
		brickColorBox.Text = ""
		brickColorBox.Active = true
		brickColorBox.Size = UDim2_new(size,0,size,0)
		brickColorBox.BackgroundColor3 = brickColor.Color
		brickColorBox.Position = UDim2_new(size * (index % BrickColors.ColorsPerRow), 0, size * math_floor(index / BrickColors.ColorsPerRow), 0)
		brickColorBox.ZIndex = colorPalette.ZIndex
		brickColorBox.Parent = colorPalette
		brickColorBox.Activated:Connect(function()
			hide()
			onClick(brickColor)
		end)
	end
	return frame, propertyLabel, colorBox
end

local function CreateColor3Control(readOnly, onClick)
	local frame = Instance_new("Frame")
	frame.Size = UDim2_new(1,0,1,0)
	frame.BackgroundTransparency = 1

	local colorBox = Instance_new("TextButton")
	colorBox.Active = true
	colorBox.Position = UDim2_new(0, Styles.Margin, 0, Styles.Margin)
	colorBox.Size = UDim2_new(0, BrickColors.BoxSize, 0, BrickColors.BoxSize)
	colorBox.Text = ""
	colorBox.AutoButtonColor = false
	colorBox.Parent = frame

	local spacingBefore = (Styles.Margin * 2) + BrickColors.BoxSize
	local box = CreateTextBox(readOnly)
	box.Size = UDim2_new(1, (-1 * spacingBefore) - Styles.Margin, 1, 0)
	box.Position = UDim2_new(0, spacingBefore, 0, 0)
	box.Parent = frame

	return frame,box,colorBox
end

function CreateCheckbox(value, readOnly, onClick)
	local checked = value
	local mouseover = false

	local checkboxFrame = Instance_new("ImageButton")
	checkboxFrame.Active = true
	checkboxFrame.Size = UDim2_new(0, Sprite.Width, 0, Sprite.Height)
	checkboxFrame.BackgroundTransparency = 1
	checkboxFrame.ClipsDescendants = true

	local spritesheetImage = Instance_new("ImageLabel")
	spritesheetImage.Name = "SpritesheetImageLabel"
	spritesheetImage.Size = UDim2_new(0, Spritesheet.Width, 0, Spritesheet.Height)
	spritesheetImage.Image = Spritesheet.Image
	spritesheetImage.BackgroundTransparency = 1
	spritesheetImage.Parent = checkboxFrame

	local function updateSprite()
		local spriteName = GetCheckboxImageName(checked, readOnly, mouseover)
		local spritePosition = SpritePosition(spriteName)
		spritesheetImage.Position = UDim2_new(0, -1 * spritePosition[1], 0, -1 * spritePosition[2])
	end

	local function setValue(val)
		checked = val
		updateSprite()
	end

	if not readOnly then
		checkboxFrame.MouseEnter:Connect(function() 
			mouseover = true 
			updateSprite() 
		end)
		checkboxFrame.MouseLeave:Connect(function() 
			mouseover = false 
			updateSprite() 
		end)
		checkboxFrame.Activated:Connect(function()
			onClick(checked)
		end)
	end

	updateSprite()

	return checkboxFrame, setValue
end

local Controls = {}

function Controls.default(object, propertyData, readOnly)
	local propertyName = propertyData.Name
	local propertyType = propertyData.ValueType

	local box = CreateTextBox(readOnly)
	box.Size = UDim2_new(1, -2 * Styles.Margin, 1, 0)
	box.Position = UDim2_new(0, Styles.Margin, 0, 0)

	local focusLostCon, changedCon, eventCon

	local function update()
		local success, value
		if propertyData.Binary then
			success, value = pcall(readbinarystring, object, propertyName)
		elseif propertyData.Special then
			success, value = pcall(propertyData.Special, object, propertyName)
		else
			success, value = pcall(gethiddenproperty, object, propertyData.Readable or propertyName)
		end
		if success then
			box.Text = ToString(value, propertyType)
		else 
			box.Text = propertyData.TextReplacement or ""
		end
	end

	if not readOnly then
		focusLostCon = box.FocusLost:Connect(function(enterPressed)
			Set(object, propertyName, ToValue(box.Text, propertyType))
			update()
		end)
	end

	update()

	changedCon = object.Changed:Connect(update)

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		if focusLostCon then
			focusLostCon:Disconnect()
		end
		changedCon:Disconnect()
		eventCon:Disconnect()
		changedCon = nil
		eventCon = nil
	end)

	return box
end

function Controls.boolean(object, propertyData, readOnly)
	local propertyName = propertyData.Name
	local checked = propertyData.CurrentValue

	local checkbox, setValue = CreateCheckbox(checked, readOnly, function(value)
		Set(object, propertyName, not checked)
	end)

	local changedCon, eventCon

	local function update()
		local success
		if propertyData.Special then
			success, checked = pcall(propertyData.Special, object, propertyName)
		else
			success, checked = pcall(gethiddenproperty, object, propertyData.Readable or propertyName)
		end
		setValue(checked)
	end

	checkbox.Position = UDim2_new(0, Styles.Margin, 0, Styles.Margin)

	changedCon = object.Changed:Connect(update)

	update()

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		changedCon:Disconnect()
		eventCon:Disconnect()
		changedCon = nil
		eventCon = nil
	end)

	return checkbox
end

function Controls.BrickColor(object, propertyData, readOnly)
	local propertyName = propertyData.Name

	local frame, label, brickColorBox = CreateBrickColor(readOnly, function(brickColor)
		Set(object, propertyName, brickColor)
	end)

	local changedCon, eventCon

	local function update()
		local success, value
		if propertyData.Special then
			success, value = pcall(propertyData.Special, object, propertyName)
		else
			success, value = pcall(gethiddenproperty, object, propertyData.Readable or propertyName)
		end
		if success then 
			brickColorBox.BackgroundColor3 = value.Color
			label.Text = tostring(value)
		end
	end

	update()

	changedCon = object.Changed:Connect(update)

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		changedCon:Disconnect()
		eventCon:Disconnect()
		changedCon = nil
		eventCon = nil
	end)

	return frame
end

function Controls.Color3(object, propertyData, readOnly)
	local propertyName = propertyData.Name

	local frame, textBox, colorBox = CreateColor3Control(readOnly)

	local focusLostCon, changedCon, eventCon

	local function update()
		local success, value
		if propertyData.Special then
			success, value = pcall(propertyData.Special, object, propertyName)
		else
			success, value = pcall(gethiddenproperty, object, propertyData.Readable or propertyName)
		end
		if success then 
			colorBox.BackgroundColor3 = value
			textBox.Text = ToString(value, "Color3")
		end
	end

	focusLostCon = textBox.FocusLost:Connect(function(enterPressed)
		Set(object, propertyName, ToValue(textBox.Text, "Color3"))
		update()
	end)

	changedCon = object.Changed:Connect(update)

	update()

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		focusLostCon:Disconnect()
		changedCon:Disconnect()
		eventCon:Disconnect()
		focusLostCon = nil
		changedCon = nil
		eventCon = nil
	end)

	return frame
end

function Controls.Instance(object, propertyData, readOnly)
	local propertyName = propertyData.Name
	local propertyType = propertyData.ValueType

	local box = CreateObject(readOnly)
	local Cancel = box:FindFirstChild("Cancel")
	box.Size = UDim2_new(1, -2 * Styles.Margin, 1, 0)
	box.Position = UDim2_new(0, Styles.Margin, 0, 0)

	local boxCon, cancelCon, propCon, eventCon

	local function update()
		if AwaitingObjectObj == object then
			if AwaitingObjectValue == true then
				box.Text = "Select an Instance"
				return
			end
		end
		local success, value
		if propertyData.Special then
			success, value = pcall(propertyData.Special, object, propertyName)
		else
			success, value = pcall(gethiddenproperty, object, propertyData.Readable or propertyName)
		end
		if success then
			box.Text = ToString(value, propertyType)
		end
	end

	if not readOnly then
		boxCon = box.Activated:Connect(function()
			if AwaitingObjectValue then
				AwaitingObjectValue = false
				Cancel.Visible = false
				update()
				return
			end
			Cancel.Visible = true
			AwaitingObjectValue = true
			AwaitingObjectObj = object
			AwaitingObjectProp = propertyData
			box.Text = "Select an Instance"
		end)
		cancelCon = Cancel.Activated:Connect(function()
			sethiddenproperty(object, propertyName, nil)
			Cancel.Visible = false
		end)
	end

	update()

	local Success, Signal = pcall(game.GetPropertyChangedSignal, object, propertyName)

	if Success then
		propCon = Signal:Connect(update)
	else
		propCon = object.Changed:Connect(function(property)
			if (property == propertyName) then
				update()
			end
		end)
	end

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		if boxCon then
			boxCon:Disconnect()
			boxCon = nil
		end
		if cancelCon then
			cancelCon:Disconnect()
			cancelCon = nil
		end
		propCon:Disconnect()
		eventCon:Disconnect()
		propCon = nil
		eventCon = nil
	end)

	return box
end

local AttributeControls = {}

local GetAttribute = game.GetAttribute
function AttributeControls.default(object, name, value, valueType, readOnly)
	local box = CreateTextBox(readOnly)
	box.Size = UDim2_new(1, -2 * Styles.Margin, 1, 0)
	box.Position = UDim2_new(0, Styles.Margin, 0, 0)

	local focusLostCon, changedCon, eventCon

	local function update()
		local success, result = pcall(GetAttribute, object, name)
		if success then
			box.Text = ToString(result, valueType)
		else 
			box.Text = tostring(value)
		end
	end

	if not readOnly then
		focusLostCon = box.FocusLost:Connect(function(enterPressed)
			object:SetAttribute(name, ToValue(box.Text, valueType))
			update()
		end)
	end

	update()

	changedCon = object.Changed:Connect(update)

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		if focusLostCon then
			focusLostCon:Disconnect()
			focusLostCon = nil
		end
		changedCon:Disconnect()
		eventCon:Disconnect()
		changedCon = nil
		eventCon = nil
	end)

	return box
end

function AttributeControls.boolean(object, name, value, valueType, readOnly)
	local checked = object:GetAttribute(name)

	local checkbox, setValue = CreateCheckbox(checked, readOnly, function(value)
		object:SetAttribute(name, not checked)
	end)

	local changedCon, eventCon

	local function update()
		local success, checked = pcall(GetAttribute, object, name)
		setValue(checked)
	end

	checkbox.Position = UDim2_new(0, Styles.Margin, 0, Styles.Margin)

	changedCon = object.Changed:Connect(update)

	update()

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		changedCon:Disconnect()
		eventCon:Disconnect()
		changedCon = nil
		eventCon = nil
	end)

	return checkbox
end

function AttributeControls.BrickColor(object, name, value, valueType, readOnly)
	local frame, label, brickColorBox = CreateBrickColor(readOnly, function(brickColor)
		object:SetAttribute(name, brickColor)
	end)

	local changedCon, eventCon

	local function update()
		local success, value = pcall(GetAttribute, object, name)
		if success then 
			brickColorBox.BackgroundColor3 = value.Color
			label.Text = tostring(value)
		end
	end

	update()

	changedCon = object.Changed:Connect(update)

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		changedCon:Disconnect()
		eventCon:Disconnect()
		changedCon = nil
		eventCon = nil
	end)

	return frame
end

function AttributeControls.Color3(object, name, value, valueType, readOnly)
	local frame, textBox, colorBox = CreateColor3Control(readOnly)

	local focusLostCon, changedCon, eventCon

	local function update()
		local success, value = pcall(GetAttribute, object, name)
		if success then 
			colorBox.BackgroundColor3 = value
			textBox.Text = ToString(value, "Color3")
		end
	end

	focusLostCon = textBox.FocusLost:Connect(function(enterPressed)
		object:SetAttribute(name, ToValue(textBox.Text, "Color3"))
		update()
	end)

	changedCon = object.Changed:Connect(update)

	update()

	eventCon = SelectionChanged_Bindable.Event:Connect(function()
		focusLostCon:Disconnect()
		changedCon:Disconnect()
		eventCon:Disconnect()
		focusLostCon = nil
		changedCon = nil
		eventCon = nil
	end)

	return frame
end

local function GetAttributeControl(object, name, value, valueType, readOnly)
	local control

	if AttributeControls[valueType] then
		control = AttributeControls[valueType](object, name, value, valueType, readOnly)
	else
		control = AttributeControls.default(object, name, value, valueType, readOnly)
	end

	return control
end

local function GetControl(object, propertyData, readOnly)
	local propertyType = propertyData.ValueType
	local RbxApiPropertyData = RbxApi.Classes[object.ClassName][propertyData.Name]
	local control

	if Controls[propertyType] then
		control = Controls[propertyType](object, propertyData, readOnly)
	elseif RbxApiPropertyData then
		local ControlType = Controls[RbxApiPropertyData.ValueType.Name] or Controls.default
		control = Controltypeof(object, propertyData, readOnly)
	else
		control = Controls.default(object, propertyData, readOnly)
	end

	return control
end

local function CanEditProperty(object, propertyData)
	if propertyData.Binary then
		return false
	end
	for _, Tag in next, propertyData.Tags do
		if string_lower(Tag) == "readonly" then
			return false
		end
	end
	return Permissions.CanEdit
end

function Set(object, propertyName, value)
	pcall(sethiddenproperty, object, propertyName, value)
end

local function CreateTextRow(text, isAlternateRow)
	local backColor = isAlternateRow and Row.BackgroundColorAlternate or Row.BackgroundColor

	local readOnly = true

	local rowFrame = Instance_new("Frame")
	rowFrame.Size = UDim2_new(1,0,0,Row.Height)
	rowFrame.BackgroundTransparency = 1
	rowFrame.Name = 'Row'

	local labelFrame = CreateCell(true)
	labelFrame.ClipsDescendants = true

	local label = CreateLabel(readOnly)
	label.RichText = true
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Size = UDim2_new(1, -1 * Row.TitleMarginLeft, 1, 0)
	label.Position = UDim2_new(0, Row.TitleMarginLeft, 0, 0)
	label.Parent = labelFrame

	labelFrame.BackgroundColor3 = backColor

	labelFrame.Parent = rowFrame

	return rowFrame
end

local function CreateTagRow(object, tag, isAlternateRow)
	local backColor = isAlternateRow and Row.BackgroundColorAlternate or Row.BackgroundColor

	local readOnly = true

	local rowFrame = Instance_new("Frame")
	rowFrame.Size = UDim2_new(1,0,0,Row.Height)
	rowFrame.BackgroundTransparency = 1
	rowFrame.Name = 'Row'

	local tagLabelFrame = CreateCell(true)
	tagLabelFrame.ClipsDescendants = true

	local tagLabel = CreateLabel(readOnly)
	tagLabel.RichText = true
	tagLabel.Text = tag
	tagLabel.TextXAlignment = Enum.TextXAlignment.Center
	tagLabel.Size = UDim2_new(1, -1 * Row.TitleMarginLeft, 1, 0)
	tagLabel.Position = UDim2_new(0, Row.TitleMarginLeft, 0, 0)
	tagLabel.Parent = tagLabelFrame

	local cancel = Create(Icon('ImageButton', 177), {
		Name = "Cancel",
		Visible = true,
		Position = UDim2_new(1,-20,0,0),
		Size = UDim2_new(0,20,0,20),
		Parent = tagLabel
	})

	local cancelCon

	cancelCon = cancel.Activated:Connect(function()
		if cancelCon then
			cancelCon:Disconnect()
			cancelCon = nil
		end
		CollectionService:RemoveTag(object, tag)
		cancel.Visible = false
		tagLabel.Text = "REMOVED"
	end)

	tagLabelFrame.BackgroundColor3 = backColor

	tagLabelFrame.Parent = rowFrame

	return rowFrame
end

local function CreateAttributeRow(object, name, value, isAlternateRow)
	local backColor = isAlternateRow and Row.BackgroundColorAlternate or Row.BackgroundColor

	local fullAttribute

	local rowFrame = Instance_new("Frame")
	rowFrame.Size = UDim2_new(1,0,0,Row.Height)
	rowFrame.BackgroundTransparency = 1
	rowFrame.Name = 'Row'

	local attributeLabelFrame = CreateCell(false)
	attributeLabelFrame.ClipsDescendants = true

	local attributeLabel = CreateLabel(false)
	attributeLabel.Text = name
	attributeLabel.Size = UDim2_new(1, -1 * Row.TitleMarginLeft, 1, 0)
	attributeLabel.Position = UDim2_new(0, Row.TitleMarginLeft, 0, 0)
	attributeLabel.Parent = attributeLabelFrame

	attributeLabelFrame.Parent = rowFrame

	local attributeValueFrame = CreateCell(false)
	attributeValueFrame.Size = UDim2_new(.5, -1, 1, 0)
	attributeValueFrame.Position = UDim2_new(.5, 0, 0, 0)
	attributeValueFrame.Parent = rowFrame

	local control = GetAttributeControl(object, name, value, typeof(value), false)
	control.Parent = attributeValueFrame

	attributeLabel.MouseEnter:Connect(function()
		fullAttribute = Instance_new("TextLabel")
		fullAttribute.BackgroundColor3 = backColor
		fullAttribute.Text = name
		fullAttribute.TextColor3 = DropDown.TextColor
		fullAttribute.Size = UDim2_new(1,-1,1,0)
		fullAttribute.Position = UDim2_new(0, DropDown.BorderSizePixel,0,0)

		local UICorner = Instance_new("UICorner")
		UICorner.CornerRadius = UDim.new(0,10)
		UICorner.Name = ""
		UICorner.Parent = fullAttribute

		fullAttribute.Parent = rowFrame
	end)

	attributeLabel.MouseLeave:Connect(function()
		if fullAttribute then
			fullAttribute:Destroy()
		end
	end)

	rowFrame.MouseEnter:Connect(function()
		attributeLabelFrame.BackgroundColor3 = Row.BackgroundColorMouseover
		attributeValueFrame.BackgroundColor3 = Row.BackgroundColorMouseover
	end)

	rowFrame.MouseLeave:Connect(function()
		attributeLabelFrame.BackgroundColor3 = backColor
		attributeValueFrame.BackgroundColor3 = backColor
	end)

	rowFrame.InputEnded:Connect(function(input)
		if input.UserInputType.Name == 'MouseButton1' and UserInputService:IsKeyDown('LeftControl') then
			if	input.Position.X > rowFrame.AbsolutePosition.X and
				input.Position.Y > rowFrame.AbsolutePosition.Y and
				input.Position.X < rowFrame.AbsolutePosition.X + rowFrame.AbsoluteSize.X and
				input.Position.Y < rowFrame.AbsolutePosition.Y + rowFrame.AbsoluteSize.Y then 
				print(pcall(setclipboard, tostring(object:GetAttribute(name))))
			end
		end
	end)

	attributeLabelFrame.BackgroundColor3 = backColor
	attributeValueFrame.BackgroundColor3 = backColor

	return rowFrame
end

local function CreateRow(object, propertyData, isAlternateRow)
	local propertyName = propertyData.Name
	local backColor = isAlternateRow and Row.BackgroundColorAlternate or Row.BackgroundColor

	local readOnly, fullProperty = not CanEditProperty(object, propertyData), nil

	local rowFrame = Instance_new("Frame")
	rowFrame.Size = UDim2_new(1,0,0,Row.Height)
	rowFrame.BackgroundTransparency = 1
	rowFrame.Name = 'Row'

	local propertyLabelFrame = CreateCell(false)
	propertyLabelFrame.ClipsDescendants = true

	local propertyLabel = CreateLabel(readOnly)
	propertyLabel.Text = propertyName
	propertyLabel.Size = UDim2_new(1, -1 * Row.TitleMarginLeft, 1, 0)
	propertyLabel.Position = UDim2_new(0, Row.TitleMarginLeft, 0, 0)
	propertyLabel.Parent = propertyLabelFrame

	propertyLabelFrame.Parent = rowFrame

	local propertyValueFrame = CreateCell(false)
	propertyValueFrame.Size = UDim2_new(.5, -1, 1, 0)
	propertyValueFrame.Position = UDim2_new(.5, 0, 0, 0)
	propertyValueFrame.Parent = rowFrame

	local control = GetControl(object, propertyData, readOnly)
	control.Parent = propertyValueFrame

	propertyLabel.MouseEnter:Connect(function()
		fullProperty = Instance_new("TextLabel")
		fullProperty.BackgroundColor3 = backColor
		fullProperty.Text = propertyName
		fullProperty.TextColor3 = DropDown.TextColor
		fullProperty.Size = UDim2_new(1,-1,1,0)
		fullProperty.Position = UDim2_new(0, DropDown.BorderSizePixel,0,0)

		local UICorner = Instance_new("UICorner")
		UICorner.CornerRadius = UDim.new(0,10)
		UICorner.Name = ""
		UICorner.Parent = fullProperty

		fullProperty.Parent = rowFrame
	end)

	propertyLabel.MouseLeave:Connect(function()
		if fullProperty then
			fullProperty:Destroy()
		end
	end)

	rowFrame.MouseEnter:Connect(function()
		propertyLabelFrame.BackgroundColor3 = Row.BackgroundColorMouseover
		propertyValueFrame.BackgroundColor3 = Row.BackgroundColorMouseover
	end)

	rowFrame.MouseLeave:Connect(function()
		propertyLabelFrame.BackgroundColor3 = backColor
		propertyValueFrame.BackgroundColor3 = backColor
	end)

	rowFrame.InputEnded:Connect(function(input)
		if input.UserInputType.Name == 'MouseButton1' and UserInputService:IsKeyDown('LeftControl') then
			if	input.Position.X > rowFrame.AbsolutePosition.X and
				input.Position.Y > rowFrame.AbsolutePosition.Y and
				input.Position.X < rowFrame.AbsolutePosition.X + rowFrame.AbsoluteSize.X and
				input.Position.Y < rowFrame.AbsolutePosition.Y + rowFrame.AbsoluteSize.Y then 
				print(pcall(setclipboard, tostring(gethiddenproperty(object, propertyName))))
			end
		end
	end)

	propertyLabelFrame.BackgroundColor3 = backColor
	propertyValueFrame.BackgroundColor3 = backColor

	return rowFrame
end

local function ClearPropertiesList()
	ContentFrame:ClearAllChildren()
end

local selection = Gui:FindFirstChild("Selection", 1)
local numRows

local function displayTextRow(text)
	pcall(function()
		local a = CreateTextRow(text, ((numRows % 2) == 0))
		a.Position = UDim2_new(0,0,0,numRows*Row.Height)
		a.Parent = ContentFrame
		numRows += 1
	end)
end

local function displayTags(tags)
	for _,data in pairs(tags) do
		pcall(function()
			local a = CreateTagRow(data.Object, data.Value, ((numRows % 2) == 0))
			a.Position = UDim2_new(0,0,0,numRows*Row.Height)
			a.Parent = ContentFrame
			numRows += 1
		end)
	end
end

local function displayAttributes(attributes)
	for name,data in pairs(attributes) do
		pcall(function()
			local a = CreateAttributeRow(data.Object, name, data.Value, ((numRows % 2) == 0))
			a.Position = UDim2_new(0,0,0,numRows*Row.Height)
			a.Parent = ContentFrame
			numRows += 1
		end)
	end
end

local function displayProperties(props)
	for _,v in next, props do
		pcall(function()
			local a = CreateRow(v.object, v.propertyData, ((numRows % 2) == 0))
			a.Position = UDim2_new(0,0,0,numRows*Row.Height)
			a.Parent = ContentFrame
			numRows += 1
		end)
	end
end

local function checkForDupe(prop,props)
	for _,v in next, props do
		if string_lower(v.propertyData.Name) == string_lower(prop.Name) and v.propertyData.ValueType == prop.ValueType then
			return true
		end
	end
	return false
end

local function sortProps(t)
	table_sort(t, function(x,y) 
		return tostring(x.propertyData.Name) < tostring(y.propertyData.Name)
	end)
end

local function getTableLength(t)
	local length = 0
	for _,_ in pairs(t) do
		length += 1
	end
	return length
end

local function showSelectionData(obj)
	ClearPropertiesList()
	local propHolder, foundProps = {}, {}
	local attributes, tags = {}, {}
	numRows = 0
	for _,nextObj in next, (obj or {}) do
		if not foundProps[nextObj.ClassName] then
			foundProps[nextObj.ClassName] = true
			for name, value in pairs(nextObj:GetAttributes()) do
				attributes[name] = {
					Object = nextObj,
					Value = value
				}
			end
			for _, value in pairs(CollectionService:GetTags(nextObj)) do
				table.insert(tags, {
					Object = nextObj,
					Value = value
				})
			end
			for i,v in next, RbxApi.GetProperties(nextObj, nextObj.ClassName, RbxApi) do
				local suc, err = pcall(function()
					if nextObj:IsA(v.Class) and not checkForDupe(v,propHolder) then
						if string_find(string_lower(v.Name),string_lower(propertiesSearch.Text)) or not searchingProperties() then
							table_insert(propHolder,{
								propertyData = v, 
								object = nextObj
							})
						end
					end
				end)
			end
		end
	end
	sortProps(propHolder)
	displayProperties(propHolder)
	if getTableLength(attributes) > 0 then
		displayTextRow("<b> ----- Attributes ----- </b>")
		displayAttributes(attributes)
	end
	if getTableLength(tags) > 0 then
		displayTextRow("<b> ----- Tags ----- </b>")
		displayTags(tags)
	end
	ContentFrame.Size = UDim2_new(1, 0, 0, numRows * Row.Height)
	scrollBar.ScrollIndex = 0
	scrollBar.TotalSpace = numRows * Row.Height
	scrollBar.Update()
end
-----------------------SCROLLBAR STUFF--------------------------
local ScrollBarWidth = 16

local ScrollStyles = {
	Background = Color3.fromRGB(37, 37, 42),
	Border = Color3.fromRGB(20, 20, 25),
	Selected = Color3.fromRGB(5, 100, 140),
	BorderSelected = Color3.fromRGB(2, 130, 145),
	Text = Color3.fromRGB(245, 245, 250),
	TextDisabled = Color3.fromRGB(188, 188, 193),
	TextSelected = Color3.fromRGB(255, 255, 255),
	Button = Color3.fromRGB(31, 31, 36),
	ButtonBorder = Color3.fromRGB(133, 133, 138),
	ButtonSelected = Color3.fromRGB(0, 168, 155),
	Field = Color3.fromRGB(37, 37, 42),
	FieldBorder = Color3.fromRGB(50, 50, 55),
	TitleBackground = Color3.fromRGB(11, 11, 16)
}

local SetZIndex
do
	local ZIndexLock = {}
	function SetZIndex(object,z)
		if not ZIndexLock[object] then
			ZIndexLock[object] = true
			if object:IsA'GuiObject' then
				object.ZIndex = z
			end
			local children = object:GetChildren()
			for i = 1,#children do
				SetZIndex(children[i],z)
			end
			ZIndexLock[object] = nil
		end
	end
end

local function SetZIndexOnChanged(object)
	return object:GetPropertyChangedSignal("ZIndex"):Connect(function(p)
		SetZIndex(object, object.ZIndex)
	end)
end

local function GetScreen(screen)
	if screen == nil then return nil end
	while not screen:IsA("GuiBase2d") do
		screen = screen.Parent
	end
	return screen
end

local function ResetButtonColor(button)
	local active = button.Active
	button.Active = not active
	button.Active = active
end

function ArrowGraphic(size,dir,scaled,template)
	local Frame = Create('Frame',{
		Name = "Arrow Graphic",
		BorderSizePixel = 0,
		Size = UDim2_new(0,size,0,size),
		Transparency = 1
	})

	if not template then
		template = Instance_new("Frame")
		template.BorderSizePixel = 0
	end

	template.BackgroundColor3 = Color3_new(1, 1, 1)

	local transform, scale

	if dir == nil or dir == "Up" then
		function transform(p,s) return p,s end
	elseif dir == "Down" then
		function transform(p,s) return UDim2_new(0,p.X.Offset,0,size-p.Y.Offset-1),s end
	elseif dir == "Left" then
		function transform(p,s) return UDim2_new(0,p.Y.Offset,0,p.X.Offset),UDim2_new(0,s.Y.Offset,0,s.X.Offset) end
	elseif dir == "Right" then
		function transform(p,s) return UDim2_new(0,size-p.Y.Offset-1,0,p.X.Offset),UDim2_new(0,s.Y.Offset,0,s.X.Offset) end
	end

	if scaled then
		function scale(p,s) return UDim2_new(p.X.Offset/size,0,p.Y.Offset/size,0),UDim2_new(s.X.Offset/size,0,s.Y.Offset/size,0) end
	else
		function scale(p,s) return p,s end
	end

	local o = math_floor(size / 4)
	if size % 2 == 0 then
		local n = size / 2 - 1
		for i = 0, n do
			local t = template:Clone()
			local p,s = scale(transform(
				UDim2_new(0,n-i,0,o+i),
				UDim2_new(0,(i+1)*2,0,1)
				))
			t.Position = p
			t.Size = s
			t.Parent = Frame
		end
	else
		local n = (size-1)/2
		for i = 0,n do
			local t = template:Clone()
			local p,s = scale(transform(
				UDim2_new(0,n-i,0,o+i),
				UDim2_new(0,i*2+1,0,1)
				))
			t.Position = p
			t.Size = s
			t.Parent = Frame
		end
	end
	if size%4 > 1 then
		local t = template:Clone()
		local p,s = scale(transform(
			UDim2_new(0,0,0,size-o-1),
			UDim2_new(0,size,0,1)
			))
		t.Position = p
		t.Size = s
		t.Parent = Frame
	end

	for _,v in next, Frame:GetChildren() do
		v.BackgroundColor3 = Color3_new(1, 1, 1)
	end

	return Frame
end

function GripGraphic(size,dir,spacing,scaled,template)
	local Frame = Create('Frame',{
		Name = "Grip Graphic",
		BorderSizePixel = 0,
		Size = UDim2_new(0,size.X,0,size.Y),
		Transparency = 1
	})

	if not template then
		template = Instance_new("Frame")
		template.BorderSizePixel = 0
	end

	spacing = spacing or 2

	local scale = scaled and function(p)
		return UDim2_new(p.X.Offset/size.X,0,p.Y.Offset/size.Y,0)
	end
		or function(p)
		return p
	end

	if dir == "Vertical" then
		for i=0, size.X - 1,spacing do
			local t = template:Clone()
			t.Size = scale(UDim2_new(0,1,0,size.Y))
			t.Position = scale(UDim2_new(0,i,0,0))
			t.Parent = Frame
		end
	elseif dir == nil or dir == "Horizontal" then
		for i=0, size.Y - 1,spacing do
			local t = template:Clone()
			t.Size = scale(UDim2_new(0, size.X, 0, 1))
			t.Position = scale(UDim2_new(0,0,0,i))
			t.Parent = Frame
		end
	end

	return Frame
end

do
	local mt = {
		__index = {
			GetScrollPercent = function(self)
				return self.ScrollIndex/(self.TotalSpace-self.VisibleSpace)
			end,
			CanScrollDown = function(self)
				return self.ScrollIndex + self.VisibleSpace < self.TotalSpace
			end,
			CanScrollUp = function(self)
				return self.ScrollIndex > 0
			end,
			ScrollDown = function(self)
				self.ScrollIndex += self.PageIncrement
				self:Update()
			end,
			ScrollUp = function(self)
				self.ScrollIndex -= self.PageIncrement
				self:Update()
			end,
			ScrollTo = function(self,index)
				self.ScrollIndex = index
				self:Update()
			end,
			SetScrollPercent = function(self,percent)
				self.ScrollIndex = math_floor((self.TotalSpace - self.VisibleSpace)*percent + .5)
				self:Update()
			end
		}
	}
	mt.__index.CanScrollRight = mt.__index.CanScrollDown
	mt.__index.CanScrollLeft = mt.__index.CanScrollUp
	mt.__index.ScrollLeft = mt.__index.ScrollUp
	mt.__index.ScrollRight = mt.__index.ScrollDown

	function ScrollBar(horizontal)
		local ScrollFrame = Create('Frame',{
			Name = "ScrollFrame",
			Position = horizontal and UDim2_new(0,0,1,-ScrollBarWidth) or UDim2_new(1,-ScrollBarWidth,0,0),
			Size = horizontal and UDim2_new(1,0,0,ScrollBarWidth) or UDim2_new(0,ScrollBarWidth,1,0),
			BackgroundTransparency = 1,
			Create('ImageButton',{
				Name = "ScrollDown",
				Position = horizontal and UDim2_new(1,-ScrollBarWidth,0,0) or UDim2_new(0,0,1,-ScrollBarWidth),
				Size = UDim2_new(0, ScrollBarWidth, 0, ScrollBarWidth),
				BackgroundColor3 = ScrollStyles.Button,
				BorderColor3 = ScrollStyles.Border,
				ImageColor3 = Styles.White
			}),
			Create('ImageButton',{
				Name = "ScrollUp",
				Size = UDim2_new(0, ScrollBarWidth, 0, ScrollBarWidth),
				BackgroundColor3 = ScrollStyles.Button,
				BorderColor3 = ScrollStyles.Border,
				ImageColor3 = Styles.White
			}),
			Create('ImageButton',{
				Name = "ScrollBar",
				Size = horizontal and UDim2_new(1,-ScrollBarWidth*2,1,0) or UDim2_new(1,0,1,-ScrollBarWidth*2),
				Position = horizontal and UDim2_new(0,ScrollBarWidth,0,0) or UDim2_new(0,0,0,ScrollBarWidth),
				AutoButtonColor = false,
				BackgroundColor3 = Color3_new(1/4, 1/4, 1/4),
				BorderColor3 = ScrollStyles.Border,
				Create('ImageButton',{
					Name = "ScrollThumb",
					AutoButtonColor = false,
					Size = UDim2_new(0, ScrollBarWidth, 0, ScrollBarWidth),
					BackgroundColor3 = ScrollStyles.Button,
					BorderColor3 = ScrollStyles.Border,
					ImageColor3 = Styles.White
				})
			})
		})

		local graphicTemplate = Create('Frame',{
			Name="Graphic",
			BorderSizePixel = 0,
			BackgroundColor3 = Color3_new(1, 1, 1)
		})

		local graphicSize = ScrollBarWidth/2

		local ScrollDownFrame = ScrollFrame.ScrollDown
		local ScrollDownGraphic = ArrowGraphic(graphicSize,horizontal and 'Right' or 'Down',true,graphicTemplate)
		ScrollDownGraphic.Position = UDim2_new(.5,-graphicSize/2,.5,-graphicSize/2)
		ScrollDownGraphic.Parent = ScrollDownFrame
		local ScrollUpFrame = ScrollFrame.ScrollUp
		local ScrollUpGraphic = ArrowGraphic(graphicSize,horizontal and 'Left' or 'Up',true,graphicTemplate)
		ScrollUpGraphic.Position = UDim2_new(.5,-graphicSize/2,.5,-graphicSize/2)
		ScrollUpGraphic.Parent = ScrollUpFrame
		local ScrollBarFrame = ScrollFrame.ScrollBar
		local ScrollThumbFrame = ScrollBarFrame.ScrollThumb
		do
			local size = ScrollBarWidth*3/8
			local Decal = GripGraphic(Vector2_new(size,size),horizontal and 'Vertical' or 'Horizontal',2,graphicTemplate)
			Decal.Position = UDim2_new(.5,-size/2,.5,-size/2)
			Decal.Parent = ScrollThumbFrame
		end

		local MouseDrag = Create('ImageButton',{
			Name = "MouseDrag",
			Position = UDim2_new(-.25,0,-.25,0),
			Size = UDim2_new(1.5,0,1.5,0),
			Transparency = 1,
			AutoButtonColor = false,
			Active = true,
			ZIndex = 10
		})

		local Class = setmetatable({
			GUI = ScrollFrame,
			ScrollIndex = 0,
			VisibleSpace = 0,
			TotalSpace = 0,
			PageIncrement = 1
		},mt)

		local UpdateScrollThumb
		if horizontal then
			function UpdateScrollThumb()
				ScrollThumbFrame.Size = UDim2_new(Class.VisibleSpace/Class.TotalSpace,0,0,ScrollBarWidth)
				if ScrollThumbFrame.AbsoluteSize.X < ScrollBarWidth then
					ScrollThumbFrame.Size = UDim2_new(0,ScrollBarWidth,0,ScrollBarWidth)
				end
				local barSize = ScrollBarFrame.AbsoluteSize.X
				ScrollThumbFrame.Position = UDim2_new(Class:GetScrollPercent()*(barSize - ScrollThumbFrame.AbsoluteSize.X)/barSize,0,0,0)
			end
		else
			function UpdateScrollThumb()
				ScrollThumbFrame.Size = UDim2_new(0,ScrollBarWidth,Class.VisibleSpace/Class.TotalSpace,0)
				if ScrollThumbFrame.AbsoluteSize.Y < ScrollBarWidth then
					ScrollThumbFrame.Size = UDim2_new(0,ScrollBarWidth,0,ScrollBarWidth)
				end
				local barSize = ScrollBarFrame.AbsoluteSize.Y
				ScrollThumbFrame.Position = UDim2_new(0,0,Class:GetScrollPercent()*(barSize - ScrollThumbFrame.AbsoluteSize.Y)/barSize,0)
			end
		end

		local lastDown, lastUp
		local scrollStyle = {BackgroundColor3=Color3_new(1, 1, 1),BackgroundTransparency=0}
		local scrollStyle_ds = {BackgroundColor3=Color3_new(1, 1, 1),BackgroundTransparency=.7}

		local function Update()
			local t,v,s = Class.TotalSpace,Class.VisibleSpace,Class.ScrollIndex
			if v <= t then
				if s > 0 then
					if s + v > t then
						Class.ScrollIndex = t - v
					end
				else
					Class.ScrollIndex = 0
				end
			else
				Class.ScrollIndex = 0
			end

			if Class.UpdateCallback then
				if Class.UpdateCallback(Class) == false then
					return
				end
			end

			local down,up = Class:CanScrollDown(),Class:CanScrollUp()
			if down ~= lastDown then
				lastDown = down
				ScrollDownFrame.Active = down
				ScrollDownFrame.AutoButtonColor = down
				local children,style = ScrollDownGraphic:GetChildren(),down and scrollStyle or scrollStyle_ds
				for i = 1,#children do
					Create(children[i],style)
				end
			end
			if up ~= lastUp then
				lastUp = up
				ScrollUpFrame.Active = up
				ScrollUpFrame.AutoButtonColor = up
				local children,style = ScrollUpGraphic:GetChildren(),up and scrollStyle or scrollStyle_ds
				for i = 1,#children do
					Create(children[i],style)
				end
			end
			ScrollThumbFrame.Visible = down or up
			UpdateScrollThumb()
		end
		Class.Update = Update

		SetZIndexOnChanged(ScrollFrame)

		local drag
		local scrollEventID = 0
		ScrollDownFrame.MouseButton1Down:Connect(function()
			scrollEventID = tick()
			local current,up_con = scrollEventID,nil
			up_con = MouseDrag.MouseButton1Up:Connect(function()
				scrollEventID = tick()
				MouseDrag.Parent = nil
				ResetButtonColor(ScrollDownFrame)
				up_con:Disconnect()
				drag = nil
			end)
			MouseDrag.Parent = GetScreen(ScrollFrame)
			Class:ScrollDown()
			task.wait(.2)
			while scrollEventID == current do
				Class:ScrollDown()
				if not Class:CanScrollDown() then break end
				task.wait()
			end
		end)

		ScrollDownFrame.MouseButton1Up:Connect(function()
			scrollEventID = tick()
		end)

		ScrollUpFrame.MouseButton1Down:Connect(function()
			scrollEventID = tick()
			local current,up_con = scrollEventID,nil
			up_con = MouseDrag.MouseButton1Up:Connect(function()
				scrollEventID = tick()
				MouseDrag.Parent = nil
				ResetButtonColor(ScrollUpFrame)
				up_con:Disconnect()
				drag = nil
			end)
			MouseDrag.Parent = GetScreen(ScrollFrame)
			Class:ScrollUp()
			task.wait(.2)
			while scrollEventID == current do
				Class:ScrollUp()
				if not Class:CanScrollUp() then break end
				task.wait(0)
			end
		end)

		ScrollUpFrame.MouseButton1Up:Connect(function()
			scrollEventID = tick()
		end)

		if horizontal then
			ScrollBarFrame.MouseButton1Down:Connect(function(x,y)
				scrollEventID = tick()
				local current = scrollEventID
				local up_con
				up_con = MouseDrag.MouseButton1Up:Connect(function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollUpFrame)
					up_con:Disconnect()
					drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
				if x > ScrollThumbFrame.AbsolutePosition.X then
					Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if x < ScrollThumbFrame.AbsolutePosition.X + ScrollThumbFrame.AbsoluteSize.X then break end
						Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
						task.wait(0)
					end
				else
					Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if x > ScrollThumbFrame.AbsolutePosition.X then break end
						Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
						task.wait(0)
					end
				end
			end)
		else
			ScrollBarFrame.MouseButton1Down:Connect(function(x,y)
				scrollEventID = tick()
				local current = scrollEventID
				local up_con
				up_con = MouseDrag.MouseButton1Up:Connect(function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollUpFrame)
					up_con:Disconnect(); drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
				if y > ScrollThumbFrame.AbsolutePosition.Y then
					Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if y < ScrollThumbFrame.AbsolutePosition.Y + ScrollThumbFrame.AbsoluteSize.Y then break end
						Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
						task.wait(0)
					end
				else
					Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if y > ScrollThumbFrame.AbsolutePosition.Y then break end
						Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
						task.wait(0)
					end
				end
			end)
		end

		if horizontal then
			ScrollThumbFrame.MouseButton1Down:Connect(function(x,y)
				scrollEventID = tick()
				local mouse_offset = x - ScrollThumbFrame.AbsolutePosition.X
				local drag_con,up_con
				drag_con = MouseDrag.MouseMoved:Connect(function(x,y)
					local bar_abs_pos = ScrollBarFrame.AbsolutePosition.X
					local bar_drag = ScrollBarFrame.AbsoluteSize.X - ScrollThumbFrame.AbsoluteSize.X
					local bar_abs_one = bar_abs_pos + bar_drag
					x -= mouse_offset
					x = x < bar_abs_pos and bar_abs_pos or x > bar_abs_one and bar_abs_one or x
					x -= bar_abs_pos
					Class:SetScrollPercent(x/(bar_drag))
				end)
				up_con = MouseDrag.MouseButton1Up:Connect(function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollThumbFrame)
					drag_con:Disconnect(); drag_con = nil
					up_con:Disconnect(); drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
			end)
		else
			ScrollThumbFrame.MouseButton1Down:Connect(function(x,y)
				scrollEventID = tick()
				local mouse_offset = y - ScrollThumbFrame.AbsolutePosition.Y
				local drag_con,up_con
				drag_con = MouseDrag.MouseMoved:Connect(function(x,y)
					local bar_abs_pos = ScrollBarFrame.AbsolutePosition.Y
					local bar_drag = ScrollBarFrame.AbsoluteSize.Y - ScrollThumbFrame.AbsoluteSize.Y
					local bar_abs_one = bar_abs_pos + bar_drag
					y -= mouse_offset
					y = y < bar_abs_pos and bar_abs_pos or y > bar_abs_one and bar_abs_one or y
					y -= bar_abs_pos
					Class:SetScrollPercent(y/(bar_drag))
				end)
				up_con = MouseDrag.MouseButton1Up:Connect(function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollThumbFrame)
					drag_con:Disconnect(); drag_con = nil
					up_con:Disconnect(); drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
			end)
		end

		function Class:Destroy()
			ScrollFrame:Destroy()
			MouseDrag:Destroy()
			for k in next, Class do
				Class[k] = nil
			end
			setmetatable(Class,nil)
		end
		Update()
		return Class
	end
end
----------------------------------------------------------------
local MainFrame = Instance_new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2_new(1, MainFrame.AbsoluteSize.X/2 -1 * ScrollBarWidth, 1,0)
MainFrame.Position = UDim2_new(0, 0, 0, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.ClipsDescendants = true
MainFrame.Parent = PropertiesFrame

ContentFrame = Instance_new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2_new(1, 0, 0, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

scrollBar = ScrollBar(false)
scrollBar.PageIncrement = 1

Create(scrollBar.GUI,{
	Position = UDim2_new(1,-ScrollBarWidth,0,0),
	Size = UDim2_new(0,ScrollBarWidth,1,0),
	Parent = PropertiesFrame
})

scrollBarH = ScrollBar(true)
scrollBarH.PageIncrement = ScrollBarWidth
Create(scrollBarH.GUI,{
	Position = UDim2_new(0,0,1,-ScrollBarWidth),
	Visible = false,
	Size = UDim2_new(1,-ScrollBarWidth,0,ScrollBarWidth),
	Parent = PropertiesFrame
})

do
	local listEntries,nameConnLookup = {},{}

	function scrollBar.UpdateCallback(self)
		scrollBar.TotalSpace = ContentFrame.AbsoluteSize.Y
		scrollBar.VisibleSpace = MainFrame.AbsoluteSize.Y
		ContentFrame.Position = UDim2_new(ContentFrame.Position.X.Scale,ContentFrame.Position.X.Offset,0,-1*scrollBar.ScrollIndex)
	end

	function scrollBarH.UpdateCallback(self) end

	MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		scrollBarH.VisibleSpace = math_ceil(MainFrame.AbsoluteSize.X)
		scrollBarH:Update()
		scrollBar.VisibleSpace = math_ceil(MainFrame.AbsoluteSize.Y)
		scrollBar:Update()
	end)

	local wheelAmount = Row.Height

	PropertiesFrame.MouseWheelForward:Connect(function()
		if UserInputService:IsKeyDown('LeftShift') then
			if scrollBarH.VisibleSpace - 1 > wheelAmount then
				scrollBarH:ScrollTo(scrollBarH.ScrollIndex - wheelAmount)
			else
				scrollBarH:ScrollTo(scrollBarH.ScrollIndex - scrollBarH.VisibleSpace)
			end
		else
			if scrollBar.VisibleSpace - 1 > wheelAmount then
				scrollBar:ScrollTo(scrollBar.ScrollIndex - wheelAmount)
			else
				scrollBar:ScrollTo(scrollBar.ScrollIndex - scrollBar.VisibleSpace)
			end
		end
	end)

	PropertiesFrame.MouseWheelBackward:Connect(function()
		if UserInputService:IsKeyDown('LeftShift') then
			if scrollBarH.VisibleSpace - 1 > wheelAmount then
				scrollBarH:ScrollTo(scrollBarH.ScrollIndex + wheelAmount)
			else
				scrollBarH:ScrollTo(scrollBarH.ScrollIndex + scrollBarH.VisibleSpace)
			end
		else
			if scrollBar.VisibleSpace - 1 > wheelAmount then
				scrollBar:ScrollTo(scrollBar.ScrollIndex + wheelAmount)
			else
				scrollBar:ScrollTo(scrollBar.ScrollIndex + scrollBar.VisibleSpace)
			end
		end
	end)
end

scrollBar.VisibleSpace = math_ceil(MainFrame.AbsoluteSize.Y)
scrollBar:Update()

showSelectionData(GetSelection())

SelectionChanged_Bindable.Event:Connect(function() 
	showSelectionData(GetSelection())
end)

SetAwaiting_Bindable.Event:Connect(function(obj)
	if AwaitingObjectValue then
		AwaitingObjectValue = false
		local mySel = obj
		if mySel then
			pcall(Set, AwaitingObjectObj, AwaitingObjectProp, mySel)
		end
	end
end)

propertiesSearch:GetPropertyChangedSignal("Text"):Connect(function()
	showSelectionData(GetSelection())
end)

function GetApi_Bindable.OnInvoke()
	return RbxApi
end

function GetAwaiting_Bindable.OnInvoke()
	return AwaitingObjectValue
end
