-- < Fix for module threads not being supported since synapse x > --
local script = getgenv().Dex:WaitForChild("ScriptEditor"):WaitForChild("ScriptEditor")
-- < Aliases > --
local Vector2_zero = Vector2.zero
local Vector2_new = Vector2.new
local Color3_fromRGB = Color3.fromRGB
local Color3_new = Color3.new
local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat
local table_clear = table.clear
local min, max, floor, ceil, random = math.min, math.max, math.floor, math.ceil, math.random
local sub, gsub, match, gmatch, find, rep, format, lower = string.sub, string.gsub, string.match, string.gmatch, string.find, string.rep, string.format, string.lower
local udim2 = UDim2.new
local newInst = Instance.new
local wait = task.wait
-- < Services > --
local UserInputService = cloneref(game:GetService("UserInputService"))
local InsertService = cloneref(game:GetService("InsertService"))
local TweenService = cloneref(game:GetService("TweenService"))
local TextService = cloneref(game:GetService("TextService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
-- < Class Aliases > --
local IsA = Players.IsA
local WaitForChild = Players.WaitForChild
local FindFirstChild = Players.FindFirstChild
local GetPropertyChangedSignal = Players.GetPropertyChangedSignal
local ClearAllChildren = Players.ClearAllChildren
local FindFirstChildOfClass = Players.FindFirstChildOfClass
local IsMouseButtonPressed = UserInputService.IsMouseButtonPressed
local GetFocusedTextBox = UserInputService.GetFocusedTextBox
local GetTextSize = TextService.GetTextSize
local LoadLocalAsset = InsertService.LoadLocalAsset
local Connect, Wait = (function()
	local A = Players.Changed
	return A.Connect, A.Wait
end)()
-- < Bindables > --
local Bindables = WaitForChild(script.Parent.Parent, "Bindables", 300)
local OpenScript_Bindable = WaitForChild(Bindables, "OpenScript", 300)
-- < Upvalues > --
local cache, dragger, CurrentScript = {}, {}, nil
local editor = script.Parent
local TopBar = WaitForChild(editor, "TopBar")
local OtherFrame = WaitForChild(TopBar, "Other")
local SaveScript = WaitForChild(OtherFrame, 'SaveScript')
local CopyScript = WaitForChild(OtherFrame, 'CopyScript')
local ClearScript = WaitForChild(OtherFrame, 'ClearScript')
local DebugScript = WaitForChild(OtherFrame, 'DebugScript')
local FileName = WaitForChild(OtherFrame, 'FileName')
local CloseEditor = WaitForChild(TopBar, "Close")
local Title	= WaitForChild(TopBar, "Title")
local LocalPlayer = Players.LocalPlayer
local PlayerMouse = LocalPlayer:GetMouse()
local Heartbeat = RunService.Heartbeat
local MinSize = editor.Editor.Size
local ResizeEdgeSize = 0.1
local IsResizing = false
local ResizeDirection = ""
local StartMousePos = Vector2.new(0, 0)
local StartFrameSize = UDim2.new(0, 0, 0, 0)
local StartFramePos = UDim2.new(0, 0, 0, 0)
local StartEditorSize = UDim2.new(0, 0, 0, 0)

-- < Source > --
do
	function dragger.new(frame)
		frame.Draggable = false
		local s, event = pcall(function()
			return frame.MouseEnter
		end)
		if s then
			frame.Active = true
			Connect(event, function()
				local input = Connect(frame.InputBegan, function(key)
					if key.UserInputType == Enum.UserInputType.MouseButton1 then
						local objectPosition = Vector2_new(PlayerMouse.X - frame.AbsolutePosition.X, PlayerMouse.Y - frame.AbsolutePosition.Y)
						while IsMouseButtonPressed(UserInputService, Enum.UserInputType.MouseButton1) do
							task.wait(0)
							pcall(function()
								frame:TweenPosition(udim2(0, PlayerMouse.X - objectPosition.X + (frame.Size.X.Offset * frame.AnchorPoint.X), 0, PlayerMouse.Y - objectPosition.Y + (frame.Size.Y.Offset * frame.AnchorPoint.Y)), 'Out', 'Quad', .1, true)
							end)
						end
					end
				end)
				local leave
				leave = Connect(frame.MouseLeave, function()
					input:Disconnect()
					leave:Disconnect()
					input = nil
					leave = nil
				end)
			end)
		end
	end
end

dragger.new(editor)

local newline, tab = "\n", "\t"
local TabText = rep(" ", 4)
local SplitCacheResult, SplitCacheStr, SplitCacheDel
local function Split(str, del)
	if SplitCacheStr == str and SplitCacheDel == del then
		return SplitCacheResult
	end
	local res = {}
	if #del == 0 then
		for i in gmatch(str, ".") do
			table_insert(res, i)
		end
	else
		local i,Si,si = 0, 1, nil
		str ..= del
		while i do
			si, Si, i = i, find(str, del, i + 1, true)
			if i == nil then
				return res
			end
			table_insert(res, sub(str, si + 1, Si - 1))
		end
	end
	SplitCacheResult, SplitCacheStr, SplitCacheDel = res, str, del
	return res
end

local Place = {
	new = function(X, Y)
		return {X = X, Y = Y}
	end
}

local Lexer do
	local lua_builtin = {}
	for Key, T in next, getrenv() do
		if type(Key) == "string" then
			table_insert(lua_builtin, Key)
			if type(T) == "table" then
				for T_Key, _ in next, T do
					if type(T_Key) == "string" then
						table_insert(lua_builtin, Key.."."..T_Key)
					end
				end
			end
		end
	end
	local Keywords = {
		["and"] = true,
		["break"] = true,
		["do"] = true,
		["else"] = true,
		["elseif"] = true,
		["end"] = true,
		["false"] = true,
		["for"] = true,
		["function"] = true,
		["if"] = true,
		["in"] = true,
		["local"] = true,
		["nil"] = true,
		["not"] = true,
		["true"] = true,
		["or"] = true,
		["repeat"] = true,
		["continue"] = true,
		["return"] = true,
		["then"] = true,
		["until"] = true,
		["while"] = true,
		["self"] = true
	}
	local Tokens = {
		Comment = 1,
		Keyword = 2,
		Number = 3,
		Operator = 4,
		String = 5,
		Identifier = 6,
		Builtin = 7,
		Symbol = 19400
	}
	local Stream 
	do
		function Stream(Input, FileName)
			local Index, Line, Column = 1,1,0
			FileName = FileName or "{none}"
			local cols = {}
			return {
				Back = function()
					Index -= 1
					local Char = sub(Input, Index, Index)
					if Char == newline then
						Line -= 1
						Column = table_remove(cols, #cols)
					else
						Column -= 1
					end
				end,
				Next = function()
					local Char = sub(Input, Index, Index)
					Index += 1
					if Char == newline then
						Line += 1
						table_insert(cols, Column)
						Column = 0
					else
						Column += 1
					end
					return Char, {
						Index = Index,
						Line = Line,
						Column = Column,
						File = FileName
					}
				end,
				Peek = function(length)
					return sub(Input, Index, Index + (length or 1) - 1)
				end,
				EOF = function()
					return Index > #Input
				end,
				Fault = function(Error)
					error(Error .. " (col " .. Column .. ", ln " .. Line .. ", file " .. FileName .. ")", 0)
				end
			}
		end
	end

	local idenCheck, numCheck, opCheck = "abcdefghijklmnopqrstuvwxyz_", "0123456789", "+-*/%^#~=<>:,."
	local blank, dot, equal, openbrak, closebrak, backslash, dash, quote, apos = "", ".", "=", "[", "]", "\\", "-", "\"", "'"
	function Lexer(Code)
		local Input = Stream(Code)
		local Current, LastToken, self
		local Clone = function(Table)
			local R = {}
			local Table_mt = getrawmetatable(Table)
			for K, V in next, Table do
				R[K] = V
			end
			if Table_mt then
				setrawmetatable(R, Table_mt)
			end
			return R
		end
		for Key, Value in next, Clone(Tokens) do
			Tokens[Value] = Key
		end
		local function Check(Value, Type, Start)
			if Type == Tokens.Identifier then
				return find(idenCheck, lower(Value), 1, true) ~= nil or not Start and find(numCheck, Value, 1, true) ~= nil
			elseif Type == Tokens.Keyword then
				return (Keywords[Value]) and true or false
			elseif Type == Tokens.Number then
				if Value == "." and not Start then
					return true
				end
				return find(numCheck, Value, 1, true) ~= nil
			elseif Type == Tokens.Operator then
				return find(opCheck, Value, 1, true) ~= nil
			end
		end
		local function Next()
			if Current ~= nil then
				local Token = Current
				Current = nil
				return Token
			end
			if Input.EOF() then
				return nil
			end
			local Char, DebugInfo = Input.Next()
			local Result = {
				Type = Tokens.Symbol
			}
			local sValue = Char
			for i = 0, 256 do
				local open = openbrak .. rep(equal, i) .. openbrak
				if Char .. Input.Peek(#open - 1) == open then
					self.StringDepth = i + 1
					break
				end
			end
			local resulting = false
			if 0 < self.StringDepth then
				local closer = closebrak .. rep(equal, self.StringDepth - 1) .. closebrak
				Input.Back()
				local Value = blank
				while not Input.EOF() and Input.Peek(#closer) ~= closer do
					Char, DebugInfo = Input.Next()
					Value ..= Char
				end
				if Input.Peek(#closer) == closer then
					for i = 1, #closer do
						Value ..= Input.Next()
					end
					self.StringDepth = 0
				end
				Result.Value = Value
				Result.Type = Tokens.String
				resulting = true
			elseif 0 < self.CommentDepth then
				local closer = closebrak .. rep(equal, self.CommentDepth - 1) .. closebrak
				Input.Back()
				local Value = blank
				while not Input.EOF() and Input.Peek(#closer) ~= closer do
					Char, DebugInfo = Input.Next()
					Value ..= Char
				end
				if Input.Peek(#closer) == closer then
					for i = 1, #closer do
						Value ..= Input.Next()
					end
					self.CommentDepth = 0
				end
				Result.Value = Value
				Result.Type = Tokens.Comment
				resulting = true
			end
			local skip = 1
			for i = 1, #lua_builtin do
				local k = lua_builtin[i]
				if Input.Peek(#k - 1) == sub(k, 2) and Char == sub(k, 1, 1) and skip < #k then
					Result.Type = Tokens.Builtin
					Result.Value = k
					skip = #k
					resulting = true
				end
			end
			for i = 1, skip - 1 do
				Char, DebugInfo = Input.Next()
			end
			if resulting then
			elseif Check(Char, Tokens.Identifier, true) then
				local Value = Char
				while Check(Input.Peek(), Tokens.Identifier) and not Input.EOF() do
					Value ..= Input.Next()
				end
				Result.Type = Check(Value, Tokens.Keyword) and Tokens.Keyword or Tokens.Identifier
				Result.Value = Value
			elseif Char == dash and Input.Peek() == dash then
				local Value = Char .. Input.Next()
				for i = 0, 256 do
					local open = openbrak .. rep(equal, i) .. openbrak
					if Input.Peek(#open) == open then
						self.CommentDepth = i + 1
						break
					end
				end
				if 0 < self.CommentDepth then
					local closer = closebrak .. rep(equal, self.CommentDepth - 1) .. closebrak
					while not Input.EOF() and Input.Peek(#closer) ~= closer do
						Char, DebugInfo = Input.Next()
						Value ..= Char
					end
					if Input.Peek(#closer) == closer then
						for i = 1, #closer do
							Value ..= Input.Next()
						end
						self.CommentDepth = 0
					end
				else
					while not Input.EOF() and not find(newline, Char, 1, true) do
						Char, DebugInfo = Input.Next()
						Value ..= Char
					end
				end
				Result.Value = Value
				Result.Type = Tokens.Comment
			elseif Check(Char, Tokens.Number, true) or Char == dot and Check(Input.Peek(), Tokens.Number, true) then
				local Value = Char
				while Check(Input.Peek(), Tokens.Number) and not Input.EOF() do
					Value ..= Input.Next()
				end
				Result.Value = Value
				Result.Type = Tokens.Number
			elseif Char == quote then
				local Escaped = false
				local String = blank
				Result.Value = quote
				while not Input.EOF() do
					local Char = Input.Next()
					Result.Value ..= Char
					if Escaped then
						String ..= Char
						Escaped = false
					elseif Char == backslash then
						Escaped = true
					elseif Char == quote or Char == newline then
						break
					else
						String ..= Char
					end
				end
				Result.Type = Tokens.String
			elseif Char == apos then
				local Escaped = false
				local String = blank
				Result.Value = apos
				while not Input.EOF() do
					local Char = Input.Next()
					Result.Value ..= Char
					if Escaped then
						String ..= Char
						Escaped = false
					elseif Char == backslash then
						Escaped = true
					elseif Char == apos or Char == newline then
						break
					else
						String ..= Char
					end
				end
				Result.Type = Tokens.String
			elseif Check(Char, Tokens.Operator) then
				Result.Value = Char
				Result.Type = Tokens.Operator
			else
				Result.Value = Char
			end
			Result.TypeName = Tokens[Result.Type]
			LastToken = Result
			return Result
		end
		local function Peek()
			local Result = Next()
			Current = Result
			return Result
		end
		self = {
			Next = Next,
			Peek = Peek,
			EOF = function()
				return Peek() == nil
			end,
			GetLast = function()
				return LastToken
			end,
			CommentDepth = 0,
			StringDepth = 0
		}
		return self
	end
end
function GetResizeDirection(MousePos)
    local FramePos = editor.Editor.AbsolutePosition
    local FrameSize = editor.Editor.AbsoluteSize
    local IsRightEdge = MousePos.X >= FramePos.X + FrameSize.X - ResizeEdgeSize
    local IsBottomEdge = MousePos.Y >= FramePos.Y + FrameSize.Y - ResizeEdgeSize

    if IsRightEdge and IsBottomEdge then return "southeast"
    elseif IsRightEdge then return "east"
    elseif IsBottomEdge then return "south"
    end
    return ""
end

function PerformResize(MousePos)
    local Delta = MousePos - StartMousePos
    local NewSize = StartFrameSize
    local NewEditorSize = StartEditorSize

    if ResizeDirection:find("east") then
        local NewWidth = math.max(MinSize.X.Offset, StartFrameSize.X.Offset + Delta.X)
        NewSize = UDim2.new(0, NewWidth, StartFrameSize.Y.Scale, StartFrameSize.Y.Offset)
        NewEditorSize = UDim2.new(0, StartEditorSize.X.Offset + (NewWidth - StartFrameSize.X.Offset), 
            StartEditorSize.Y.Scale, StartEditorSize.Y.Offset)
    end

    if ResizeDirection:find("south") then
        NewSize = UDim2.new(NewSize.X.Scale, NewSize.X.Offset, 0, 
            math.max(MinSize.Y.Offset, StartFrameSize.Y.Offset + Delta.Y))
    end

    editor.Editor.Size = NewSize
    editor.Editor.Position = StartFramePos
    ScriptEditor.Size = NewEditorSize
end
function Place.fromIndex(CodeEditor, Index)
	local cache = CodeEditor.PlaceCache
	local fromCache = {}
	if cache.fromIndex then
		fromCache = cache.fromIndex
	else
		cache.fromIndex = fromCache
	end
	if fromCache[Index] then
	end
	local Content = CodeEditor.Content
	local ContentUpto = sub(Content, 1, Index)
	if Index == 0 then
		return Place.new(0, 0)
	end
	local Lines = Split(ContentUpto, newline)
	local res = Place.new(#gsub(Lines[#Lines], tab, TabText), #Lines - 1)
	fromCache[Index] = res
	return res
end
function Place.toIndex(CodeEditor, Place)
	local cache = CodeEditor.PlaceCache
	local toCache = {}
	if cache.toIndex then
		toCache = cache.toIndex
	else
		cache.toIndex = toCache
	end
	local Content = CodeEditor.Content
	if Place.X == 0 and Place.Y == 0 then
		return 0
	end
	local Lines = CodeEditor.Lines
	local Index = 0
	for I = 1, Place.Y do
		Index += #Lines[I] + 1
	end
	local line = Lines[Place.Y + 1]
	local roundedX = Place.X
	local ix = 0
	for i = 1, #line do
		local c = sub(line, i, i)
		local pix = ix
		if c == tab then
			ix += #TabText
		else
			ix += 1
		end
		if Place.X == ix then
			roundedX = i
		elseif pix < Place.X and ix > Place.X then
			if Place.X - pix < ix - Place.X then
				roundedX = i - 1
			else
				roundedX = i
			end
		end
	end
	local res = Index + min(#line, roundedX)
	toCache[Place.X .. "-$-" .. Place.Y] = res
	return res
end
local Selection = {}
local Side = {Left = 1, Right = 2}
function Selection.new(Start, End, CaretSide)
	return {
		Start = Start,
		End = End,
		Side = CaretSide
	}
end
local Themes = {
	Plain = {
		LineSelection = Color3_fromRGB(46, 46, 46),
		Background = Color3_fromRGB(45, 45, 45),
		Comment = Color3_fromRGB(150, 150, 150),
		Keyword = Color3_fromRGB(204, 153, 204),
		Builtin = Color3_fromRGB(102, 153, 204),
		Number = Color3_fromRGB(250, 145, 85),
		Operator = Color3_fromRGB(102, 204, 204),
		String = Color3_fromRGB(153, 204, 153),
		Text = Color3_fromRGB(204, 204, 204),
		SelectionBackground = Color3_fromRGB(150, 150, 150),
		SelectionColor = Color3_fromRGB(),
		SelectionGentle = Color3_fromRGB(65, 65, 65)
	}
}

local EditorLib = {
	["Place"] = Place,
	["Selection"] = Selection,
	NewTheme = function(Name, Theme)
		Themes[Name] = Theme
	end
}

local TextCursor = {
	Image = "rbxassetid://1188942192",
	HotspotX = 3,
	HotspotY = 8,
	Size = udim2(0, 7, 0, 17)
}
function EditorLib.Initialize(Frame, Options)
	local themestuff = {}
	local function ThemeSet(obj, prop, val)
		themestuff[obj] = themestuff[obj] or {}
		themestuff[obj][prop] = val
	end
	local baseZIndex = Frame.ZIndex
	Options.CaretBlinkingRate = tonumber(Options.CaretBlinkingRate) or .25
	Options.FontSize = tonumber(Options.FontSize or Options.TextSize) or 14
	Options.CaretFocusedOpacity = tonumber(Options.CaretOpacity and Options.CaretOpacity.Focused or Options.CaretFocusedOpacity) or 1
	Options.CaretUnfocusedOpacity = tonumber(Options.CaretOpacity and Options.CaretOpacity.Unfocused or Options.CaretUnfocusedOpacity) or 0
	Options.Theme = type(Options.Theme) == "string" and Options.Theme or "Plain"
	local SizeDot = GetTextSize(TextService, ".", Options.FontSize, Options.Font, Vector2_new(1000, 1000))
	local SizeM = GetTextSize(TextService, "m", Options.FontSize, Options.Font, Vector2_new(1000, 1000))
	local SizeAV = GetTextSize(TextService, "AV", Options.FontSize, Options.Font, Vector2_new(1000, 1000))
	local Editor = {
		Content = "",
		Lines = {""},
		Focused = false,
		PlaceCache = {},
		Selection = Selection.new(0, 0, Side.Left),
		LastKeyCode = false,
		UndoStack = {},
		RedoStack = {}
	}
	Editor.StartingSelection = Editor.Selection
	local CharWidth = SizeM.X
	local CharHeight = SizeM.Y + 4
	if (SizeDot.X ~= SizeM.X or SizeDot.Y ~= SizeM.Y) and SizeAV.X ~= SizeM.X + SizeDot.X then
		return error("CodeEditor requires a monospace font with no currying", 2)
	end
	local ContentChangedEvent = newInst("BindableEvent")
	local FocusLostEvent = newInst("BindableEvent")
	local PlayerGui = FindFirstChildOfClass(LocalPlayer, "PlayerGui")
	local Container = newInst("Frame")
	Container.Name = "Container"
	Container.BorderSizePixel = 0
	Container.BackgroundColor3 = Themes[Options.Theme].Background
	ThemeSet(Container, "BackgroundColor3", "Background")
	Container.Size = udim2(1, 0, 1, 0)
	Container.ClipsDescendants = true
	local GutterSize = CharWidth * 4
	local TextArea = newInst("ScrollingFrame")
	TextArea.Name = "TextArea"
	TextArea.BackgroundTransparency = 1
	TextArea.BorderSizePixel = 0
	TextArea.Size = udim2(1, -GutterSize, 1, 0)
	TextArea.Position = udim2(0, GutterSize, 0, 0)
	TextArea.ScrollBarThickness = 10
	TextArea.ScrollBarImageTransparency = 0
	TextArea.ScrollBarImageColor3 = Color3_fromRGB(20, 20, 20)
	TextArea.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	TextArea.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	TextArea.ZIndex = 3
	local Gutter = newInst("Frame")
	Gutter.Name = "Gutter"
	Gutter.ZIndex = baseZIndex
	Gutter.BorderSizePixel = 0
	Gutter.BackgroundTransparency = .96
	Gutter.Size = udim2(0, GutterSize - 5, 1.5, 0)
	local GoodMouseDetector = newInst("TextButton")
	GoodMouseDetector.Text = [[]]
	GoodMouseDetector.BackgroundTransparency = 1
	GoodMouseDetector.Size = udim2(1, 0, 1, 0)
	GoodMouseDetector.Position = udim2()
	GoodMouseDetector.Visible = false
	local Scroll = newInst("TextButton")
	Scroll.Name = "VertScroll"
	Scroll.Size = udim2(0, 10, 1, 0)
	Scroll.Position = udim2(1, -10, 0, 0)
	Scroll.BackgroundTransparency = 1
	Scroll.Text = ""
	Scroll.ZIndex = 1000
	Scroll.Parent = Container
	local ScrollBar = newInst("TextButton")
	ScrollBar.Name = "ScrollBar"
	ScrollBar.Size = udim2(1, 0, 0, 36)
	ScrollBar.Position = udim2()
	ScrollBar.Text = ""
	ScrollBar.BackgroundColor3 = Themes[Options.Theme].ScrollBar or Color3_fromRGB(120, 120, 120)
	ScrollBar.BackgroundTransparency = .75
	ScrollBar.BorderSizePixel = 0
	ScrollBar.AutoButtonColor = false
	ScrollBar.ZIndex = 3 + baseZIndex
	ScrollBar.Parent = Scroll
	local CaretIndicator = newInst("Frame")
	CaretIndicator.Name = "CaretIndicator"
	CaretIndicator.Size = udim2(1, 0, 0, 2)
	CaretIndicator.Position = udim2()
	CaretIndicator.BorderSizePixel = 0
	CaretIndicator.BackgroundColor3 = Themes[Options.Theme].Text
	ThemeSet(CaretIndicator, "BackgroundColor3", "Text")
	CaretIndicator.BackgroundTransparency = .29803921568627456
	CaretIndicator.ZIndex = 4 + baseZIndex
	CaretIndicator.Parent = Scroll
	local MarkersFolder = newInst("Folder", Scroll)
	local markers = {}
	local updateMarkers

	do
		local lerp = function(a, b, r)
			return a + r * (b - a)
		end
		function updateMarkers()
			ClearAllChildren(MarkersFolder)
			local Theme = Themes[Options.Theme]
			local Background = Theme.Background
			local Text = Theme.Text
			local ra = Background.r
			local ga = Background.g
			local ba = Background.b
			local rb = Text.r
			local gb = Text.g
			local bb = Text.b
			local r = lerp(ra, rb, .2980392156862745)
			local g = lerp(ga, gb, .2980392156862745)
			local b = lerp(ba, bb, .2980392156862745)
			local color = Color3_new(r, g, b)
			for i, v in ipairs(markers) do
				local Marker = newInst("Frame")
				Marker.BorderSizePixel = 0
				Marker.BackgroundColor3 = color
				Marker.Size = udim2(0, 4, 0, 6)
				Marker.Position = udim2(0, 4, v * CharHeight / TextArea.CanvasSize.Y.Offset, 0)
				Marker.ZIndex = 4 + baseZIndex
				Marker.Parent = MarkersFolder
			end
		end
	end
	do
		Connect(TextArea.Changed, function(property)
			if property == "CanvasSize" or property == "CanvasPosition" then
				Gutter.Position = udim2(0, 0, 0, -TextArea.CanvasPosition.Y)
			end
		end)
	end
	local Theme = Themes[Options.Theme]
	local ScrollBorder = newInst("Frame")
	ScrollBorder.Name = "ScrollBorder"
	ScrollBorder.Position = udim2(0, -1, 0, 0)
	ScrollBorder.Size = udim2(0, 1, 1, 0)
	ScrollBorder.BorderSizePixel = 0
	ScrollBorder.BackgroundColor3 = Color3_fromRGB(34, 34, 34)
	ScrollBorder.Parent = Scroll
	do
		Connect(TextArea.Changed, function(property)
			if property == "CanvasSize" or property == "CanvasPosition" then
				local percent = TextArea.AbsoluteWindowSize.X / TextArea.CanvasSize.X.Offset
				ScrollBar.Size = udim2(percent, 0, 1, 0)
				local max = max(TextArea.CanvasSize.X.Offset - TextArea.AbsoluteWindowSize.X, 0)
				ScrollBar.Position = udim2(0, (max == 0 and 0 or TextArea.CanvasPosition.X / max) * (Scroll.AbsoluteSize.X - ScrollBar.AbsoluteSize.X), 0, 0)
				Scroll.Visible = false
			end
		end)
	end
	local LineSelection = newInst("Frame")
	LineSelection.Name = "LineSelection"
	LineSelection.BackgroundColor3 = Theme.Background
	ThemeSet(LineSelection, "BackgroundColor3", "Background")
	LineSelection.BorderSizePixel = 2
	LineSelection.BorderColor3 = Theme.LineSelection
	ThemeSet(LineSelection, "BorderColor3", "LineSelection")
	LineSelection.Size = udim2(1, -4, 0, CharHeight - 4)
	LineSelection.Position = udim2(0, 2, 0, 2)
	LineSelection.ZIndex = -1 + baseZIndex
	LineSelection.Visible = false
	LineSelection.Parent = TextArea

	local ErrorHighlighter = newInst("Frame")
	ErrorHighlighter.Name = "ErrorHighlighter"
	ErrorHighlighter.BackgroundColor3 = Color3_fromRGB(255, 0, 0)
	ErrorHighlighter.BackgroundTransparency = .9
	ErrorHighlighter.BorderSizePixel = 0
	ErrorHighlighter.Size = udim2(1, -4, 0, CharHeight - 4)
	ErrorHighlighter.Position = udim2(0, 2, 0, 2)
	ErrorHighlighter.ZIndex = 5 + baseZIndex
	ErrorHighlighter.Visible = false
	ErrorHighlighter.Parent = TextArea

	local ErrorMessage = newInst("TextLabel")
	ErrorMessage.Name = "ErrorMessage"
	ErrorMessage.BackgroundColor3 = Theme.Background:Lerp(Color3_new(1, 1, 1), .1)
	ErrorMessage.TextColor3 = Color3_fromRGB(255, 152, 152)
	ErrorMessage.BorderSizePixel = 0
	ErrorMessage.Visible = false
	ErrorMessage.Size = udim2(0, 150, 0, CharHeight - 4)
	ErrorMessage.Position = udim2(0, 2, 0, 2)
	ErrorMessage.ZIndex = 6 + baseZIndex
	ErrorMessage.Parent = Container

	local Tokens = newInst("Frame")
	Tokens.BackgroundTransparency = 1
	Tokens.Name = "Tokens"
	Tokens.Parent = TextArea

	local Selection = newInst("Frame")
	Selection.BackgroundTransparency = 1
	Selection.Name = "Selection"
	Selection.ZIndex = baseZIndex
	Selection.Parent = TextArea

	local TextBox = newInst("TextBox")
	TextBox.BackgroundTransparency = 1
	TextBox.Size = udim2(0, 0, 0, 0)
	TextBox.Position = udim2(-1, 0, -1, 0)
	TextBox.Text = ""
	TextBox.ShowNativeInput = false
	TextBox.MultiLine = true
	TextBox.ClearTextOnFocus = true

	local Caret = newInst("Frame")
	Caret.Name = "Caret"
	Caret.BorderSizePixel = 0
	Caret.BackgroundColor3 = Theme.Text
	ThemeSet(Caret, "BackgroundColor3", "Text")
	Caret.Size = udim2(0, 2, 0, CharHeight)
	Caret.Position = udim2(0, 0, 0, 0)
	Caret.ZIndex = 100
	Caret.Visible = false

	local selectedword = nil
	local tokens = {}

	local function NewToken(Content, Color, Position, Parent)
		local Token = newInst("TextLabel")
		Token.BorderSizePixel = 0
		Token.TextColor3 = Theme[Color]
		Token.BackgroundTransparency = (Content == selectedword) and 0 or 1
		Token.BackgroundColor3 = Theme.SelectionGentle
		Token.Size = udim2(0, CharWidth * #Content, 0, CharHeight)
		Token.Position = udim2(0, Position.X * CharWidth, 0, Position.Y * CharHeight)
		Token.Font = Options.Font
		Token.TextSize = Options.FontSize
		Token.Text = Content
		Token.TextXAlignment = "Left"
		Token.ZIndex = baseZIndex
		Token.Parent = Parent
		table_insert(tokens, Token)
	end

	local function updateselected()
		for _, v in ipairs(tokens) do
			v.BackgroundTransparency = (v.Text == selectedword) and 0 or 1
		end
		table_clear(markers)
		if selectedword and selectedword ~= "" and selectedword ~= tab then
			for LineNumber = 1, #Editor.Lines do
				local line = Editor.Lines[LineNumber]
				local Dnable = "[^A-Za-z0-9_]"
				local has = false
				if sub(line, 1, #selectedword) == selectedword then
					has = true
				elseif sub(line, #line - #selectedword + 1) == selectedword then
					has = true
				elseif match(line, Dnable .. gsub(selectedword, "%W", "%%%1") .. Dnable) then
					has = true
				end
				if has then
					table_insert(markers, LineNumber - 1)
				end
			end
		end
		updateMarkers()
	end
	local DrawnLines = {}
	local depth, sdepth = {}, {}
	local function DrawTokens()
		local LineBegin = floor(TextArea.CanvasPosition.Y / CharHeight)
		local LineEnd = ceil((TextArea.CanvasPosition.Y + TextArea.AbsoluteWindowSize.Y) / CharHeight)
		LineEnd = min(LineEnd, #Editor.Lines)
		for LineNumber = 1, LineBegin - 1 do
			if not depth[LineNumber] then
				local line = Editor.Lines[LineNumber] or ""
				if match(line, "%[%=+%[") or match(line, "%]%=+%]") then
					local LexerStream = Lexer(line)
					LexerStream.CommentDepth = depth[LineNumber - 1] or 0
					LexerStream.StringDepth = sdepth[LineNumber - 1] or 0
					while not LexerStream.EOF() do
						LexerStream.Next()
					end
					sdepth[LineNumber] = LexerStream.StringDepth
					depth[LineNumber] = LexerStream.CommentDepth
				else
					sdepth[LineNumber] = sdepth[LineNumber - 1] or 0
					depth[LineNumber] = depth[LineNumber - 1] or 0
				end
			end
		end
		for LineNumber = LineBegin, LineEnd do
			if not DrawnLines[LineNumber] then
				DrawnLines[LineNumber] = true
				local X, Y = 0, LineNumber - 1
				local LineLabel = newInst("TextLabel")
				LineLabel.BorderSizePixel = 0
				LineLabel.TextColor3 = Color3_fromRGB(144, 145, 139)
				LineLabel.BackgroundTransparency = 1
				LineLabel.Size = udim2(1, 0, 0, CharHeight)
				LineLabel.Position = udim2(0, 0, 0, Y * CharHeight)
				LineLabel.Font = Options.Font
				LineLabel.TextSize = Options.FontSize
				LineLabel.TextXAlignment = Enum.TextXAlignment.Right
				LineLabel.Text = LineNumber
				LineLabel.ZIndex = baseZIndex
				LineLabel.Parent = Gutter
				if Editor.Lines[Y + 1] then
					local LexerStream = Lexer(Editor.Lines[Y + 1])
					LexerStream.CommentDepth = depth[LineNumber - 1] or 0
					LexerStream.StringDepth = sdepth[LineNumber - 1] or 0
					while not LexerStream.EOF() do
						local Token = LexerStream.Next()
						local Value = Token.Value
						local TokenType = Token.TypeName
						if find(" \t\r\n", Value, 1, true) == nil then
							NewToken(gsub(Value, tab, TabText), (TokenType == "Identifier" or TokenType == "Symbol") and "Text" or TokenType, Place.new(X, Y), Tokens)
						end
						X += #gsub(Value, tab, TabText)
					end
					depth[LineNumber] = LexerStream.CommentDepth
					sdepth[LineNumber] = LexerStream.StringDepth
				end
			end
		end
	end
	Connect(TextArea.Changed, function(Property)
		if Property == "CanvasPosition" or Property == "AbsoluteWindowSize" then
			DrawTokens()
		end
	end)
	local function ClearTokensAndSelection()
		table_clear(depth)
		ClearAllChildren(Tokens)
		ClearAllChildren(Selection)
		ClearAllChildren(Gutter)
	end
	local function Write(Content, Start, End)
		local InBetween = sub(Editor.Content, Start + 1, End)
		local NoLN = find(InBetween, newline, 1, true) == nil and find(Content, newline, 1, true) == nil
		local StartPlace, EndPlace
		if NoLN then
			StartPlace, EndPlace = Place.fromIndex(Editor, Start), Place.fromIndex(Editor, End)
		end
		Editor.Content = sub(Editor.Content, 1, Start) .. Content .. sub(Editor.Content, End + 1)
		ContentChangedEvent:Fire(Editor.Content)
		table_clear(Editor.PlaceCache)
		local CanvasWidth = TextArea.CanvasSize.X.Offset - 14
		Editor.Lines = Split(Editor.Content, newline)
		for _, Res in ipairs(Editor.Lines) do
			local width = #gsub(Res, tab, TabText) * CharWidth
			CanvasWidth = CanvasWidth < width and width or CanvasWidth
		end
		ClearTokensAndSelection()
		TextArea.CanvasSize = udim2(0, 3000, 0, select(2, gsub(Editor.Content, newline, "")) * CharHeight + TextArea.AbsoluteWindowSize.Y)
		table_clear(DrawnLines)
		DrawTokens()
	end
	local function SetContent(Content)
		Editor.Content = Content
		ContentChangedEvent:Fire(Editor.Content)
		table_clear(Editor.PlaceCache)
		Editor.Lines = Split(Editor.Content, newline)
		ClearTokensAndSelection()
		local CanvasWidth = TextArea.CanvasSize.X.Offset - 14
		for _, Res in ipairs(Editor.Lines) do
			local A = #Res
			CanvasWidth = CanvasWidth < A and A * CharWidth or CanvasWidth
		end
		TextArea.CanvasSize = udim2(0, 3000, 0, select(2, gsub(Editor.Content, newline, "")) * CharHeight + TextArea.AbsoluteWindowSize.Y)
		table_clear(DrawnLines)
		DrawTokens()
	end
	local function UpdateSelection()
		ClearAllChildren(Selection)
		Selection.ZIndex = (Themes[Options.Theme].SelectionColor) and 2 or 1 + baseZIndex
		Tokens.ZIndex = (Themes[Options.Theme].SelectionColor) and 1 or 2 + baseZIndex
		if Editor.Selection.Start == Editor.Selection.End then
			LineSelection.Visible = true
			LineSelection.Position = udim2(0, 2, 0, CharHeight * Place.fromIndex(Editor, Editor.Selection.Start).Y + 2)
		else
			LineSelection.Visible = false
		end
		local Index = 0
		local Start = #gsub(sub(Editor.Content, 1, Editor.Selection.Start), tab, TabText)
		local End = #gsub(sub(Editor.Content, 1, Editor.Selection.End), tab, TabText)
		for LineNumber, Line in ipairs(Editor.Lines) do
			Line = gsub(Line, tab, TabText)
			local StartX = Start - Index
			local EndX = End - Index
			local Y = LineNumber - 1
			local GoesOverLine = false
			local SLine = #Line
			StartX = StartX < 0 and 0 or StartX
			if EndX > SLine then
				GoesOverLine = true
				EndX = SLine
			end
			local Width = EndX - StartX
			if GoesOverLine then
				Width += .5
			end
			if Width > 0 then
				local color = Themes[Options.Theme].SelectionColor
				local SelectionSegment = newInst(color and "TextLabel" or "Frame")
				SelectionSegment.BorderSizePixel = 0
				if color then
					SelectionSegment.TextColor3 = color
					SelectionSegment.Font = Options.Font
					SelectionSegment.TextSize = Options.FontSize
					SelectionSegment.Text = sub(Line, StartX + 1, EndX)
					SelectionSegment.TextXAlignment = "Left"
					SelectionSegment.ZIndex = baseZIndex
				end
				SelectionSegment.BackgroundColor3 = Themes[Options.Theme].SelectionBackground
				SelectionSegment.Size = udim2(0, CharWidth * Width, 0, CharHeight)
				SelectionSegment.Position = udim2(0, StartX * CharWidth, 0, Y * CharHeight)
				SelectionSegment.Parent = Selection
			end
			Index += SLine + 1
		end
		local NewY = Caret.Position.Y.Offset
		local MinBoundsY = TextArea.CanvasPosition.Y
		local MaxBoundsY = MinBoundsY + TextArea.AbsoluteWindowSize.Y - CharHeight
		if NewY < MinBoundsY then
			TextArea.CanvasPosition = Vector2_new(0, NewY)
		end
		if NewY > MaxBoundsY then
			TextArea.CanvasPosition = Vector2_new(0, NewY - TextArea.AbsoluteWindowSize.Y + CharHeight)
		end
	end
	TextBox.Parent = TextArea
	Caret.Parent = TextArea
	TextArea.Parent = Container
	Gutter.Parent = Container
	Container.Parent = Frame
	local function updateCaret(CaretPlace)
		Caret.Position = udim2(0, CaretPlace.X * CharWidth, 0, CaretPlace.Y * CharHeight)
		CaretIndicator.Position = udim2(0, 0, CaretPlace.Y * CharHeight / TextArea.CanvasSize.Y.Offset, -1)
	end
	local PressedKey, WorkingKey, LeftShift, RightShift, Shift, LeftCtrl, RightCtrl, Ctrl
	local MovementTimeout = tick()
	local BeginSelect, MoveCaret
	local function SetVisibility(Visible)
		Editor.Visible = Visible
	end
	local function selectWord()
		local Index = (Editor.Selection.Side == Side.Right) and Editor.Selection.End or Editor.Selection.Start
		local code = Editor.Content
		local left = max(Index - 1, 0)
		local right = min(Index + 1, #code)
		local Dable = "[A-Za-z0-9_]"
		while left ~= 0 and match(sub(code, left + 1, left + 1), Dable) do
			left -= 1
		end
		while right ~= #code and match(sub(code, right, right), Dable) do
			right += 1
		end
		if not match(sub(code, left + 1, left + 1), Dable) then
			left += 1
		end
		if not match(sub(code, right, right), Dable) then
			right -= 1
		end
		if left < right then
			Editor.Selection.Start = left
			Editor.Selection.End = right
		else
			Editor.Selection.Start = Index
			Editor.Selection.End = Index
		end
	end
	local lastClick, lastCaretPos = 0, 0
	local function PushToUndoStack()
		table_insert(Editor.UndoStack, {
			Content = Editor.Content,
			Selection = {
				Start = Editor.Selection.Start,
				End = Editor.Selection.End,
				Side = Editor.Selection.Side
			},
			LastKeyCode = false
		})
		if #Editor.RedoStack > 0 then
			table_clear(Editor.RedoStack)
		end
	end
	local function Undo()
		local UndoStack = Editor.UndoStack
		local S = #UndoStack
		if S > 1 then
			local Thing = UndoStack[S - 1]
			for Key, Value in next, Thing do
				Editor[Key] = Value
			end
			Editor.SetContent(Thing.Content)
			table_insert(Editor.RedoStack, table_remove(UndoStack, S))
		end
	end
	local function Redo()
		local RedoStack = Editor.RedoStack
		local S = #RedoStack
		if S > 0 then
			local Thing = RedoStack[S]
			for Key, Value in next, Thing do
				Editor[Key] = Value
			end
			Editor.SetContent(Thing.Content)
			table_insert(Editor.UndoStack, Thing)
			table_remove(RedoStack, S)
		end
	end
	--[[Connect(PlayerMouse.Move, function()
		if BeginSelect then
			local Index = GetIndexAtMouse()
			if type(BeginSelect) == "number" then
				BeginSelect = {BeginSelect, BeginSelect}
			end
			local Selection = Editor.Selection
			Selection.Start = min(BeginSelect[1], Index)
			Selection.End = max(BeginSelect[2], Index)
			if Selection.Start ~= Selection.End then
				Selection.Side = Selection.Start == Index and Side.Left or Side.Right
			end
			if BeginSelect[3] then
				selectWord()
				Selection.Start = min(BeginSelect[1], Selection.Start)
				Selection.End = max(BeginSelect[2], Selection.End)
			end
			updateCaret(Place.fromIndex(Editor, Selection.Side == Side.Right and Selection.End or Selection.Start))
			UpdateSelection()
		end
	end)]]
	Connect(TextBox.Focused, function()
		Editor.Focused = true
	end)
	Connect(TextBox.FocusLost, function()
		Editor.Focused = false
		FocusLostEvent:Fire()
		PressedKey = nil
		WorkingKey = nil
	end)
	function MoveCaret(Amount)
		local Direction = Amount < 0 and -1 or 1
		if Amount < 0 then
			Amount = -Amount
		end
		for Index = 1, Amount do
			if Direction == -1 then
				local Start = Editor.Selection.Start
				local End = Editor.Selection.End
				if Shift then
					if Start == End then
						if Start > 0 then
							Editor.Selection.Start = Start - 1
							Editor.Selection.Side = Side.Left
						end
					elseif Editor.Selection.Side == Side.Left then
						if Start > 0 then
							Editor.Selection.Start = Start - 1
						end
					elseif Editor.Selection.Side == Side.Right then
						Editor.Selection.End = End - 1
					end
				elseif Start ~= End then
					Editor.Selection.End = Start
				elseif Start > 0 then
					Editor.Selection.Start = Start - 1
					Editor.Selection.End = End - 1
				end
			elseif Direction == 1 then
				local Start = Editor.Selection.Start
				local End = Editor.Selection.End
				if Shift then
					if Start == End then
						if Start < #Editor.Content then
							Editor.Selection.End = End + 1
							Editor.Selection.Side = Side.Right
						end
					elseif Editor.Selection.Side == Side.Left then
						Editor.Selection.Start = Start + 1
					elseif Editor.Selection.Side == Side.Right and End < #Editor.Content then
						Editor.Selection.End = End + 1
					end
				elseif Start ~= End then
					Editor.Selection.Start = End
				elseif Start < #Editor.Content then
					Editor.Selection.Start = Start + 1
					Editor.Selection.End = End + 1
				end
			end
		end
	end
	local LastKeyCode
	local function ProcessInput(Type, Data)
		MovementTimeout = tick() + .25
		if Type == "Control+Key" then
			LastKeyCode = nil
		elseif Type == "KeyPress" then
			local Dat = Data
			if Dat == Enum.KeyCode.Up then
				Dat = Enum.KeyCode.Down
			end
			if LastKeyCode ~= Dat then
				Editor.StartingSelection.Start = Editor.Selection.Start
				Editor.StartingSelection.End = Editor.Selection.End
				Editor.StartingSelection.Side = Editor.Selection.Side
			end
			LastKeyCode = Dat
		elseif Type == "StringInput" then
			local Start = Editor.Selection.Start
			local End = Editor.Selection.End
			if Data == newline then
				local CaretPlaceInd = Editor.Selection.Start
				if Editor.Selection.Side == Side.Right then
					CaretPlaceInd = Editor.Selection.End
				end
				local CaretPlace = Place.fromIndex(Editor, CaretPlaceInd)
				local CaretLine = Editor.Lines
				CaretLine = CaretLine[CaretPlace.Y + 1]
				CaretLine = sub(CaretLine, 1, CaretPlace.X)
				local TabAmount = 0
				while sub(CaretLine, TabAmount + 1, TabAmount + 1) == tab do
					TabAmount += 1
				end
				Data ..= rep(tab, TabAmount)
				local SpTabAmount = 0
				while sub(CaretLine, SpTabAmount + 1, SpTabAmount + 1) == " " do
					SpTabAmount += 1
				end
				Data ..= gsub(rep(" ", SpTabAmount), TabText, tab)
				Write(Data, Start, End)
				Editor.Selection.Start = Start + #Data
				Editor.Selection.End = Editor.Selection.Start
				PushToUndoStack()
			elseif Data == tab and Editor.Selection.Start ~= Editor.Selection.End then
				local lstart = Place.fromIndex(Editor, Editor.Selection.Start)
				local lend = Place.fromIndex(Editor, Editor.Selection.End)
				local changes = 0
				local change1 = 0
				for i = lstart.Y + 1, lend.Y + 1 do
					local line = Editor.Lines[i]
					local change = 0
					if Shift then
						if sub(line, 1, 1) == tab then
							line = sub(line, 2)
							change = -1
						end
					else
						line = tab .. line
						change = 1
					end
					changes += change
					if i == lstart.Y + 1 then
						change1 = change
					end
					Editor.Lines[i] = line
				end
				SetContent(table_concat(Editor.Lines, newline))
				Editor.Selection.Start += change1
				Editor.Selection.End += changes
				PushToUndoStack()
			else
				Write(Data, Start, End)
				Editor.Selection.Start = Start + #Data
				Editor.Selection.End = Editor.Selection.Start
				PushToUndoStack()
			end
		end
		local CaretPlaceInd = (Editor.Selection.Side == Side.Right) and Editor.Selection.End or Editor.Selection.Start
		local CaretPlace = Place.fromIndex(Editor, CaretPlaceInd)
		updateCaret(CaretPlace)
		UpdateSelection()
	end
	Connect(GetPropertyChangedSignal(TextBox, "Text"), function()
		if TextBox.Text ~= "" then
			ProcessInput("StringInput", (gsub(TextBox.Text, "\r", "")))
			TextBox.Text = ""
		end
	end)
	Connect(UserInputService.InputBegan, function(Input)
		if GetFocusedTextBox(UserInputService) == TextBox and Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			local KeyCode = Input.KeyCode
			if KeyCode == Enum.KeyCode.LeftShift then
				LeftShift = true
				Shift = true
			elseif KeyCode == Enum.KeyCode.RightShift then
				RightShift = true
				Shift = true
			elseif KeyCode == Enum.KeyCode.LeftControl then
				LeftCtrl = true
				Ctrl = true
			elseif KeyCode == Enum.KeyCode.RightControl then
				RightCtrl = true
				Ctrl = true
			else
				PressedKey = KeyCode
				ProcessInput(not (not Ctrl or Shift) and "Control+Key" or "KeyPress", KeyCode)
				local UniqueID = newproxy()
				WorkingKey = UniqueID
				task.wait(.25)
				if WorkingKey == UniqueID then
					WorkingKey = true
				end
			end
		end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        	local MousePos = UserInputService:GetMouseLocation()
        	local Direction = GetResizeDirection(MousePos)
        
        	if Direction ~= "" then
            	IsResizing = true
            	ResizeDirection = Direction
            	StartMousePos = MousePos
            	StartFrameSize = editor.Editor.Size
            	StartFramePos = editor.Editor.Position
            	StartEditorSize = ScriptEditor.Size
        	end
    	end
	end)
	Connect(UserInputService.InputEnded, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			BeginSelect = nil
			IsResizing = false
            ResizeDirection = ""
		end
		if Input.KeyCode == Enum.KeyCode.LeftShift then
			LeftShift = false
		end
		if Input.KeyCode == Enum.KeyCode.RightShift then
			RightShift = false
		end
		if Input.KeyCode == Enum.KeyCode.LeftControl then
			LeftCtrl = false
		end
		if Input.KeyCode == Enum.KeyCode.RightControl then
			RightCtrl = false
		end
		Shift = LeftShift or RightShift
		Ctrl = LeftCtrl or RightCtrl
		if PressedKey == Input.KeyCode then
			PressedKey = nil
			WorkingKey = nil
		end
	end)
	Connect(UserInputService.InputChanged, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement and IsResizing then
        	PerformResize(UserInputService:GetMouseLocation())
    	end
	end)
	local Count = 0
	Connect(Heartbeat, function()
		if Count == 0 and WorkingKey == true then
			ProcessInput(not (not Ctrl or Shift) and "Control+Key" or "KeyPress", PressedKey)
		end
		Count = (Count + 1) % 2
	end)
	Editor.Write = Write
	Editor.SetContent = SetContent
	Editor.SetVisibility = SetVisibility
	Editor.PushToUndoStack = PushToUndoStack
	Editor.Undo = Undo
	Editor.Redo = Redo
	function Editor.UpdateTheme(theme)
		for obj, v in next, themestuff do
			for key, value in next, v do
				obj[key] = Themes[theme][value]
			end
		end
		Options.Theme = theme
		ClearTokensAndSelection()
		updateMarkers()
	end
	function Editor.HighlightError(Visible, Line, Msg)
		if Visible then
			ErrorHighlighter.Position = udim2(0, 2, 0, CharHeight * Line + 2 - CharHeight)
			ErrorMessage.Text = "Line " .. Line .. " - " .. Msg
			ErrorMessage.Size = udim2(0, ErrorMessage.TextBounds.X + 15, 0, ErrorMessage.TextBounds.Y + 8)
		else
			ErrorMessage.Visible = false
		end
		ErrorHighlighter.Visible = Visible
	end
	Editor.ContentChanged = ContentChangedEvent.Event
	Editor.FocusLost = FocusLostEvent.Event
	TextArea.CanvasPosition = Vector2_zero
	return Editor, TextBox, ClearTokensAndSelection, TextArea
end

local ScriptEditor, EditorGrid, Clear, TxtArea = EditorLib.Initialize(FindFirstChild(editor, "Editor"), {
	Font = Enum.Font.Code,
	TextSize = 16,
	Language = "Luau",
	CaretBlinkingRate = .5
})

local function DebugScriptAt(o)
	return "WIP -Cesare"
end

local function openScript(o)
	CurrentScript = o
    EditorGrid.Text = ""
    local Triggers = {'--This script could not be decompiled due to it having no bytecode', '"--This script could not be decompiled due to it having no bytecode"'}
    local id = o:GetDebugId()
    if cache[id] then
        ScriptEditor.SetContent(cache[id])
    else
        local guid = tostring(gethiddenproperty(o,"ScriptGuid")) or "{Couldn't grab GUID}"
        local path
        if not o:IsDescendantOf(game) then
            local ancestors = {}
            local current = o
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
            path = "getnilinstances()." .. table.concat(ancestors, ".")
        else
            local TargetPath = o:GetFullName()
            local ServiceName = game:FindFirstChild(TargetPath:match("^[^%.]+")).ClassName
            local Rest = TargetPath:match("^[^%.]+%.(.+)") or ""
            path = string.format("game:GetService(\"%s\")%s", ServiceName, Rest ~= "" and "." .. Rest or "")
        end
		
        local decompiled
        if IsA(o, "LocalScript") or IsA(o, "ModuleScript") then
            decompiled = decompile(o)
            if find(decompiled, Triggers[1]) and not find(decompiled, Triggers[2]) then
                if #o.Source > 0 then
                    decompiled = format("-- Script GUID: %s\n-- Script Path: %s\n\n%s\n", guid, path, o.Source)
                elseif #o.Source <= 0 then
                    decompiled = format("-- Script GUID: %s\n-- Script Path: %s\n-- Electron V3 Decompiler\n-- This script has no bytecode and no source.\n-- It can not be viewed.", guid, path)
                end
            elseif #decompiled <= 0 then
                decompiled = format("-- Script GUID: %s\n-- Script Path: %s\n-- Electron V3 Decompiler\n-- Decompiler returned nothing, script has no bytecode or has anti-decompiler implemented.", guid, path)
            else
				local lines = {}
                for line in decompiled:gmatch("[^\r\n]+") do
                    table.insert(lines, line)
                end
                if #lines > 0 and lines[1]:match("^%s*%-%-") then
                    table.remove(lines, 1)
                    decompiled = table.concat(lines, "\n")
                end
                decompiled = format("-- Script GUID: %s\n-- Script Path: %s\n%s", guid, path, decompiled)
            end
        elseif IsA(o, "Script") then
            local passed = false
            local linkedSource = o.LinkedSource
            if linkedSource and #linkedSource >= 1 then
                local result = tonumber(string.match(linkedSource, "(%d+)"))
                if result then
                    result = format("https://assetdelivery.roblox.com/v1/asset?id=%s", result)
                    decompiled = format("-- Script GUID: %s\n-- Script Path: %s\n-- Open this link in your browser and it will automatically download the source: \n-- %s", guid, path, result)
                    passed = true
                end
            end
            if not passed then
                local sourceAssetId = tonumber(gethiddenproperty(o, "SourceAssetId"))
                if sourceAssetId and sourceAssetId ~= -1 then
                    local asset = LoadLocalAsset(InsertService, "rbxassetid://" .. sourceAssetId)
                    if asset then
                        local source = asset.Source
                        if source and #source > 0 then
                            decompiled = format("-- Script GUID: %s\n-- Script Path: %s\n%s", guid, path, source)
                            passed = true
                        end
                    end
                end
            end
        end
        cache[id] = decompiled
        task.wait(0)
        ScriptEditor.SetContent(cache[id])
    end
    Title.Text = "[Script Viewer] Viewing: " .. o.Name
end

Connect(OpenScript_Bindable.Event, function(object)
	script.Parent.Visible = true
	openScript(object)
end)

Connect(SaveScript.Activated, function()
	if ScriptEditor.Content ~= "" then
		local fileName = FileName.Text
		if fileName == "File Name" or FileName == "" then
			fileName = "LocalScript_" .. random(1, 5000)
		end
		fileName ..= ".lua"
		writefile(fileName, ScriptEditor.Content)
	end
end)

Connect(CopyScript.Activated, function()
	setclipboard(ScriptEditor.Content)
end)

Connect(ClearScript.Activated, function()
	CurrentScript = nil
	ScriptEditor.SetContent("")
	TxtArea.CanvasPosition = Vector2_zero
	Title.Text = "[Script Viewer]"
	Clear()
end)

Connect(DebugScript.Activated, function()
	if not Title.Text:find("Viewing") then return end
    ScriptEditor.SetContent("")
	ScriptEditor.SetContent(DebugScriptAt(CurrentScript))
end)

Connect(CloseEditor.Activated, function()
	script.Parent.Visible = false
end)
