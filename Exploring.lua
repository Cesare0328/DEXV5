-- < Fix for module threads not being supported since synapse x > --
local script = getgenv().Dex:WaitForChild("ExplorerPanel"):WaitForChild("Exploring")
-- < Aliases > --
local Instance_new = Instance.new
local UDim2_new = UDim2.new
local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local NumberRange_new = NumberRange.new
local Color3_new = Color3.new
local Color3_fromRGB = Color3.fromRGB
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local table_concat = table.concat
local table_clear = table.clear
local string_split = string.split
local string_find = string.find
local string_match = string.match
local string_lower = string.lower
local string_sub = string.sub
local string_byte = string.byte
local string_gsub = string.gsub
local string_rep = string.rep
local math_floor = math.floor
local math_ceil = math.ceil
local math_random = math.random
local math_huge = math.huge
-- < Services > --
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
-- < Class Aliases > --
local IsA = game.IsA
local ClearAllChildren = game.ClearAllChildren
local IsAncestorOf = game.IsAncestorOf
local WaitForChild = game.WaitForChild
local FindFirstChildOfClass = game.FindFirstChildOfClass
local GetPropertyChangedSignal = game.GetPropertyChangedSignal
local GetChildren = game.GetChildren
local GetDescendants = game.GetDescendants
local Clone = game.Clone
local Destroy = game.Destroy
local Wait, Connect, Disconnect = (function()
	local A = game.Changed
	local B = A.Connect
	local C = B(A, function()end)
	local D = C.Disconnect
	D(C)
	return A.Wait, B, D
end)()
-- < Bindables > --
local Bindables = WaitForChild(script.Parent.Parent, "Bindables", 300)
local GetSpecials_Bindable = WaitForChild(Bindables, "GetSpecials", 300)
local GetSetting_Bindable = WaitForChild(Bindables, "GetSetting", 300)
local GetOption_Bindable = WaitForChild(Bindables, "GetOption", 300)
local GetAwaiting_Bindable = WaitForChild(Bindables, "GetAwaiting", 300)
local GetSelection_Bindable = WaitForChild(Bindables, "GetSelection", 300)
local GetApi_Bindable = WaitForChild(Bindables, "GetApi", 300)
local GetPrint_Bindable = WaitForChild(Bindables, "GetPrint", 300)
local OpenScript_Bindable = WaitForChild(Bindables, "OpenScript", 300)
local SelectionChanged_Bindable = WaitForChild(Bindables, "SelectionChanged", 300)
local SetAwaiting_Bindable = WaitForChild(Bindables, "SetAwaiting", 300)
local SetOption_Bindable = WaitForChild(Bindables, "SetOption", 300)
local SetSelection_Bindable = WaitForChild(Bindables, "SetSelection", 300)
-- < Specials > --
local Specials = GetSpecials_Bindable:Invoke()
local checkrbxlocked = Specials.checkrbxlocked
-- < Upvalues > --
local Stepped = RunService.Stepped
local LocalPlayer = Players.LocalPlayer
local Searched = false
local ContextMenuHovered = false
local NilInstances = {}
local OriginalToClone = {}
local Mouse = LocalPlayer:GetMouse()
local Option = {
	Modifiable = true, -- can modify object parents in the hierarchy
	Selectable = true -- can select objects
}
local GUI_SIZE = 16 -- general size of GUI objects, in pixels
local ENTRY_PADDING, ENTRY_MARGIN = 1, 1 -- padding between items within each entry and padding between each entry
local explorerPanel = script.Parent
local Dex = explorerPanel.Parent
local HoldingCtrl, HoldingShift = false, false
-- < Custom Aliases > --
local getinstancelist = Specials.getinstancelist
local writeinstance = Specials.writeinstance
local fireclickdetector = Specials.fireclickdetector
local firetouchinterest = Specials.firetouchinterest
local fireproximityprompt = Specials.fireproximityprompt
local wait = task.wait
-- < Source > --
local DexOutput, DexOutputMain = Instance_new("Folder"), Instance_new("ScreenGui")
DexOutput.Name = "Output"
DexOutputMain.Name = "Dex Output"
DexOutputMain.Parent = DexOutput

local function print(...)
	local A = Instance_new("Dialog")
	for _,v in ipairs({...}) do
		A.Name = tostring(v) .. " "
	end
	A.Parent = DexOutputMain
end

GetPrint_Bindable.OnInvoke = function() 
	return print 
end

local ENTRY_SIZE = GUI_SIZE + ENTRY_PADDING * 2
local ENTRY_BOUND = ENTRY_SIZE + ENTRY_MARGIN
local HEADER_SIZE = ENTRY_SIZE * 2

local FONT = 'SourceSans'
local FONT_SIZE 

do
	local size,s,n = {8,9,10,11,12,14,18,24,36,48}, nil, math_huge
	for i = 1, #size do
		if size[i] <= GUI_SIZE then
			FONT_SIZE = i - 1
		end
	end
end

local GuiColor = {
	Background = Color3_fromRGB(37, 37, 42),
	Border = Color3_fromRGB(20, 20, 25),
	Selected = Color3_fromRGB(5, 100, 145),
	BorderSelected = Color3_fromRGB(2, 125, 145),
	Text = Color3_fromRGB(245, 245, 250),
	TextDisabled = Color3_fromRGB(190, 190, 195),
	TextSelected = Color3_fromRGB(255, 255, 255),
	Button = Color3_fromRGB(31, 31, 35),
	ButtonBorder = Color3_fromRGB(135, 135, 140),
	ButtonSelected = Color3_fromRGB(0, 170, 155),
	Field = Color3_fromRGB(37, 37, 42),
	FieldBorder = Color3_fromRGB(50, 50, 55),
	TitleBackground = Color3_fromRGB(10, 10, 15)
}
-- Icon map constants
local ActionTextures = {
	Copy = {"rbxasset://textures/TerrainTools/icon_regions_copy.png","rbxasset://textures/TerrainTools/icon_regions_copy.png"},
	Paste = {"rbxasset://textures/TerrainTools/icon_regions_paste.png","rbxasset://textures/TerrainTools/icon_regions_paste.png"},
	Delete = {"rbxasset://textures/TerrainTools/icon_regions_delete.png","rbxasset://textures/TerrainTools/icon_regions_delete.png"},
	Starred = {"rbxasset://textures/StudioToolbox/AssetPreview/star_filled.png","rbxasset://textures/StudioToolbox/AssetPreview/star_filled.png"},
	AddStar = {"rbxasset://textures/StudioToolbox/AssetPreview/star_stroke.png","rbxasset://textures/StudioToolbox/AssetPreview/star_stroke.png"}
}

local NodeTextures = {"rbxasset://textures/AnimationEditor/btn_expand.png", "rbxasset://textures/AnimationEditor/btn_collapse.png"}

local ExplorerIndex, ReflectionMetadata = {}, "https://raw.githubusercontent.com/Cesare0328/DEXV5/refs/heads/main/ReflectionMetadata.JSON"

for _, Metadata in ipairs(HttpService:JSONDecode(game:HttpGet(ReflectionMetadata, true)).roblox.Item[1].Item) do
	local Item = Metadata.Properties.string
	local ImageOrder = 0
	local ClassName = "Instance"
	for Category, Data in ipairs(Item) do
		if Data._name == "ExplorerImageIndex" then
			ImageOrder = tonumber(Data.__text)
		end
		if Data._name == "Name" then
			ClassName = Data.__text
		end
	end
	ExplorerIndex[ClassName] = ImageOrder
end

local function Create(p1, p2)
	local A = typeof(p1) == 'string' and Instance_new(p1) or p1
	for B, C in next, p2 do
		if typeof(B) == 'number' then
			C.Parent = A
		else
			A[B] = C
		end
	end
	return A
end

local barActive, activeOptions = false, {}

local function createDDown(dBut, callback, ...)
	if barActive then
		for _,v in ipairs(activeOptions) do
			Destroy(v)
		end
		table_clear(activeOptions)
		barActive = false
		return
	else
		barActive = true
	end
	local slots, base = {...}, dBut
	for i,v in ipairs(slots) do
		local newOption = Clone(base)
		newOption.ZIndex = 2
		newOption.Name = "Option " .. tostring(i)
		newOption.BackgroundTransparency = 0
		table_insert(activeOptions, newOption)
		newOption.Position = UDim2_new(-.4, dBut.Position.X.Offset, dBut.Position.Y.Scale, dBut.Position.Y.Offset + (#activeOptions * dBut.Size.Y.Offset))
		newOption.Text = slots[i]
		newOption.Parent = base.Parent.Parent.Parent
		Connect(newOption.MouseButton1Down, function()
			dBut.Text = slots[i]
			callback(slots[i])
			for _,v in ipairs(activeOptions) do
				Destroy(v)
			end
			table_clear(activeOptions)
			barActive = false
		end)
	end
end

local function EventConnect(event, func)
	return Connect(event, function(...)
		pcall(func, ...)
	end)
end

function GetScreen(screen)
	if screen == nil then return end
	while not IsA(screen, "ScreenGui") do
		screen = screen.Parent
		if screen == nil then return nil end
	end
	return screen
end

do
	local ZIndexLock = {}
	function SetZIndex(object,z)
		if not ZIndexLock[object] then
			ZIndexLock[object] = true
			if IsA(object, 'GuiObject') then
				object.ZIndex = z
			end
			local children = GetChildren(object)
			for i = 1,#children do
				SetZIndex(children[i],z)
			end
			ZIndexLock[object] = nil
		end
	end
	function SetZIndexOnChanged(object)
		return Connect(GetPropertyChangedSignal(object, "ZIndex"), function()
			SetZIndex(object, object.ZIndex)
		end)
	end
end

local Icon 
do
	local iconMap = 'rbxasset://textures/ClassImages.png'

	function Icon(IconFrame,index)
		local mapSize = Vector2_new(2352,16)
		local iconSize = 16
		local class = 'Frame'
		if typeof(IconFrame) == 'string' then
			class = IconFrame
			IconFrame = nil
		end
		if not IconFrame then
			IconFrame = Create(class,{
				Name = "IconFrame",
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Create('ImageLabel',{
					Name = "IconMap",
					Active = false,
					BackgroundTransparency = 1,
					Image = iconMap,
					Size = UDim2_new(0,iconSize,0,mapSize.Y)
				})
			})
		end
		local IconMap = WaitForChild(IconFrame, "IconMap", 300)
		IconMap.ImageRectOffset = Vector2_new(iconSize * index, 0)
		IconMap.ImageRectSize = Vector2_new(iconSize, iconSize)
		return IconFrame
	end
end

function SpecialIcon(IconFrame,texture,iconSize)
	local class = 'Frame'
	if typeof(IconFrame) == 'string' then
		class = IconFrame
		IconFrame = nil
	end
	if not IconFrame then
		IconFrame = Create(class,{
			Name = "IconFrame",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Create('ImageLabel',{
				Name = "SpecialIcon",
				Active = true,
				BackgroundTransparency = 1,
				Image = texture,
				Size = iconSize or UDim2_new(0,16,0,16)
			})
		})
	end
	return IconFrame
end

do
	local function ResetButtonColor(button)
		local active = button.Active
		button.Active = not active
		button.Active = active
	end

	local function ArrowGraphic(size,dir,scaled,template)
		local Frame = Create('Frame',{
			Name = "Arrow Graphic",
			BorderSizePixel = 0,
			Size = UDim2_new(0,size,0,size),
			Transparency = 1
		})

		if not template then
			template = Create('Frame',{
				BorderSizePixel = 0
			})
		end

		template.BackgroundColor3 = Color3_new(1, 1, 1)

		local transform
		if dir == nil or dir == 'Up' then
			function transform(p,s) return p,s end
		elseif dir == 'Down' then
			function transform(p,s) return UDim2_new(0,p.X.Offset,0,size-p.Y.Offset-1),s end
		elseif dir == 'Left' then
			function transform(p,s) return UDim2_new(0,p.Y.Offset,0,p.X.Offset),UDim2_new(0,s.Y.Offset,0,s.X.Offset) end
		elseif dir == 'Right' then
			function transform(p,s) return UDim2_new(0,size-p.Y.Offset-1,0,p.X.Offset),UDim2_new(0,s.Y.Offset,0,s.X.Offset) end
		end

		local scale
		if scaled then
			function scale(p,s) return UDim2_new(p.X.Offset/size,0,p.Y.Offset/size,0),UDim2_new(s.X.Offset/size,0,s.Y.Offset/size,0) end
		else
			function scale(p,s) return p,s end
		end

		local o = math_floor(size/4)
		if size%2 == 0 then
			local n = size/2-1
			for i = 0,n do
				local t = Clone(template)
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
				local t = Clone(template)
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
			local t = Clone(template)
			local p,s = scale(transform(
				UDim2_new(0,0,0,size-o-1),
				UDim2_new(0,size,0,1)
				))
			t.Position = p
			t.Size = s
			t.Parent = Frame
		end

		for _, v in ipairs(GetChildren(Frame)) do
			v.BackgroundColor3 = Color3_new(1, 1, 1)
		end

		return Frame
	end

	local function GripGraphic(size,dir,spacing,scaled,template)
		local Frame = Create('Frame',{
			Name = "Grip Graphic",
			BorderSizePixel = 0,
			Size = UDim2_new(0,size.X,0,size.Y),
			Transparency = 1
		})

		if not template then
			template = Create('Frame',{
				BorderSizePixel = 0
			})
		end

		spacing = spacing or 2

		local scale = function(p)
			return scaled and UDim2_new(p.X.Offset / size.X, 0, p.Y.Offset / size.Y, 0) or p
		end

		if dir == 'Vertical' then
			for i=0,size.X-1,spacing do
				local t = Clone(template)
				t.Size = scale(UDim2_new(0,1,0, size.Y))
				t.Position = scale(UDim2_new(0,i,0,0))
				t.Parent = Frame
			end
		elseif dir == nil or dir == 'Horizontal' then
			for i=0,size.Y-1,spacing do
				local t = Clone(template)
				t.Size = scale(UDim2_new(0,size.X,0,1))
				t.Position = scale(UDim2_new(0,0,0,i))
				t.Parent = Frame
			end
		end

		return Frame
	end

	function ScrollBar(horizontal)
		local drag

		local ScrollFrame = Create('Frame',{
			Name = "ScrollFrame",
			BorderSizePixel = 0,
			Position = horizontal and UDim2_new(0,0,1,-GUI_SIZE) or UDim2_new(1,-GUI_SIZE,0,0),
			Size = horizontal and UDim2_new(1,0,0,GUI_SIZE) or UDim2_new(0,GUI_SIZE,1,0),
			BackgroundTransparency = 1,
			Create('ImageButton',{
				Name = "ScrollDown",
				Position = horizontal and UDim2_new(1,-GUI_SIZE,0,0) or UDim2_new(0,0,1,-GUI_SIZE),
				Size = UDim2_new(0, GUI_SIZE, 0, GUI_SIZE),
				BackgroundColor3 = GuiColor.Button,
				BorderColor3 = GuiColor.Border
			}),
			Create('ImageButton',{
				Name = "ScrollUp",
				Size = UDim2_new(0, GUI_SIZE, 0, GUI_SIZE),
				BackgroundColor3 = GuiColor.Button,
				BorderColor3 = GuiColor.Border
			}),
			Create('ImageButton',{
				Name = "ScrollBar",
				Size = horizontal and UDim2_new(1,-GUI_SIZE*2,1,0) or UDim2_new(1,0,1,-GUI_SIZE*2),
				Position = horizontal and UDim2_new(0,GUI_SIZE,0,0) or UDim2_new(0,0,0,GUI_SIZE),
				AutoButtonColor = false,
				BackgroundColor3 = Color3_new(1/4, 1/4, 1/4),
				BorderColor3 = GuiColor.Border,
				Create('ImageButton',{
					Name = "ScrollThumb",
					AutoButtonColor = false,
					Size = UDim2_new(0, GUI_SIZE, 0, GUI_SIZE),
					BackgroundColor3 = GuiColor.Button,
					BorderColor3 = GuiColor.Border
				})
			})
		})

		local graphicTemplate = Create('Frame',{
			Name="Graphic",
			BorderSizePixel = 0,
			BackgroundColor3 = GuiColor.Border
		})
		local graphicSize = GUI_SIZE/2

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
			local size = GUI_SIZE*3/8
			local Decal = GripGraphic(Vector2_new(size,size),horizontal and 'Vertical' or 'Horizontal',2,graphicTemplate)
			Decal.Position = UDim2_new(.5,-size/2,.5,-size/2)
			Decal.Parent = ScrollThumbFrame
		end

		local Class = setmetatable({
			GUI = ScrollFrame,
			ScrollIndex = 0,
			VisibleSpace = 0,
			TotalSpace = 0,
			PageIncrement = 1
		},{
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
				CanScrollRight = function(self)
					return self.ScrollIndex + self.VisibleSpace < self.TotalSpace
				end,
				CanScrollLeft = function(self)
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
				ScrollRight = function(self)
					self.ScrollIndex += self.PageIncrement
					self:Update()
				end,
				ScrollLeft = function(self)
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
		})

		local UpdateScrollThumb
		if horizontal then
			function UpdateScrollThumb()
				ScrollThumbFrame.Size = UDim2_new(Class.VisibleSpace/Class.TotalSpace,0,0,GUI_SIZE)
				if ScrollThumbFrame.AbsoluteSize.X < GUI_SIZE then
					ScrollThumbFrame.Size = UDim2_new(0,GUI_SIZE,0,GUI_SIZE)
				end
				local barSize = ScrollBarFrame.AbsoluteSize.X
				ScrollThumbFrame.Position = UDim2_new(Class:GetScrollPercent()*(barSize - ScrollThumbFrame.AbsoluteSize.X)/barSize,0,0,0)
			end
		else
			function UpdateScrollThumb()
				ScrollThumbFrame.Size = UDim2_new(0,GUI_SIZE,Class.VisibleSpace/Class.TotalSpace,0)
				if ScrollThumbFrame.AbsoluteSize.Y < GUI_SIZE then
					ScrollThumbFrame.Size = UDim2_new(0,GUI_SIZE,0,GUI_SIZE)
				end
				local barSize = ScrollBarFrame.AbsoluteSize.Y
				ScrollThumbFrame.Position = UDim2_new(0,0,Class:GetScrollPercent()*(barSize - ScrollThumbFrame.AbsoluteSize.Y)/barSize,0)
			end
		end

		local lastDown, lastUp
		local scrollStyle = {BackgroundColor3=Color3_new(1, 1, 1),BackgroundTransparency=0}
		local scrollStyle_ds = {BackgroundColor3=Color3_new(1, 1, 1),BackgroundTransparency=.7}

		local function Update()
			local t, v, s = Class.TotalSpace, Class.VisibleSpace, Class.ScrollIndex
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

			local down = Class:CanScrollDown()
			local up = Class:CanScrollUp()
			if down ~= lastDown then
				lastDown = down
				ScrollDownFrame.Active = down
				ScrollDownFrame.AutoButtonColor = down
				local children = GetChildren(ScrollDownGraphic)
				local style = down and scrollStyle or scrollStyle_ds
				for i = 1,#children do
					Create(children[i],style)
				end
			end
			if up ~= lastUp then
				lastUp = up
				ScrollUpFrame.Active = up
				ScrollUpFrame.AutoButtonColor = up
				local children = GetChildren(ScrollUpGraphic)
				local style = up and scrollStyle or scrollStyle_ds
				for i = 1,#children do
					Create(children[i],style)
				end
			end
			ScrollThumbFrame.Visible = down or up
			UpdateScrollThumb()
		end
		Class.Update = Update

		SetZIndexOnChanged(ScrollFrame)

		local MouseDrag = Create('ImageButton',{
			Name = "MouseDrag",
			Position = UDim2_new(-.25,0,-.25,0),
			Size = UDim2_new(1.5,0,1.5,0),
			Transparency = 1,
			AutoButtonColor = false,
			Active = true,
			ZIndex = 10
		})

		local scrollEventID = 0
		Connect(ScrollDownFrame.MouseButton1Down, function()
			scrollEventID = tick()
			local current = scrollEventID
			local up_con
			up_con = Connect(MouseDrag.MouseButton1Up, function()
				scrollEventID = tick()
				MouseDrag.Parent = nil
				ResetButtonColor(ScrollDownFrame)
				Disconnect(up_con)
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

		Connect(ScrollDownFrame.MouseButton1Up, function()
			scrollEventID = tick()
		end)

		Connect(ScrollUpFrame.MouseButton1Down, function()
			scrollEventID = tick()
			local current = scrollEventID
			local up_con
			up_con = Connect(MouseDrag.MouseButton1Up, function()
				scrollEventID = tick()
				MouseDrag.Parent = nil
				ResetButtonColor(ScrollUpFrame)
				Disconnect(up_con)
				drag = nil
			end)
			MouseDrag.Parent = GetScreen(ScrollFrame)
			Class:ScrollUp()
			task.wait(.2)
			while scrollEventID == current do
				Class:ScrollUp()
				if not Class:CanScrollUp() then break end
				task.wait()
			end
		end)

		Connect(ScrollUpFrame.MouseButton1Up, function()
			scrollEventID = tick()
		end)

		if horizontal then
			Connect(ScrollBarFrame.MouseButton1Down, function(x,y)
				scrollEventID = tick()
				local current = scrollEventID
				local up_con
				up_con = Connect(MouseDrag.MouseButton1Up, function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollUpFrame)
					Disconnect(up_con)
					drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
				if x > ScrollThumbFrame.AbsolutePosition.X then
					Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if x < ScrollThumbFrame.AbsolutePosition.X + ScrollThumbFrame.AbsoluteSize.X then break end
						Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
						task.wait()
					end
				else
					Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if x > ScrollThumbFrame.AbsolutePosition.X then break end
						Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
						task.wait()
					end
				end
			end)
		else
			Connect(ScrollBarFrame.MouseButton1Down, function(x,y)
				scrollEventID = tick()
				local current = scrollEventID
				local up_con
				up_con = Connect(MouseDrag.MouseButton1Up, function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollUpFrame)
					Disconnect(up_con)
					drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
				if y > ScrollThumbFrame.AbsolutePosition.Y then
					Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if y < ScrollThumbFrame.AbsolutePosition.Y + ScrollThumbFrame.AbsoluteSize.Y then break end
						Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
						task.wait()
					end
				else
					Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
					task.wait(.2)
					while scrollEventID == current do
						if y > ScrollThumbFrame.AbsolutePosition.Y then break end
						Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
						task.wait()
					end
				end
			end)
		end

		if horizontal then
			Connect(ScrollThumbFrame.MouseButton1Down, function(x,y)
				scrollEventID = tick()
				local mouse_offset = x - ScrollThumbFrame.AbsolutePosition.X
				local drag_con
				local up_con
				drag_con = Connect(MouseDrag.MouseMoved, function(x,y)
					local bar_abs_pos = ScrollBarFrame.AbsolutePosition.X
					local bar_drag = ScrollBarFrame.AbsoluteSize.X - ScrollThumbFrame.AbsoluteSize.X
					local bar_abs_one = bar_abs_pos + bar_drag
					x -= mouse_offset
					x = x < bar_abs_pos and bar_abs_pos or x > bar_abs_one and bar_abs_one or x
					x -= bar_abs_pos
					Class:SetScrollPercent(x/(bar_drag))
				end)
				up_con = Connect(MouseDrag.MouseButton1Up, function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollThumbFrame)
					Disconnect(drag_con)
					drag_con = nil
					Disconnect(up_con)
					drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
			end)
		else
			Connect(ScrollThumbFrame.MouseButton1Down, function(x,y)
				scrollEventID = tick()
				local mouse_offset = y - ScrollThumbFrame.AbsolutePosition.Y
				local drag_con, up_con
				drag_con = Connect(MouseDrag.MouseMoved, function(x,y)
					local bar_abs_pos = ScrollBarFrame.AbsolutePosition.Y
					local bar_drag = ScrollBarFrame.AbsoluteSize.Y - ScrollThumbFrame.AbsoluteSize.Y
					local bar_abs_one = bar_abs_pos + bar_drag
					y -= mouse_offset
					y = y < bar_abs_pos and bar_abs_pos or y > bar_abs_one and bar_abs_one or y
					y -= bar_abs_pos
					Class:SetScrollPercent(y/(bar_drag))
				end)
				up_con = Connect(MouseDrag.MouseButton1Up, function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollThumbFrame)
					Disconnect(drag_con)
					drag_con = nil
					Disconnect(up_con)
					drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
			end)
		end

		function Class:Destroy()
			Destroy(ScrollFrame)
			Destroy(MouseDrag)
			for k in next, Class do
				Class[k] = nil
			end
			setmetatable(Class, nil)
		end
		Update()
		return Class
	end
end
----------------------------------------------------------------
Create(explorerPanel,{
	BackgroundColor3 = GuiColor.Field,
	BorderColor3 = GuiColor.Border,
	Active = true
})

local ConfirmationWindow = WaitForChild(Dex, "Confirmation")
local CautionWindow = WaitForChild(Dex, "Caution")
local TableCautionWindow = WaitForChild(Dex, "TableCaution")

local RemoteWindow = WaitForChild(Dex, "CallRemote")

local ScriptEditor = WaitForChild(Dex, "ScriptEditor")

local CurrentRemoteWindow

local lastSelectedNode

local RunningScriptsStorage, RunningScriptsStorageMain, RunningScriptsStorageEnabled

if getscripts then 
	RunningScriptsStorageEnabled = true 
end

if RunningScriptsStorageEnabled then
	RunningScriptsStorage = Create('Folder',{
		Name = "Dex Internal Storage",
	})
	RunningScriptsStorageMain = Create('Folder',{
		Name = "Running Scripts",
		Parent = RunningScriptsStorage
	})
	if not GetSetting_Bindable:Invoke("RSSIncludeRL") then
		for _, RunningScript in next, getscripts() do
			local runningScript
			RunningScript.Archivable = true
			runningScript = Clone(RunningScript)
			pcall(function()
				runningScript.Disabled = true
			end)
			runningScript.Parent = RunningScriptsStorageMain
		end
	else
		for _, Instance in next, getinstancelist() do
			if typeof(Instance) == "Instance" and IsA(Instance, "LuaSourceContainer") then
				Instance.Archivable = true
				local Script = Clone(Instance)
				pcall(function()
					Script.Disabled = true
				end)
				Script.Parent = RunningScriptsStorageMain
			end
		end
	end
end

local NilStorage, NilStorageMain, NilStorageEnabled

if getnilinstances then 
	NilStorageEnabled = true
end

if NilStorageEnabled then
	NilStorage = Create('Folder',{
		Name = "Dex Internal Storage",
	})
	NilStorageMain = Create('Folder',{
		Name = "Nil Instances",
		Parent = NilStorage
	})
	for _, v in next, getnilinstances() do
		local Cloned
		v.Archivable = true
		pcall(function()
			Cloned = Clone(v)
		    NilInstances[v] = Cloned
			OriginalToClone[Cloned] = v
			Cloned.Disabled = true
			Cloned.Parent = NilStorageMain
		end)
	end
end

local listFrame = Create('Frame',{
	Name = "List",
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Position = UDim2_new(0,0,0,HEADER_SIZE),
	Size = UDim2_new(1,-GUI_SIZE,1,-HEADER_SIZE),
	Parent = explorerPanel
})

local scrollBar = ScrollBar(false)
scrollBar.PageIncrement = 1
Create(scrollBar.GUI,{
	Position = UDim2_new(1,-GUI_SIZE,0,HEADER_SIZE),
	Size = UDim2_new(0,GUI_SIZE,1,-HEADER_SIZE),
	Parent = explorerPanel
})

local scrollBarH = ScrollBar(true)
scrollBarH.PageIncrement = GUI_SIZE
Create(scrollBarH.GUI,{
	Position = UDim2_new(0,0,1,-GUI_SIZE),
	Size = UDim2_new(1,-GUI_SIZE,0,GUI_SIZE),
	Visible = false,
	Parent = explorerPanel
})

local headerFrame = Create('Frame',{
	Name = "Header",
	BorderSizePixel = 0,
	BackgroundColor3 = GuiColor.Background,
	BorderColor3 = GuiColor.Border,
	Position = UDim2_new(),
	Size = UDim2_new(1,0,0,HEADER_SIZE),
	Parent = explorerPanel,
	Create('TextLabel',{
		Text = "Explorer",
		BackgroundTransparency = 1,
		TextColor3 = GuiColor.Text,
		TextXAlignment = 'Left',
		Font = FONT,
		FontSize = FONT_SIZE,
		Position = UDim2_new(0,4,0,0),
		Size = UDim2_new(1,-4,.5,0)
	})
})

local explorerFilter = 	Create('TextBox',{
	PlaceholderText = "Filter Instances",
	Text = "Filter Instances",
	BackgroundTransparency = .8,
	TextColor3 = GuiColor.Text,
	TextXAlignment = 'Left',
	Font = FONT,
	FontSize = FONT_SIZE,
	Position = UDim2_new(0,4,.5,0),
	Size = UDim2_new(1,-8,.5,-2)
})

explorerFilter.Parent = headerFrame

SetZIndexOnChanged(explorerPanel)

local Styles = {
	Font = Enum.Font.Arial,
	Margin = 5,
	Black = Color3_fromRGB(0,0,5),
	Black2 = Color3_fromRGB(24, 24, 29),
	White = Color3_fromRGB(244,244,249),
	WhiteOver = Color3_fromRGB(200,200,205),
	Hover = Color3_fromRGB(2, 128, 149),
	Hover2 = Color3_fromRGB(5, 102, 146)
}

local Row = {
	Font = Styles.Font,
	FontSize = Enum.FontSize.Size14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor = Styles.White,
	TextColorOver = Styles.WhiteOver,
	TextLockedColor = Color3_fromRGB(155,155,160),
	Height = 24,
	BorderColor = Color3_fromRGB(54,54,55),
	BackgroundColor = Styles.Black2,
	BackgroundColorAlternate = Color3_fromRGB(32, 32, 37),
	BackgroundColorMouseover = Color3_fromRGB(40, 40, 45),
	TitleMarginLeft = 15
}

local DropDown = {
	Font = Styles.Font,
	FontSize = Enum.FontSize.Size14,
	TextColor = Color3_fromRGB(255,255,260),
	TextColorOver = Row.TextColorOver,
	TextXAlignment = Enum.TextXAlignment.Left,
	Height = 20,
	BackColor = Styles.Black2,
	BackColorOver = Styles.Hover2,
	BorderColor = Color3_fromRGB(45,45,50),
	BorderSizePixel = 0,
	ArrowColor = Color3_fromRGB(80,80,83),
	ArrowColorOver = Styles.Hover
}

local BrickColors = {
	BoxSize = 13,
	BorderSizePixel = 0,
	BorderColor = Color3_fromRGB(53,53,55),
	FrameColor = Color3_fromRGB(53,53,55),
	Size = 20,
	Padding = 4,
	ColorsPerRow = 8,
	OuterBorder = 1,
	OuterBorderColor = Styles.Black
}

local currentRightClickMenu, CurrentInsertObjectWindow, CurrentFunctionCallerWindow, RbxApi

function IsCreatable(Class)
	local Class_Tags = Class.Tags
	if Class_Tags then
		for _, Tag in next, Class_Tags do
			if string_lower(Tag) == "notcreatable" then
				return false
			end
		end
	end
	return true
end

function IsAService(Class)
	local Class_Tags = Class.Tags
	if Class_Tags then
		for _, Tag in next, Class_Tags do
			if string_lower(Tag) == "service" then
				return true
			end
		end
	end
	return false
end

function GetClasses()
	if RbxApi == nil then return {} end
	local classTable = {}
	for _,Class in next, RbxApi.InstanceClasses do
		if IsCreatable(Class) and not IsAService(Class) then
			table_insert(classTable, Class.Name)
		end
	end
	return classTable
end

local function sortAlphabetic(t, property)
	table_sort(t, function(x,y) return x[property] < y[property] end)
end

function CreateInsertObjectMenu(choices, currentChoice, readOnly, onClick)
	local totalSize = Dex.AbsoluteSize.Y

	if #choices == 0 then 
		return
	end

	table_sort(choices, function(a,b) return a < b end)

	local frame = Create('Frame',{
		Name = "InsertObject",
		Size = UDim2_new(0, 200, 1, 0),
		BackgroundTransparency = 1,
		Active = true
	})

	local menu, arrow, expanded, margin = nil, nil, false, DropDown.BorderSizePixel

	local function hideMenu()
		expanded = false
		if frame then 
			CurrentInsertObjectWindow.Visible = false
		end
	end

	local function showMenu()
		expanded = true
		menu = Create('ScrollingFrame',{
			Size = UDim2_new(0, 200, 1, 0),
			CanvasSize = UDim2_new(0, 500, 0, #choices * DropDown.Height),
			Position = UDim2_new(0, margin, 0, 0),
			BackgroundTransparency = 0,
			BackgroundColor3 = DropDown.BackColor,
			BorderColor3 = DropDown.BorderColor,
			BorderSizePixel = DropDown.BorderSizePixel,
			TopImage = "rbxasset://textures/blackBkg_square.png",
			MidImage = "rbxasset://textures/blackBkg_square.png",
			BottomImage = "rbxasset://textures/blackBkg_square.png",
			Active = true,
			ZIndex = 5,
			Parent = frame
		})

		local function choice(name)
			onClick(name)
			hideMenu()
		end

		for i,name in next, choices do
			local option = CreateRightClickMenuItem(name, {}, function()
				choice(name)
			end,1)
			option.Size = UDim2_new(1, 0, 0, 20)
			option.Position = UDim2_new(0, 0, 0, (i - 1) * DropDown.Height)
			option.ZIndex = menu.ZIndex
			option.Parent = menu
		end
	end
	showMenu()
	return frame
end

function CreateInsertObject()
	if not CurrentInsertObjectWindow then return end
	CurrentInsertObjectWindow.Visible = true
	if currentRightClickMenu and CurrentInsertObjectWindow.Visible then
		CurrentInsertObjectWindow.Position = UDim2_new(0,currentRightClickMenu.Position.X.Offset-currentRightClickMenu.Size.X.Offset-2,0,0)
	end
	if CurrentInsertObjectWindow.Visible then
		CurrentInsertObjectWindow.Parent = Dex
	end
end

function GetCorrectIcon(Class)
	if typeof(Class) == "string" then
		if ExplorerIndex[Class] then
			return ExplorerIndex[Class]
		end
	elseif typeof(Class) == "Instance" then
		if ExplorerIndex[Class.ClassName] then
			return ExplorerIndex[Class.ClassName]
		end
		for ClassIndex, ImageIndex in next, ExplorerIndex do
			if IsA(Class, ClassIndex) then
				return ImageIndex
			end
		end
	end
	return 0
end

function CreateRightClickMenuItem(text, customizationData, onClick, insObj)
	local button = Create('TextButton',{
		Font = customizationData.Font or DropDown.Font,
		FontSize = customizationData.FontSize or DropDown.FontSize,
		TextColor3 = customizationData.TextColor or DropDown.TextColor,
		TextXAlignment = customizationData.TextXAlignment or DropDown.TextXAlignment,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Active = true,
		Text = text
	})

	if insObj == 1 then
		local newIcon = Icon(nil, GetCorrectIcon(text) or 0)
		newIcon.Position = UDim2_new(0,0,0,2)
		newIcon.Size = UDim2_new(0,GUI_SIZE,0,GUI_SIZE)
		newIcon.IconMap.ZIndex = 5
		newIcon.Parent = button
		button.Text = string_rep(" ", 4)..button.Text
	elseif insObj == 2 then
		button.FontSize = Enum.FontSize.Size11
	end

	Connect(button.MouseEnter, function()
		button.TextColor3 = DropDown.TextColorOver
		if not insObj and CurrentInsertObjectWindow then
			if CurrentInsertObjectWindow.Visible == false and button.Text == "Insert Object" then
				CreateInsertObject()
			elseif CurrentInsertObjectWindow.Visible and button.Text ~= "Insert Object" then
				CurrentInsertObjectWindow.Visible = false
			end
		end
	end)
	Connect(button.MouseLeave, function()
		button.TextColor3 = DropDown.TextColor
	end)
	Connect(button.Activated, function()
		button.TextColor3 = DropDown.TextColor
		onClick(text)
	end)	
	return button
end

function CreateRightClickMenu(choices, currentChoice, readOnly, onClick)
	local frame = Create('Frame',{
		Name = "DropDown",
		Size = UDim2_new(0, 200, 1, 0),
		BackgroundTransparency = 1,
		Active = true
	})

	local menu, arrow, expanded, margin = nil, nil, false, DropDown.BorderSizePixel

	local function hideMenu()
		expanded = false
		if frame then 
			Destroy(frame)
			DestroyRightClick()
		end
	end

	local function showMenu()
		expanded = true
		menu = Create('Frame',{
			Size = UDim2_new(0, 200, 0, #choices * DropDown.Height),
			Position = UDim2_new(0, margin, 0, 5),
			BackgroundTransparency = 0,
			BackgroundColor3 = DropDown.BackColor,
			BorderColor3 = DropDown.BorderColor,
			BorderSizePixel = DropDown.BorderSizePixel,
			Active = true,
			ZIndex = 5,
			Parent = frame
		})

		local UICorner = Create('UICorner',{
			Name = "",
			CornerRadius = UDim.new(0, 12),
			Parent = menu
		})

		local function choice(name)
			onClick(name)
			hideMenu()
		end

		for i,name in next, choices do
			local option = CreateRightClickMenuItem(name, {TextXAlignment = "Center"}, function()
				choice(name)
			end)
			option.Size = UDim2_new(1, 0, 0, 20)
			option.Position = UDim2_new(0, 0, 0, (i - 1) * DropDown.Height)
			option.ZIndex = menu.ZIndex
			option.Parent = menu
		end
	end
	frame.MouseEnter:Connect(function()
	    ContextMenuHovered = true
	end)
	frame.MouseLeave:Connect(function()
	    ContextMenuHovered = false
	end)
	showMenu()
	return frame
end

function checkMouseInGui(gui)
	if gui == nil then return false end
	local guiPosition, guiSize = gui.AbsolutePosition, gui.AbsoluteSize
	return ( Mouse.X >= guiPosition.X and Mouse.X <= guiPosition.X + guiSize.X and Mouse.Y >= guiPosition.Y and Mouse.Y <= guiPosition.Y + guiSize.Y) and true or false
end

local Clipboard = {}

local getTextWidth do
	local text = Create('TextLabel',{
		Name = "TextWidth",
		TextXAlignment = 'Left',
		TextYAlignment = 'Center',
		Font = FONT,
		FontSize = FONT_SIZE,
		Text = "",
		Position = UDim2_new(),
		Size = UDim2_new(1,0,1,0),
		Visible = false,
		Parent = explorerPanel
	})
	function getTextWidth(s)
		text.Text = s
		return text.TextBounds.X
	end
end

local nameScanned, TreeList, NodeLookup, QuickButtons, nodeWidth = false, {}, {}, {}, 0

function findObjectIndex(targetObject)
    for i = 1, #TreeList do
        if TreeList[i] and TreeList[i].Object == targetObject then
            return i
        end
    end
    return nil
end

function filteringInstances()
	return (explorerFilter.Text ~= "" and explorerFilter.Text ~= "Filter Instances") and true or false
end

function lookForAName(obj, name)
	for _,v in ipairs(GetChildren(obj)) do
		if string_find(string_lower(tostring(v)), string_lower(name)) then 
			nameScanned = true 
		end
		lookForAName(v, name)
	end
end

function scanName(obj)
	nameScanned = false
	if string_find(string_lower(obj.Name),string_lower(explorerFilter.Text)) then
		nameScanned = true
	else
		lookForAName(obj,explorerFilter.Text)
	end
	return nameScanned
end

function updateActions()
	for _,v in next, QuickButtons do
		v.Toggle(v.Cond() and true or false)
	end
end

local updateList,rawUpdateList,updateScroll,rawUpdateSize do
	local function r(t)
		for i = 1,#t do
			if not filteringInstances() or scanName(t[i].Object) then
				table_insert(TreeList, t[i])
				local w = (t[i].Depth)*(2+ENTRY_PADDING+GUI_SIZE) + 2 + ENTRY_SIZE + 4 + getTextWidth(t[i].Object.Name) + 4
				if w > nodeWidth then
					nodeWidth = w
				end
				if t[i].Expanded or filteringInstances() then
					r(t[i])
				end
			end
		end
	end

	function rawUpdateSize()
		scrollBarH.TotalSpace = nodeWidth
		scrollBarH.VisibleSpace = listFrame.AbsoluteSize.X
		scrollBarH:Update()
		local visible = scrollBarH:CanScrollDown() or scrollBarH:CanScrollUp()
		scrollBarH.GUI.Visible = visible

		listFrame.Size = UDim2_new(1,-GUI_SIZE,1,-GUI_SIZE*(visible and 1 or 0) - HEADER_SIZE)

		scrollBar.VisibleSpace = math_ceil(listFrame.AbsoluteSize.Y/ENTRY_BOUND)
		scrollBar.GUI.Size = UDim2_new(0,GUI_SIZE,1,-GUI_SIZE*(visible and 1 or 0) - HEADER_SIZE)

		scrollBar.TotalSpace = #TreeList+1
		scrollBar:Update()
	end

	function rawUpdateList()
		TreeList = {}
		nodeWidth = 0
		r(NodeLookup[workspace.Parent])
		r(NodeLookup[DexOutput])
		if NilStorageEnabled then
			r(NodeLookup[NilStorage])
		end
		if RunningScriptsStorageEnabled then
			r(NodeLookup[RunningScriptsStorage])
		end
		rawUpdateSize()
		updateActions()
	end

	local updatingList = false
	function updateList()
		if updatingList or filteringInstances() then return end
		updatingList = true
		task.defer(function()
			updatingList = false
			rawUpdateList()
		end)
	end

	local updatingScroll = false
	function updateScroll()
		if updatingScroll then return end
		updatingScroll = true
		task.defer(function()
			updatingScroll = false
			scrollBar:Update()
		end)
	end
end

local Selection 

do
	local SelectionList, SelectionSet, Updates = {}, {}, true

	Selection = {
		Selected = SelectionSet,
		List = SelectionList
	}

	local function addObject(object)
		local lupdate, supdate = false, false

		if not SelectionSet[object] then
			local node = NodeLookup[object]
			if node then
				table_insert(SelectionList,object)
				SelectionSet[object] = true
				node.Selected = true
				node = node.Parent
				while node do
					if not node.Expanded then
						node.Expanded = true
						lupdate = true
					end
					node = node.Parent
				end
				supdate = true
			end
		end
		return lupdate,supdate
	end

	function Selection:Set(objects)
		local lupdate, supdate = false, false

		if #SelectionList > 0 then
			for i = 1,#SelectionList do
				local object = SelectionList[i]
				local node = NodeLookup[object]
				if node then
					node.Selected = false
					SelectionSet[object] = nil
				end
			end

			SelectionList = {}
			Selection.List = SelectionList
			supdate = true
		end

		for i = 1,#objects do
			local l,s = addObject(objects[i])
			lupdate = l or lupdate
			supdate = s or supdate
		end

		if lupdate then
			rawUpdateList()
			supdate = true
		elseif supdate then
			scrollBar:Update()
		end

		if supdate then
			SelectionChanged_Bindable:Fire()
			updateActions()
		end
	end

	function Selection:Add(object)
		local l,s = addObject(object)
		if l then
			rawUpdateList()
			if Updates then
				SelectionChanged_Bindable:Fire()
				updateActions()
			end
		elseif s then
			scrollBar:Update()
			if Updates then
				SelectionChanged_Bindable:Fire()
				updateActions()
			end
		end
	end

	function Selection:StopUpdates()
		Updates = false
	end

	function Selection:ResumeUpdates()
		Updates = true
		SelectionChanged_Bindable:Fire()
		updateActions()
	end

	function Selection:Remove(object,noupdate)
		if SelectionSet[object] then
			local node = NodeLookup[object]
			if node then
				node.Selected = false
				SelectionSet[object] = nil
				for i = 1,#SelectionList do
					if SelectionList[i] == object then
						table_remove(SelectionList,i)
						break
					end
				end
				if not noupdate then
					scrollBar:Update()
				end
				SelectionChanged_Bindable:Fire()
				updateActions()
			end
		end
	end

	function Selection:Get()
		local list = {}
		for i = 1,#SelectionList do
			list[i] = SelectionList[i]
		end
		return list
	end

	SetSelection_Bindable.OnInvoke = function(...)
		Selection:Set(...)
	end

	GetSelection_Bindable.OnInvoke = function()
		return Selection:Get()
	end
end

function CreateCaution(title,msg)
	local newCaution = CautionWindow
	local MainWindow = newCaution.MainWindow
	newCaution.Visible = true
	newCaution.Title.Text = title
	MainWindow.Desc.Text = msg
	Connect(MainWindow.Ok.MouseButton1Up, function()
		newCaution.Visible = false
	end)
end

function CreateTableCaution(title,msg)
	if typeof(msg) ~= "table" then
		return CreateCaution(title, tostring(msg))
	end
	local newCaution = Clone(TableCautionWindow)
	newCaution.Title.Text = title
	local TableList = newCaution.MainWindow.TableResults
	local TableTemplate = newCaution.MainWindow.TableTemplate
	for _,v in next, msg do
		local newResult = Clone(TableTemplate)
		newResult.Type.Text = typeof(v)
		newResult.Value.Text = tostring(v)
		newResult.Position = UDim2_new(0,0,0, #GetChildren(TableList) * 20)
		newResult.Parent = TableList
		TableList.CanvasSize = UDim2_new(0,0,0, #GetChildren(TableList) * 20)
		newResult.Visible = true
	end
	newCaution.Parent = Dex
	newCaution.Visible = true
	Connect(newCaution.MainWindow.Ok.MouseButton1Up, function()
		Destroy(newCaution)
	end)
end

local function ToValue(value,type)
	if type == "Vector2" then
		local list = string_split(value,",")
		if #list < 2 then return nil end
		local x = tonumber(list[1]) or 0
		local y = tonumber(list[2]) or 0
		return Vector2_new(x,y)
	elseif type == "Vector3" then
		local list = string_split(value,",")
		if #list < 3 then return nil end
		local x = tonumber(list[1]) or 0
		local y = tonumber(list[2]) or 0
		local z = tonumber(list[3]) or 0
		return Vector3_new(x,y,z)
	elseif type == "Color3" then
		local list = string_split(value,",")
		if #list < 3 then return nil end
		local r = tonumber(list[1]) or 0
		local g = tonumber(list[2]) or 0
		local b = tonumber(list[3]) or 0
		return Color3_new(r/255,g/255, b/255)
	elseif type == "UDim2" then
		local list = string_split(string_gsub(string_gsub(value, "{", ""),"}",""),",")
		if #list < 4 then return nil end
		local xScale = tonumber(list[1]) or 0
		local xOffset = tonumber(list[2]) or 0
		local yScale = tonumber(list[3]) or 0
		local yOffset = tonumber(list[4]) or 0
		return UDim2_new(xScale, xOffset, yScale, yOffset)
	elseif type == "Number" then
		return tonumber(value)
	elseif type == "String" then
		return value
	elseif type == "NumberRange" then
		local list = string_split(value,",")
		if #list == 1 then
			if tonumber(list[1]) == nil then return nil end
			local newVal = tonumber(list[1]) or 0
			return NumberRange_new(newVal)
		end
		if #list < 2 then return nil end
		local x = tonumber(list[1]) or 0
		local y = tonumber(list[2]) or 0
		return NumberRange_new(x,y)
	else
		return nil
	end
end

local function ToPropValue(value,type)
	if type == "Vector2" then
		local list = string_split(value,",")
		if #list < 2 then return nil end
		local x = tonumber(list[1]) or 0
		local y = tonumber(list[2]) or 0
		return Vector2_new(x,y)
	elseif type == "Vector3" then
		local list = string_split(value,",")
		if #list < 3 then return nil end
		local x = tonumber(list[1]) or 0
		local y = tonumber(list[2]) or 0
		local z = tonumber(list[3]) or 0
		return Vector3_new(x,y,z)
	elseif type == "Color3" then
		local list = string_split(value,",")
		if #list < 3 then return nil end
		local r = tonumber(list[1]) or 0
		local g = tonumber(list[2]) or 0
		local b = tonumber(list[3]) or 0
		return Color3_new(r/255,g/255, b/255)
	elseif type == "UDim2" then
		local list = string_split(string_gsub(string_gsub(value, "{", ""),"}",""),",")
		if #list < 4 then return nil end
		local xScale = tonumber(list[1]) or 0
		local xOffset = tonumber(list[2]) or 0
		local yScale = tonumber(list[3]) or 0
		local yOffset = tonumber(list[4]) or 0
		return UDim2_new(xScale, xOffset, yScale, yOffset)
	elseif type == "Content" then
		return value
	elseif type == "float" or type == "int" or type == "double" then
		return tonumber(value)
	elseif type == "string" then
		return value
	elseif type == "NumberRange" then
		local list = string_split(value,",")
		if #list == 1 then
			if tonumber(list[1]) == nil then return nil end
			local newVal = tonumber(list[1]) or 0
			return NumberRange.new(newVal)
		end
		if #list < 2 then return nil end
		local x = tonumber(list[1]) or 0
		local y = tonumber(list[2]) or 0
		return NumberRange.new(x,y)
	elseif string_sub(value,1,4) == "Enum" then
		local getEnum = value
		while true do
			local x,y = string_find(getEnum,".")
			if y then
				getEnum = string_sub(getEnum,y+1)
			else
				break
			end
		end
		return getEnum
	else
		return nil
	end
end

function PromptRemoteCaller(inst)
	if CurrentRemoteWindow then
		Destroy(CurrentRemoteWindow)
		CurrentRemoteWindow = nil
	end
	CurrentRemoteWindow = Clone(RemoteWindow)
	CurrentRemoteWindow.Parent = Dex
	CurrentRemoteWindow.Visible = true

	local displayValues, ArgumentList, ArgumentTemplate = false, CurrentRemoteWindow.MainWindow.Arguments, CurrentRemoteWindow.MainWindow.ArgumentTemplate

	if IsA(inst, "RemoteEvent") then
		CurrentRemoteWindow.Title.Text = "Fire Event"
		CurrentRemoteWindow.MainWindow.Ok.Text = "Fire"
		CurrentRemoteWindow.MainWindow.DisplayReturned.Visible = false
		CurrentRemoteWindow.MainWindow.Desc2.Visible = false
	end

	local newArgument = Clone(ArgumentTemplate)
	newArgument.Parent = ArgumentList
	newArgument.Visible = true
	Connect(newArgument.Type.MouseButton1Down, function()
		createDDown(newArgument.Type, function(choice)
			newArgument.Type.Text = choice
		end,"Script","Number","String","Color3","Vector3","Vector2","UDim2","NumberRange")
	end)

	Connect(CurrentRemoteWindow.MainWindow.Ok.MouseButton1Up, function()
		if CurrentRemoteWindow and inst.Parent ~= nil then
			local MyArguments = {}
			for _,v in ipairs(GetChildren(ArgumentList)) do
				table_insert(MyArguments, ToValue(v.Value.Text,v.Type.Text))
			end
			if IsA(inst, "RemoteFunction") then
				if displayValues then
					pcall(function()
						local myResults = inst:InvokeServer(unpack(MyArguments))
						if myResults then
							CreateTableCaution("Remote Caller",myResults)
						else
							CreateCaution("Remote Caller","This remote didn't return anything.")
						end
					end)
				else
					pcall(function()
						inst:InvokeServer(unpack(MyArguments))
					end)
				end
			else
				inst:FireServer(unpack(MyArguments))
			end
			Destroy(CurrentRemoteWindow)
			CurrentRemoteWindow = nil
		end
	end)

	Connect(CurrentRemoteWindow.MainWindow.Add.MouseButton1Up, function()
		if CurrentRemoteWindow then
			local newArgument = Clone(ArgumentTemplate)
			newArgument.Position = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
			ArgumentList.CanvasSize = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
			newArgument.Visible = true
			newArgument.Parent = ArgumentList
			Connect(newArgument.Type.MouseButton1Down, function()
				createDDown(newArgument.Type,function(choice)
					newArgument.Type.Text = choice
				end,"Script","Number","String","Color3","Vector3","Vector2","UDim2","NumberRange")
			end)
		end
	end)

	Connect(CurrentRemoteWindow.MainWindow.Subtract.MouseButton1Up, function()
		if CurrentRemoteWindow then
			local A = GetChildren(ArgumentList)
			local B = #A
			if B > 1 then
				Destroy(A[B])
				ArgumentList.CanvasSize = UDim2_new(0, 0, 0, B * 20)
			end
		end
	end)

	Connect(CurrentRemoteWindow.MainWindow.Cancel.MouseButton1Up, function()
		if CurrentRemoteWindow then
			Destroy(CurrentRemoteWindow)
			CurrentRemoteWindow = nil
		end
	end)

	Connect(CurrentRemoteWindow.MainWindow.DisplayReturned.MouseButton1Up, function()
		if displayValues then
			displayValues = false
			CurrentRemoteWindow.MainWindow.DisplayReturned.enabled.Visible = false
		else
			displayValues = true
			CurrentRemoteWindow.MainWindow.DisplayReturned.enabled.Visible = true
		end
	end)
end

function DestroyRightClick()
	if currentRightClickMenu then
		Destroy(currentRightClickMenu)
		currentRightClickMenu = nil
	end
	if CurrentInsertObjectWindow and CurrentInsertObjectWindow.Visible then
		CurrentInsertObjectWindow.Visible = false
	end
end

local tabChar = string_rep(" ", 4)

local function getSmaller(a, b, notLast)
	local aByte = string_byte(a) or -1
	local bByte = string_byte(b) or -1
	if aByte == bByte then
		if notLast and #a == 1 and #b == 1 then
			return -1
		elseif #b == 1 then
			return false
		elseif #a == 1 then
			return true
		else
			return getSmaller(string_sub(a, 2), string_sub(b, 2), notLast)
		end
	else
		return aByte < bByte
	end
end

local function parseData(obj, numTabs, isKey, overflow, noTables, forceDict)
	local objType, objStr = typeof(obj), tostring(obj)
	if objType == "table" then
		if noTables then return objStr end
		local isCyclic, out, nextIndex, isDict, hasTables, data = overflow[obj], {}, 1, false, false, {}
		overflow[obj] = true

		for key, val in next, obj do
			if not hasTables and typeof(val) == "table" then
				hasTables = true
			end

			if not isDict and key ~= nextIndex then
				isDict = true
			else
				nextIndex += 1
			end

			table_insert(data, {key, val})
		end

		if isDict or hasTables or forceDict then
			table_insert(out, (isCyclic and "Cyclic " or "") .. "{")
			table_sort(data, function(a, b)
				local aType, bType = typeof(a[2]), typeof(b[2])
				if bType == "string" and aType ~= "string" then
					return false
				end
				local res = getSmaller(aType, bType, true)
				return (res == -1) and getSmaller(tostring(a[1]), tostring(b[1])) or res
			end)
			for i = 1, #data do
				local arr = data[i]
				local nowKey, nowVal = arr[1], arr[2]
				local parseKey, parseVal = parseData(nowKey, numTabs+1, true, overflow, isCyclic), parseData(nowVal, numTabs+1, false, overflow, isCyclic)
				if isDict then
					local nowValType, preStr, postStr = typeof(nowVal), "", ""
					if i > 1 and (nowValType == "table" or typeof(data[i-1][2]) ~= nowValType) then
						preStr = "\n"
					end
					if i < #data and nowValType == "table" and typeof(data[i+1][2]) ~= "table" and typeof(data[i+1][2]) == nowValType then
						postStr = "\n"
					end
					table_insert(out, preStr .. string_rep(tabChar, numTabs+1) .. parseKey .. " = " .. parseVal .. ";" .. postStr)
				else
					table_insert(out, string_rep(tabChar, numTabs+1) .. parseVal .. ";")
				end
			end
			table_insert(out, string_rep(tabChar, numTabs) .. "}")
		else
			local data2 = {}
			for i = 1, #data do
				local arr = data[i]
				local nowVal = arr[2]
				local parseVal = parseData(nowVal, 0, false, overflow, isCyclic)
				table_insert(data2, parseVal)
			end
			table_insert(out, "{" .. table_concat(data2, ", ") .. "}")
		end

		return table_concat(out, "\n")
	else
		local returnVal
		if (objType == "string" or objType == "Content") and (not isKey or tonumber(string_sub(obj, 1, 1))) then
			local retVal = '"' .. objStr .. '"'
			if isKey then
				retVal = "[" .. retVal .. "]"
			end
			returnVal = retVal
		elseif objType == "EnumItem" then
			returnVal = "Enum." .. tostring(obj.EnumType) .. "." .. obj.Name
		elseif objType == "Enum" then
			returnVal = "Enum." .. objStr
		elseif objType == "Instance" then
			returnVal = obj.Parent and obj:GetFullName() or obj.ClassName
		elseif objType == "CFrame" then
			returnVal = "CFrame.new(" .. objStr .. ")"
		elseif objType == "Vector3" then
			returnVal = "Vector3_new(" .. objStr .. ")"
		elseif objType == "Vector2" then
			returnVal = "Vector2_new(" .. objStr .. ")"
		elseif objType == "UDim2" then
			returnVal = "UDim2_new(" .. objStr:gsub("[{}]", "") .. ")"
		elseif objType == "BrickColor" then
			returnVal = "BrickColor.new(\"" .. objStr .. "\")"
		elseif objType == "Color3" then
			returnVal = "Color3_new(" .. objStr .. ")"
		elseif objType == "NumberRange" then
			returnVal = "NumberRange.new(" .. objStr:gsub("^%s*(.-)%s*$", "%1"):gsub(" ", ", ") .. ")"
		elseif objType == "PhysicalProperties" then
			returnVal = "PhysicalProperties.new(" .. objStr .. ")"
		else
			returnVal = objStr
		end
		return returnVal
	end
end

local function tableToString(t)
	local success, result = pcall(function()
		return parseData(t, 0, false, {}, nil, false)
	end)
	return success and result or 'error'
end

local function HasSpecial(str)
	return (string_match(str, "%c") or string_match(str, "%s") or string_match(str, "%p")) ~= nil
end

local function GetPath(Instance)
	local Obj, string, temp, error = Instance, {}, {}, false

	while Obj ~= game do
		if Obj == nil then
			error = true
			break
		end
		table_insert(temp, Obj.Parent == game and Obj.ClassName or tostring(Obj))
		Obj = Obj.Parent
	end

	table_insert(string, "game:GetService(\"" .. temp[#temp] .. "\")")

	for i = #temp - 1, 1, -1 do
		table_insert(string, HasSpecial(temp[i]) and "[\"" .. temp[i] .. "\"]" or "." .. temp[i])
	end

	return (error and "nil -- Path contained an invalid instance" or table_concat(string, ""))
end

local function canViewServerScript(scriptObj)
	local linkedSource = scriptObj.LinkedSource
	if linkedSource and #linkedSource >= 1 then
		local result = tonumber(string.match(linkedSource, "(%d+)"))
		if result then
			return true
		end
	end
	local sourceAssetId = tonumber(scriptObj.SourceAssetId)
	if sourceAssetId and sourceAssetId ~= -1 then
		return true
	end
	return false
end

function rightClickMenu(sObj)
	local actions = {
		'Cut',
		'Copy',
		'Paste Into',
		'Duplicate',
		'Delete',
		'Group',
		'Select Children',
		'Insert Part',
		'Insert Object',
		'Save to File',
		'Copy Path'
	}
	if sObj == RunningScriptsStorageMain or sObj == NilStorageMain then
		table_insert(actions, 1, "Refresh Instances")
	end
    if IsA(sObj, "RemoteEvent") or IsA(sObj, "RemoteFunction") then
		table_insert(actions, 10, "Call Remote")
	end
    if IsA(sObj, "BasePart") or IsA(sObj, "Model") or IsA(sObj, "Humanoid") or IsA(sObj, "Player") then
		table_insert(actions, 8, "Teleport to")
	end
    if filteringInstances() and Searched then
		table_insert(actions, 1, "Clear Search and Jump to")
	end
    if IsA(sObj, "ClickDetector") then
		table_insert(actions, 8, "Fire ClickDetector")
	elseif IsA(sObj, "TouchTransmitter") then
		table_insert(actions, 8, "Fire TouchTransmitter")
	elseif IsA(sObj, "ProximityPrompt") then
		table_insert(actions, 8, "Fire ProximityPrompt")
	end
    if IsA(sObj, "Model") then
		table_insert(actions, 7, "Ungroup")
	end
    if IsA(sObj, "LocalScript") or IsA(sObj, "ModuleScript") or (IsA(sObj, "Script") and canViewServerScript(sObj)) then
		table_insert(actions, 7, "View Script")
		table_insert(actions, 8, "Save Script")
	end

	currentRightClickMenu = CreateRightClickMenu(actions, "", false, function(option)
		if option == "Cut" then
			if not Option.Modifiable then
				return
			end
			local cut = {}
			for _, Selected in ipairs(Selection.List) do
				local obj = Clone(Selected)
				if obj then
					table_insert(Clipboard, obj)
					table_insert(cut, Selected)
				end
			end
			for _, CutInstance in next, cut do
				pcall(game.Destroy, CutInstance)
			end
			updateActions()
		elseif option == "Copy" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				table_insert(Clipboard, Clone(Selected))
			end
			updateActions()
		elseif option == "Paste Into" then
			if not Option.Modifiable then
				return
			end
			local parent = Selection.List[1] or workspace
			for _, Copied in next, Clipboard do
				if Copied.Archivable then
					Clone(Copied).Parent = parent
				end
			end
			table_clear(Clipboard)
		elseif option == "Duplicate" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				if Selected.Archivable then
					Clone(Selected).Parent = Selected.Parent or workspace
				end
			end
		elseif option == "Delete" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				pcall(game.Destroy, Selected)
			end
			Selection:Set({})
		elseif option == "Group" then
			if not Option.Modifiable then
				return
			end
			local A = Create("Model",{
				Parent = Selection.List[1].Parent or workspace
			})
			for B, C in ipairs(Selection:Get()) do
				C.Parent = A
			end
			Selection:Set({})
		elseif option == "Ungroup" then
			if not Option.Modifiable then
				return
			end
			local ungrouped = {}
			for _, Selected in ipairs(Selection:Get()) do
				for _, Selected_Instance in ipairs(GetChildren(Selected)) do
					Selected_Instance.Parent = Selected.Parent or workspace
					table_insert(ungrouped, Selected_Instance)
				end	
				pcall(game.Destroy, Selected)
			end
			Selection:Set({})
			if GetSetting_Bindable:Invoke("SelectUngrouped") then
				for _, v in next, ungrouped do
					Selection:Add(v)
				end
			end
		elseif option == "Select Children" then
			if not Option.Modifiable then
				return
			end
			Selection:StopUpdates()
			for _, Selected in ipairs(Selection:Get()) do
				Selection:Set({})
				for _, Selected_Instance in ipairs(GetChildren(Selected)) do
					Selection:Add(Selected_Instance)
				end
			end
			Selection:ResumeUpdates()
		elseif option == "Teleport to" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				if not Selected:IsDescendantOf(workspace) and not Selected:IsDescendantOf(Players) then break end
				if Selected:IsA("BasePart") then
				    pcall(function()
						LocalPlayer.Character:SetPrimaryPartCFrame(Selected.CFrame)
					    LocalPlayer.Character:MoveTo(Selected.Position)
				    end)
				elseif Selected:IsA("Model") then
                    pcall(function()
						LocalPlayer.Character:SetPrimaryPartCFrame(Selected:GetPivot())
					    LocalPlayer.Character:MoveTo(Selected:GetPivot().p)
				    end)
				elseif Selected:IsA("Humanoid") and Selected.RootPart then
                    pcall(function()
						LocalPlayer.Character:SetPrimaryPartCFrame(Selected.RootPart.CFrame)
					    LocalPlayer.Character:MoveTo(Selected.RootPart.Position)
				    end)
				elseif Selected:IsA("Player") and Selected.Character and Selected.Character.PrimaryPart then
                    pcall(function()
						LocalPlayer.Character:SetPrimaryPartCFrame(Selected.Character.PrimaryPart.CFrame)
					    LocalPlayer.Character:MoveTo(Selected.Character.PrimaryPart.Position)
				    end)
			    end
				break
			end
		elseif option == "Clear Search and Jump to" then
			explorerFilter.Text = ""
            rawUpdateList()
		    if #Selection:Get() == 1 then
			    local TargetIndex = findObjectIndex(Selection:Get()[1])
                local ScrollIndex = math.max(1, TargetIndex - math.floor(scrollBar.VisibleSpace / 2))
                scrollBar:ScrollTo(ScrollIndex)
		    end
		elseif option == "Insert Part" then
			if not Option.Modifiable then
				return
			end
			local insertedParts = {}
			for _, Selected in ipairs(Selection:Get()) do
				pcall(function()
					table_insert(insertedParts, Create('Part', {
						Position = LocalPlayer.Character.Head.Position + Vector3_new(0, 3, 0),
						Parent = Selected
					}))
				end)
			end
		elseif option == "Save to File" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				local Success, Saved_As = pcall(writeinstance, Selected, "rbxmx")
				if Success then
					CreateCaution(tabChar.."[writeinstance]: Success", "Instance '"..tostring(Selected)..[[' was saved to your workspace folder as "]]..Saved_As..[["! This file can now be inserted in Roblox Studio.]])
				else
					CreateCaution(tabChar.."[writeinstance]: Error", "\n"..Saved_As)
				end
			end
		elseif option == 'Copy Path' then
    		if not Option.Modifiable then
        		return
    		end
    		local path
    		local obj = Selection:Get()[1]
    		if not obj:IsDescendantOf(game) then
        		local ancestors = {}
        		local current = obj
        		while current do
            		table.insert(ancestors, 1, current.Name)
            		current = current.Parent
        		end
        		if ancestors[1] == "Dex Internal Storage" then
            		table.remove(ancestors, 1)
        		end
        		if ancestors[1] == "Nil Instances" then
            		table.remove(ancestors, 1)
        		end

        		if #ancestors > 0 then
            		local pathParts = {"getnilinstances()"}
            		for i = 1, #ancestors do
                		local name = ancestors[i]
						if name:match("^[%a_][%w_]*$") then
    						table.insert(pathParts, "." .. name)
						else
    						local escapedName = name:gsub('"', '\\"')
    						table.insert(pathParts, "[\"" .. escapedName .. "\"]")
						end
            		end
            		path = table.concat(pathParts, "")
        		else
            		path = "getnilinstances()"
        		end
			else
                local ancestors = {}
                local current = obj
                while current.Parent ~= game do
                    table.insert(ancestors, 1, current.Name)
                    current = current.Parent
                end
                
                local ServiceName = current.ClassName
                
                local pathParts = {string.format("game:GetService(\"%s\")", ServiceName)}
                for i = 1, #ancestors do
                    local name = ancestors[i]
                    if name:match("^[%a_][%w_]*$") then
                        table.insert(pathParts, "." .. name)
                    else
                        local escapedName = name:gsub('"', '\\"')
                        table.insert(pathParts, "[\"" .. escapedName .. "\"]")
                    end
                end
                
                path = table.concat(pathParts, "")
            end
        setclipboard(path)
		elseif option == "Call Remote" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				PromptRemoteCaller(Selected)
				break
			end
		elseif option == "Fire ClickDetector" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				fireclickdetector(Selected)
			end
		elseif option == "Fire TouchTransmitter" then
			if not Option.Modifiable then
				return
			end
			local A = Selection:Get()
			local B = A[1]
			local C = B.Parent
			local D = A[2]
			firetouchinterest(D, C, 0)
			firetouchinterest(D, C, 1)
		elseif option == "Fire ProximityPrompt" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				fireproximityprompt(Selected)
			end
		elseif option == "View Script" then
			if Option.Modifiable then
				for _, Selected in ipairs(Selection:Get()) do
					OpenScript_Bindable:Fire(Selected)
				end
			end
		elseif option == "Save Script" then
			if not Option.Modifiable then
				return
			end
			for _, Selected in ipairs(Selection:Get()) do
				writefile(game.PlaceId .. '_' ..string_gsub(Selected, "%W", "").. '_'..math_random(1e5, 1e9+1e9+1e8+1e7+1e7+1e7+1e7+1e6+1e6+1e6+1e6+1e6+1e6+1e6+1e5+1e5+1e5+1e5+1e4+1e4+1e4+1e4+1e4+1e4+1e4+1e4+1e3+1e3+1e3+1e2+1e2+1e2+1e2+1e2+1e2+1e1+1e1+1e1+1e1+7)..'.lua', decompile(Selected))
			end
		elseif option == 'Refresh Instances' then
    		ClearAllChildren(sObj)
    		if sObj == NilStorageMain then
        		for i, v in ipairs(getnilinstances()) do
            		if v ~= DexOutput and v ~= DexOutputMain and v ~= RunningScriptsStorage and v ~= RunningScriptsStorageMain and v ~= NilStorage and v ~= NilStorageMain and not OriginalToClone[v] then
                		v.Archivable = true
						pcall(function()
                    		local Cloned = Clone(v)
                    		NilInstances[Cloned] = v
							OriginalToClone[v] = Cloned
                    		Cloned.Parent = NilStorageMain
                		end)
            		end
        		end
			elseif sObj == RunningScriptsStorageMain then
				if not GetSetting_Bindable:Invoke("RSSIncludeRL") then
					for i,v in ipairs(getscripts()) do
						if v ~= RunningScriptsStorage then
							v.Archivable = true
							local ls = Clone(v)
							pcall(function()
								ls.Disabled = true
								ls.Parent = RunningScriptsStorageMain
							end)
						end
					end
				else
					for i,v in ipairs(getinstancelist()) do
						if typeof(v) == "Instance" and IsA(v, "LuaSourceContainer") then
							if v ~= RunningScriptsStorage then
								pcall(function()
									v.Archivable = true
									local Script = Clone(v)
									Script.Disabled = true
									Script.Parent = RunningScriptsStorageMain
								end)
							end
						end
					end
				end
			end
		end
	end)
	currentRightClickMenu.Parent = Dex
	currentRightClickMenu.Position = UDim2_new(0, Mouse.X,0, Mouse.Y)
	if currentRightClickMenu.AbsolutePosition.X + currentRightClickMenu.AbsoluteSize.X > explorerPanel.AbsolutePosition.X + explorerPanel.AbsoluteSize.X then
		currentRightClickMenu.Position = UDim2_new(0, explorerPanel.AbsolutePosition.X + explorerPanel.AbsoluteSize.X - currentRightClickMenu.AbsoluteSize.X, 0, Mouse.Y)
	end
end

local function cancelReparentDrag()
end

local function cancelSelectDrag()
end

do
	local listEntries, nameConnLookup = {}, {}

	local mouseDrag = Create('ImageButton',{
		Name = "MouseDrag",
		Position = UDim2_new(-.25,0,-.25,0),
		Size = UDim2_new(1.5,0,1.5,0),
		Transparency = 1,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 10
	})

	local function dragSelect(last,add,button)
		local conDrag, conUp

		conDrag = Connect(mouseDrag.MouseMoved, function(x,y)
			local pos, size = Vector2_new(x,y) - listFrame.AbsolutePosition, listFrame.AbsoluteSize
			if pos.X < 0 or pos.X > size.X or pos.Y < 0 or pos.Y > size.Y then return end

			local i = math_floor(pos.Y/ENTRY_BOUND) - 2 + scrollBar.ScrollIndex
			for n = i<last and i or last, i>last and i or last do
				local node = TreeList[n]
				if node then
					if add then
						Selection:Add(node.Object)
					else
						Selection:Remove(node.Object)
					end
				end
			end
			last = i
		end)

		function cancelSelectDrag()
			mouseDrag.Parent = nil
			Disconnect(conDrag)
			Disconnect(conUp)
			function cancelSelectDrag() end
		end

		conUp = Connect(mouseDrag[button], cancelSelectDrag)

		mouseDrag.Parent = GetScreen(listFrame)
	end

	local function dragReparent(object,dragGhost,clickPos,ghostOffset)
		local conDrag, conUp, conUp2, parentIndex
		local dragged = false
		local parentHighlight = Create('Frame',{
			Transparency = 1,
			Visible = false,
			Create('Frame',{
				BorderSizePixel = 0,
				BackgroundColor3 = Color3_new(0.95, 0.95, 0.95),
				BackgroundTransparency = .3,
				Position = UDim2_new(),
				Size = UDim2_new(1,0,0,1)
			}),
			Create('Frame',{
				BorderSizePixel = 0,
				BackgroundColor3 = Color3_new(0.95, 0.95, 0.95),
				BackgroundTransparency = .3,
				Position = UDim2_new(1,0,0,0),
				Size = UDim2_new(0,1,1,0)
			}),
			Create('Frame',{
				BorderSizePixel = 0,
				BackgroundColor3 = Color3_new(0.95, 0.95, 0.95),
				BackgroundTransparency = .3,
				Position = UDim2_new(0,0,1,0),
				Size = UDim2_new(1,0,0,1)
			}),
			Create('Frame',{
				BorderSizePixel = 0,
				BackgroundColor3 = Color3_new(0.95, 0.95, 0.95),
				BackgroundTransparency = .3,
				Position = UDim2_new(),
				Size = UDim2_new(0,1,1,0)
			}),
		})
		SetZIndex(parentHighlight,9)
		conDrag = Connect(mouseDrag.MouseMoved, function(x,y)
			local dragPos = Vector2_new(x,y)
			if dragged then
				local pos,size = dragPos - listFrame.AbsolutePosition,listFrame.AbsoluteSize
				parentIndex = nil
				parentHighlight.Visible = false
				if pos.X >= -5 and pos.X <= size.X + 5 and pos.Y >= 0 and pos.Y <= size.Y + ENTRY_SIZE*2 then
					local i = math_floor(pos.Y/ENTRY_BOUND) - 2
					local actualIndex = i + scrollBar.ScrollIndex
					local node = TreeList[actualIndex]
					if node and node.Object ~= object and not IsAncestorOf(object, node.Object) then
						local isDraggedObject = false
						if Option.Selectable then
							local selectedList = Selection.List
							for j = 1, #selectedList do
								if selectedList[j] == node.Object then
									isDraggedObject = true
									break
								end
							end
						else
							isDraggedObject = (node.Object == object)
						end
						
						if not isDraggedObject then
							parentIndex = i
							local entry = listEntries[i]
							if entry then
								parentHighlight.Visible = true
								local entryRelativeY = entry.AbsolutePosition.Y - listFrame.AbsolutePosition.Y
								parentHighlight.Position = UDim2_new(0,1,0,entryRelativeY)
								parentHighlight.Size = UDim2_new(0,size.X-4,0,entry.AbsoluteSize.Y)
							end
						end
					end
				end
				dragGhost.Position = UDim2_new(0,dragPos.X+ghostOffset.X,0,dragPos.Y+ghostOffset.Y)
			elseif (clickPos-dragPos).Magnitude > 6 then
				dragged = true
				SetZIndex(dragGhost,9)
				dragGhost.IndentFrame.Transparency = .25
				dragGhost.IndentFrame.EntryText.TextColor3 = GuiColor.TextSelected
				dragGhost.Position = UDim2_new(0,dragPos.X+ghostOffset.X,0,dragPos.Y+ghostOffset.Y)
				dragGhost.Parent = GetScreen(listFrame)
				parentHighlight.Parent = listFrame
			end
		end)

		function cancelReparentDrag()
			mouseDrag.Parent = nil
			Disconnect(conDrag)
			Disconnect(conUp)
			Disconnect(conUp2)
			Destroy(dragGhost)
			Destroy(parentHighlight)
			function cancelReparentDrag() end
		end

		local wasSelected = Selection.Selected[object]

		if not wasSelected and Option.Selectable then 
			Selection:Set({object}) 
		end

		conUp = Connect(mouseDrag.MouseButton1Up, function()
			cancelReparentDrag()
			if dragged then
				if parentIndex then
					local actualParentIndex = parentIndex + scrollBar.ScrollIndex
					local parentNode = TreeList[actualParentIndex]
					if parentNode then
						local parentObj = parentNode.Object
						local function parent(a,b)
							a.Parent = b
						end
						if Option.Selectable then
    						local list = Selection.List
    						for i = 1,#list do
								if not checkrbxlocked(list[i]) or (NilInstances[list[i]] and not checkrbxlocked(NilInstances[list[i]])) then
        							list[i].Parent = parentObj --here
        							if NilInstances[list[i]] then
           								NilInstances[list[i]].Parent = NilInstances[parentObj] or parentObj --here
        							end
								parentNode.Expanded = true
								end
    						end
						else
							if not checkrbxlocked(object) or (NilInstances[object] and not checkrbxlocked(NilInstances[object])) then
    							object.Parent = parentObj
    							if NilInstances[object] then
        							NilInstances[object].Parent = NilInstances[parentObj] or parentObj
    							end
							parentNode.Expanded = true
							end
						end
						rawUpdateList()
					end
				end
			else
				if not wasSelected and Option.Selectable then 
					Selection:Set({object})
				elseif wasSelected then
					Selection:Set({})
				end
			end
			cancelReparentDrag()
		end)
		conUp2 = Connect(mouseDrag.MouseButton2Down, function()
			cancelReparentDrag()
		end)
		mouseDrag.Parent = GetScreen(listFrame)
	end

	local entryTemplate = Create('ImageButton',{
		Name = "Entry",
		Transparency = 1,
		AutoButtonColor = false,
		Position = UDim2_new(),
		Size = UDim2_new(1,0,0,ENTRY_SIZE),
		Create('Frame',{
			Name = "IndentFrame",
			BackgroundTransparency = 1,
			BackgroundColor3 = GuiColor.Selected,
			BorderColor3 = GuiColor.BorderSelected,
			Position = UDim2_new(),
			Size = UDim2_new(1,0,1,0),
			Create(SpecialIcon('ImageButton',NodeTextures[1],UDim2_new(0,9,0,5)),{
				Name = "Expand",
				AutoButtonColor = false,
				Position = UDim2_new(0,-9,.5,-8/2),
				Size = UDim2_new(0,16,0,16)
			}),
			Create(Icon(nil,0),{
				Name = "ExplorerIcon",
				Position = UDim2_new(0,2+ENTRY_PADDING,.5,-GUI_SIZE/2),
				Size = UDim2_new(0,GUI_SIZE,0,GUI_SIZE)
			}),
			Create('TextLabel',{
				Name = "EntryText",
				BackgroundTransparency = 1,
				TextColor3 = GuiColor.Text,
				TextXAlignment = 'Left',
				TextYAlignment = 'Center',
				Font = FONT,
				FontSize = FONT_SIZE,
				Text = "",
				Position = UDim2_new(0,2+ENTRY_SIZE+4,0,0),
				Size = UDim2_new(1,-2,1,0)
			})
		})
	})

	function scrollBar.UpdateCallback(self)
		for i = 1,self.VisibleSpace do
			local node = TreeList[i + self.ScrollIndex]
			if node then
				local entry = listEntries[i]
				local curSelect
				if not entry then
					entry = Create(Clone(entryTemplate), {
						Position = UDim2_new(0,2,0,ENTRY_BOUND*(i-1)+2),
						Size = UDim2_new(0,nodeWidth,0,ENTRY_SIZE),
						ZIndex = listFrame.ZIndex
					})
					listEntries[i] = entry
					local expand = entry.IndentFrame.Expand
					Connect(expand.MouseEnter, function()
						local node = TreeList[i + self.ScrollIndex]
						if #node > 0 then
							if node.Expanded then
								FindFirstChildOfClass(expand, "ImageLabel").Image = NodeTextures[2]
							else
								FindFirstChildOfClass(expand, "ImageLabel").Image = NodeTextures[1]
							end
						end
					end)
					Connect(expand.MouseLeave, function()
						local node = TreeList[i + self.ScrollIndex]
						if #node > 0 then
							if node.Expanded then
								FindFirstChildOfClass(expand, "ImageLabel").Image = NodeTextures[2]
							else
								FindFirstChildOfClass(expand, "ImageLabel").Image = NodeTextures[1]
							end
						end
					end)
					Connect(expand.MouseButton1Down, function()
						local node = TreeList[i + self.ScrollIndex]
						if #node > 0 then
							node.Expanded = not node.Expanded
							if node.Object == Dex and node.Expanded then
								CreateCaution(tabChar.."Warning","Please be careful when editing instances inside here, this is like the System32 of Dex and modifying objects here can break Dex.")
							end
							rawUpdateList()
						end
					end)
					Connect(entry.MouseButton1Down, function(x,y)
						local node = TreeList[i + self.ScrollIndex]
						DestroyRightClick()
						if GetAwaiting_Bindable:Invoke() then
							SetAwaiting_Bindable:Fire(node.Object)
							return
						end
						if not HoldingShift then
							lastSelectedNode = i + self.ScrollIndex
						end
						if HoldingShift and not filteringInstances() then
							if lastSelectedNode then
								if i + self.ScrollIndex - lastSelectedNode > 0 then
									Selection:StopUpdates()
									for i2 = 1, i + self.ScrollIndex - lastSelectedNode do
										local newNode = TreeList[lastSelectedNode + i2]
										if newNode then
											Selection:Add(newNode.Object)
										end
									end
									Selection:ResumeUpdates()
								else
									Selection:StopUpdates()
									for i2 = i + self.ScrollIndex - lastSelectedNode, 1 do
										local newNode = TreeList[lastSelectedNode + i2]
										if newNode then
											Selection:Add(newNode.Object)
										end
									end
									Selection:ResumeUpdates()
								end
							end
							return
						end
						if HoldingCtrl then
							if Selection.Selected[node.Object] then
								Selection:Remove(node.Object)
							else
								Selection:Add(node.Object)
							end
							return
						end
						if Option.Modifiable then
							local pos = Vector2_new(x,y)
							dragReparent(node.Object, Clone(entry), pos, entry.AbsolutePosition - pos)
						elseif Option.Selectable then
							if Selection.Selected[node.Object] then
								Selection:Set({})
							else
								Selection:Set({node.Object})
							end
							dragSelect(i+self.ScrollIndex,true,'MouseButton1Up')
						end
					end)
					Connect(entry.MouseButton2Down, function()
						if not Option.Selectable then return end
						DestroyRightClick()
						curSelect = entry
						local node = TreeList[i + self.ScrollIndex]
						if GetAwaiting_Bindable:Invoke() then
							SetAwaiting_Bindable:Fire(node.Object)
							return
						end
						if not Selection.Selected[node.Object] then
							Selection:Set({node.Object})
						end
					end)
					Connect(entry.MouseButton2Up, function()
						if not Option.Selectable then return end
						local node = TreeList[i + self.ScrollIndex]
						if checkMouseInGui(curSelect) then
							rightClickMenu(node.Object)
						end
					end)
					entry.Parent = listFrame
				end

				entry.Visible = true

				local object = node.Object

				if #node == 0 then
					entry.IndentFrame.Expand.Visible = false
				elseif node.Expanded then
					FindFirstChildOfClass(entry.IndentFrame.Expand, "ImageLabel").Image = NodeTextures[2]
					entry.IndentFrame.Expand.Visible = true
				else
					FindFirstChildOfClass(entry.IndentFrame.Expand, "ImageLabel").Image = NodeTextures[1]
					entry.IndentFrame.Expand.Visible = true
				end

				Icon(entry.IndentFrame.ExplorerIcon, GetCorrectIcon(object) or 0)

				local w = (node.Depth)*(2+ENTRY_PADDING+GUI_SIZE)
				entry.IndentFrame.Position = UDim2_new(0,w,0,0)
				entry.IndentFrame.Size = UDim2_new(1,-w,1,0)

				if nameConnLookup[entry] then
					Disconnect(nameConnLookup[entry])
				end

				local text = entry.IndentFrame.EntryText
				text.Text = tostring(object)
				nameConnLookup[entry] = Connect(GetPropertyChangedSignal(node.Object, "Name"), function()
					text.Text = tostring(object)
				end)

				entry.IndentFrame.Transparency = node.Selected and 0 or 1
				text.TextColor3 = GuiColor[node.Selected and 'TextSelected' or 'Text']

				entry.Size = UDim2_new(0,nodeWidth,0,ENTRY_SIZE)
			elseif listEntries[i] then
				listEntries[i].Visible = false
			end
		end
		for i = self.VisibleSpace+1,self.TotalSpace do
			local entry = listEntries[i]
			if entry then
				listEntries[i] = nil
				Destroy(entry)
			end
		end
	end

	function scrollBarH.UpdateCallback(self)
		for A = 1, scrollBar.VisibleSpace do
			local B = TreeList[A + scrollBar.ScrollIndex]
			if B then
				local C = listEntries[A]
				if C then
					C.Position = UDim2_new(0, 2 - scrollBarH.ScrollIndex, 0, ENTRY_BOUND * (A - 1) + 2)
				end
			end
		end
	end

	Connect(GetPropertyChangedSignal(listFrame, "AbsoluteSize"), rawUpdateSize)

	local wheelAmount = 6

	Connect(explorerPanel.MouseWheelForward, function()
		scrollBar:ScrollTo((scrollBar.VisibleSpace - 1 > wheelAmount) and scrollBar.ScrollIndex - wheelAmount or scrollBar.ScrollIndex - scrollBar.VisibleSpace)
	end)

	Connect(explorerPanel.MouseWheelBackward, function()
		scrollBar:ScrollTo((scrollBar.VisibleSpace - 1 > wheelAmount) and scrollBar.ScrollIndex + wheelAmount or scrollBar.ScrollIndex + scrollBar.VisibleSpace)
	end)
end
----------------------------------------------------------------
local function insert(t,i,v)
	for n = #t,i,-1 do
		local v = t[n]
		v.Index = n+1
		t[n+1] = v
	end
	v.Index = i
	t[i] = v
end

local function remove(t,i)
	local v = t[i]
	for n = i+1,#t do
		local v = t[n]
		v.Index = n-1
		t[n-1] = v
	end
	t[#t] = nil
	v.Index = 0
	return v
end

local function depth(o)
	local d = -1
	while o do
		o = o.Parent
		d += 1
	end
	return d
end

local connLookup = {}

local function nodeIsVisible(node)
	local visible = true
	node = node.Parent
	while node and visible do
		visible = visible and node.Expanded
		node = node.Parent
	end
	return visible
end

local function removeObject(object)
	local objectNode = NodeLookup[object]

	if not objectNode then
		return
	end

	local visible = nodeIsVisible(objectNode)

	Selection:Remove(object, true)

	local parent = objectNode.Parent
	remove(parent, objectNode.Index)
	NodeLookup[object] = nil
	Disconnect(connLookup[object])
	connLookup[object] = nil

	if visible then
		updateList()
	elseif nodeIsVisible(parent) then
		updateScroll()
	end
end

local function moveObject(object,parent)
	local objectNode = NodeLookup[object]
	local parentNode = NodeLookup[parent]

	if not objectNode or not parentNode then
		return
	end

	local visible = nodeIsVisible(objectNode)

	local parent = objectNode.Parent
	remove(parent, objectNode.Index)
	objectNode.Parent = parentNode

	objectNode.Depth = depth(object)

	local function r(node,d)
		for i = 1,#node do
			node[i].Depth = d
			r(node[i],d+1)
		end
	end

	r(objectNode, objectNode.Depth + 1)

	insert(parentNode, #parentNode+1, objectNode)

	if visible or nodeIsVisible(objectNode) then
		updateList()
	elseif nodeIsVisible(parent) then
		updateScroll()
	end
end

local InstanceBlacklist = GetSetting_Bindable:Invoke("UseInstanceBlacklist") and {
	['Instance'] = true,
	['VRService'] = true,
	['ContextActionService'] = true,
	['CorePackages'] = true,
	['AssetService'] = true,
	['TouchInputService'] = true,
	['ScriptContext'] = true,
	['FilteredSelection'] = true,
	['MeshContentProvider'] = true,
	['SolidModelContentProvider'] = true,
	['AnalyticsService'] = true,
	['GamepadService'] = true,
	['HapticService'] = true,
	['ChangeHistoryService'] = true,
	['Visit'] = true,
	['SocialService'] = true,
	['SpawnerService'] = true,
	['FriendService'] = true,
	['Geometry'] = true,
	['BadgeService'] = true,
	['PhysicsService'] = true,
	['PluginDebugService'] = true,
	['PluginGuiService'] = true,
	['RobloxPluginGuiService'] = true,
	['CollectionService'] = true,
	['HttpRbxApiService'] = true,
	['TweenService'] = true,
	['TextService'] = true,
	['NotificationService'] = true,
	['AdService'] = true,
	['CSGDictionaryService'] = true,
	['ControllerService'] = true,
	['RuntimeScriptService'] = true,
	['ScriptService'] = true,
	['MouseService'] = true,
	['KeyboardService'] = true,
	['CookiesService'] = true,
	['TimerService'] = true,
	['GamePassService'] = true,
	['KeyframeSequenceProvider'] = true,
	['NonReplicatedCSGDictionaryService'] = true,
	['GuidRegistryService'] = true,
	['PathfindingService'] = true,
	['GroupService'] = true
} or {}

local function check(object)
	return object.AncestryChanged
end

local function addObject(object,noupdate)
	if object.Parent == game and InstanceBlacklist[object.ClassName] or object.ClassName == '' then
		return
	end

	if object.Name == "Instance" and object.Parent == game and object.className and GetSetting_Bindable:Invoke("UseRealclassName") then
		object.Name = object.className
	end
	
	if script then
		local s = pcall(check, object)
		if not s then return end
	end

	local parentNode = NodeLookup[object.Parent]
	if not parentNode then return end

	local objectNode = {
		Object = object,
		Parent = parentNode,
		Index = 0,
		Expanded = false,
		Selected = false,
		Depth = depth(object)
	}

	connLookup[object] = EventConnect(object.AncestryChanged,function(c, p)
		if c == object then
			if not p then
				removeObject(c)
			else
				moveObject(c,p)
			end
		end
	end)

	NodeLookup[object] = objectNode
	insert(parentNode, #parentNode + 1, objectNode)

	if not noupdate then
		if nodeIsVisible(objectNode) then
			updateList()
		elseif nodeIsVisible(objectNode.Parent) then
			updateScroll()
		end
	end
end

local function makeObject(obj,par)
	local newObject = Instance_new(obj.ClassName)
	for i,v in next, obj.Properties do
		pcall(function()
			newObject[tostring(v)] = ToPropValue(v.Value, v.Type)
		end)
	end
	newObject.Parent = par
end

local function writeObject(obj)
	local newObject = {ClassName = obj.ClassName, Properties = {}}
	for i,v in next, RbxApi.GetProperties(obj.className) do
		if v["Name"] ~= "Parent" then
			table_insert(newObject.Properties,{Name = v["Name"], Type = v["ValueType"], Value = tostring(obj[v["Name"]])})
		end
	end
	return newObject
end

do
	NodeLookup[workspace.Parent] = {
		Object = workspace.Parent,
		Parent = nil,
		Index = 0,
		Expanded = true
	}

	NodeLookup[DexOutput] = {
		Object = DexOutput,
		Parent = nil,
		Index = 0,
		Expanded = true
	}

	if NilStorageEnabled then
		NodeLookup[NilStorage] = {
			Object = NilStorage,
			Parent = nil,
			Index = 0,
			Expanded = true
		}
	end

	if RunningScriptsStorageEnabled then
		NodeLookup[RunningScriptsStorage] = {
			Object = RunningScriptsStorage,
			Parent = nil,
			Index = 0,
			Expanded = true
		}
	end

	Connect(game.DescendantAdded, addObject)
	Connect(game.DescendantRemoving, removeObject)
	Connect(DexOutput.DescendantAdded, addObject)
	Connect(DexOutput.DescendantRemoving, removeObject)

	if NilStorageEnabled then
		Connect(NilStorage.DescendantAdded,addObject)
		Connect(NilStorage.DescendantRemoving,removeObject)
	end
	if RunningScriptsStorageEnabled then
		Connect(RunningScriptsStorage.DescendantAdded,addObject)
		Connect(RunningScriptsStorage.DescendantRemoving,removeObject)
	end
	local function ApplyDescendants(o)
		local s, children = pcall(GetDescendants, o)
		if s then
			for i = 1,#children do
				addObject(children[i], true)
			end
		end
	end

	ApplyDescendants(workspace.Parent)
	ApplyDescendants(DexOutput)

	if NilStorageEnabled then
		ApplyDescendants(NilStorage)
	end

	if RunningScriptsStorageEnabled then
		ApplyDescendants(RunningScriptsStorage)
	end

	scrollBar.VisibleSpace = math_ceil(listFrame.AbsoluteSize.Y/ENTRY_BOUND)
	updateList()
end

local actionButtons

do
	actionButtons = {}

	local totalActions = 1
	local currentActions = totalActions
	local function makeButton(icon,over,name,vis,cond)
		local buttonEnabled = false
		local button = Create(SpecialIcon('ImageButton',icon),{
			Name = name .. "Button",
			Visible = Option.Modifiable and Option.Selectable,
			Position = UDim2_new(1,-(GUI_SIZE+2)*currentActions+2,.25,-GUI_SIZE/2),
			Size = UDim2_new(0,GUI_SIZE,0,GUI_SIZE),
			Parent = headerFrame
		})
		local tipText = Create('TextLabel',{
			Name = name .. "Text",
			Text = name,
			Visible = false,
			BackgroundTransparency = 1,
			TextXAlignment = 'Right',
			Font = FONT,
			FontSize = FONT_SIZE,
			Position = UDim2_new(),
			Size = UDim2_new(1,-(GUI_SIZE+2)*totalActions,1,0),
			Parent = headerFrame
		})
		Connect(button.MouseEnter, function()
			if buttonEnabled then
				button.BackgroundTransparency = .9
			end
		end)
		Connect(button.MouseLeave, function()
			button.BackgroundTransparency = 1
		end)
		currentActions += 1
		table_insert(actionButtons, {Obj = button, Cond = cond})
		QuickButtons[#actionButtons+1] = {Obj = button, Cond = cond, Toggle = function(on)
			buttonEnabled = on and true or false
			SpecialIcon(button, on and over or icon)
		end}
		return button
	end
	Connect(makeButton(ActionTextures.Delete[1], ActionTextures.Delete[2],"Delete", true, function()
		return #Selection:Get() > 0
	end).Activated, function()
		if not Option.Modifiable then return end
		for _, Selected in ipairs(Selection:Get()) do
			pcall(game.Destroy, Selected)
		end
		Selection:Set({})
	end)
	Connect(makeButton(ActionTextures.Paste[1], ActionTextures.Paste[2], "Paste", true, function()
		return #Selection:Get() > 0 and #Clipboard > 0
	end).Activated, function()
		if not Option.Modifiable then return end
		local parent = Selection.List[1] or workspace
		for _, Copied in next, Clipboard do
			Clone(Copied).Parent = parent
		end
	end)
	Connect(makeButton(ActionTextures.Copy[1], ActionTextures.Copy[2],"Copy", true, function()
		return #Selection:Get() > 0
	end).Activated, function()
		if not Option.Modifiable then return end
		local list = Selection.List
		for _, Selected in next, list do
			table_insert(Clipboard, Clone(Selected))
		end
		updateActions()
	end)
	makeButton(ActionTextures.AddStar[1], ActionTextures.AddStar[2], "Star", true, function()
		return #Selection:Get() > 0
	end)
	makeButton(ActionTextures.Starred[1], ActionTextures.Starred[2], "Starred", true, function()
		return true
	end)
end

do
	local optionCallback = {
		Modifiable = function(p1)
			for i = 1, #actionButtons do
				actionButtons[i].Obj.Visible = p1 and Option.Selectable
			end
			cancelReparentDrag()
		end,
		Selectable = function(p1)
			for i = 1,#actionButtons do
				actionButtons[i].Obj.Visible = p1 and Option.Modifiable
			end
			cancelSelectDrag()
			Selection:Set({})
		end
	}

	function SetOption_Bindable.OnInvoke(p1, p2)
		if optionCallback[p1] then
			Option[p1] = p2
			optionCallback[p1](p2)
		end
	end

	function GetOption_Bindable.OnInvoke(p1)
		if p1 then
			return Option[p1]
		else
			local A = {}
			for B, C in next, Option do
				A[B] = C
			end
			return A
		end
	end
end

Connect(UserInputService.InputBegan, function(p1)
	local A = p1.KeyCode
	if A == Enum.KeyCode.LeftControl or A == Enum.KeyCode.LeftShift then
		HoldingCtrl = true
	end
	if p1.UserInputType == Enum.UserInputType.MouseButton1 then
		if not ContextMenuHovered then
        	DestroyRightClick()
		end
		--if theres any other uses in the future
    end
end)

Connect(UserInputService.InputEnded, function(p1)
    local A = p1.KeyCode
    if A == Enum.KeyCode.LeftControl or A == Enum.KeyCode.LeftShift then
        HoldingCtrl = false
    end
end)

while not RbxApi do
	RbxApi = GetApi_Bindable:Invoke()
	task.wait()
end

Connect(explorerFilter.FocusLost, function(p1)
	Searched = true
	rawUpdateList()
	if explorerFilter.Text == "" and #Selection:Get() == 1 then
        if GetSetting_Bindable:Invoke("SkipToAfterSearch") then
			local TargetIndex = findObjectIndex(Selection:Get()[1])
            local ScrollIndex = math.max(1, TargetIndex - math.floor(scrollBar.VisibleSpace / 2))
            scrollBar:ScrollTo(ScrollIndex)
		end
	end
end)

CurrentInsertObjectWindow = CreateInsertObjectMenu(GetClasses(), "", false, function(option)
	CurrentInsertObjectWindow.Visible = false
	for _, ArrayItem in ipairs(Selection:Get()) do
		pcall(function()
			Instance_new(option, ArrayItem)
		end)
	end
	DestroyRightClick()
end)
