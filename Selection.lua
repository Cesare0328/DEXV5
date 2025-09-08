-- < Fix for module threads not being supported since synapse x > --
local script = getgenv().Dex:WaitForChild("Selection")
-- < Aliases > --
local table_insert = table.insert
local string_format = string.format
local string_sub = string.sub
local string_split = string.split
local os_date = os.date
local UDim2_new = UDim2.new
local Color3_new = Color3.new
local Instance_new = Instance.new
-- < Services > --
local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))
local CoreGui = cloneref( game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local ContentProvider = cloneref(game:GetService("ContentProvider"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
-- < Class Aliases > --
local WaitForChild = RunService.WaitForChild
local FindFirstChild = RunService.FindFirstChild
local GetChildren = RunService.GetChildren
local Clone = RunService.Clone
local Destroy = RunService.Destroy
local JSONDecode = HttpService.JSONDecode
local JSONEncode = HttpService.JSONEncode
local Wait, Connect = (function()
	local A = RunService.Changed
	return A.Wait, A.Connect
end)()
local TweenSize, TweenPosition = (function()
	local A = Instance_new("Frame")
	return A.TweenSize, A.TweenPosition
end)()
-- < Globals > --
getgenv().AssetsCached = false
getgenv().InitLoaded = false
-- < Upvalues > --
local Heartbeat = RunService.Heartbeat
local SelectionBoxes = {}
local Gui = script.Parent
local CurrentSaveInstanceWindow
local SaveCautionWindow = WaitForChild(Dex, "SaveCaution")
local SelectionBox = WaitForChild(script, "Box", 300)
local IntroFrame = WaitForChild(Gui, "IntroFrame")
local SideMenu = WaitForChild(Gui, "SideMenu")
local OpenToggleButton = WaitForChild(Gui, "Toggle")
local CloseToggleButton = WaitForChild(SideMenu, "Toggle")
local OpenScriptEditorButton = WaitForChild(SideMenu, "OpenScriptEditor")
local ConsoleButton = WaitForChild(SideMenu, "Console")
local ScriptEditor = WaitForChild(Gui, "ScriptEditor")
local SlideOut = WaitForChild(SideMenu, "SlideOut")
local SlideFrame = WaitForChild(SlideOut, "SlideFrame")
local Slant = WaitForChild(SideMenu, "Slant")
local ExplorerButton = WaitForChild(SlideFrame, "Explorer")
local SettingsButton = WaitForChild(SlideFrame, "Settings")
local ExplorerPanel = WaitForChild(Gui, "ExplorerPanel")
local PropertiesFrame = WaitForChild(Gui, "PropertiesFrame")
local SaveMapWindow = WaitForChild(Gui, "SaveMapWindow")
local RemoteDebugWindow = WaitForChild(Gui, "RemoteDebugWindow")
local SettingsPanel = WaitForChild(Gui, "SettingsPanel")
local AboutPanel = WaitForChild(Gui, "About")
local SettingHeader = WaitForChild(SettingsPanel, "Header")
local SettingTemplate = WaitForChild(SettingsPanel, "SettingTemplate")
local SettingList = WaitForChild(SettingsPanel, "SettingList")
local SaveMapSettingFrame = WaitForChild(SaveMapWindow, "MapSettings")
local SaveMapButton = WaitForChild(SaveMapWindow, "Save")
local Bindables = WaitForChild(script.Parent, "Bindables", 300)
local SelectionChanged_Bindable = WaitForChild(Bindables, "SelectionChanged", 300)
local GetSetting_Bindable = WaitForChild(Bindables, "GetSetting", 300)
local SetSetting_Bindable = WaitForChild(Bindables, "SetSetting", 300)
local GetSelection_Bindable = WaitForChild(Bindables, "GetSelection", 300)
local SetSelection_Bindable = WaitForChild(Bindables, "SetSelection", 300)
local Player = Players.LocalPlayer
local Mouse = cloneref(Player:GetMouse())
local CurrentWindow = "Nothing c:"
local Windows = {
	Explorer = {
		ExplorerPanel,
		PropertiesFrame
	},
	Settings = {SettingsPanel},
	SaveMap = {SaveMapWindow},
	Remotes = {RemoteDebugWindow},
	About = {AboutPanel}
}
local Writefile = writefile or error("Executor requires writefile function", 0)
local XmlHeader = [[
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
<External>null</External>
<External>nil</External>
]]
local XmlFooter = "</roblox>"
local Blacklist = {
    CoreGui = true,
    Chat = true,
    CorePackages = true
}
local BlacklistModels = {}
local RefCounter = 0
local RefCache = {}
-- < Custom Aliases > --
local wait = task.wait
-- < Source > --
local function BeforeLoad()
	local A, B = pcall(readfile, "dexv5_settings.json")
	local C = A and JSONDecode(HttpService, B) or {}
    local D = "UUID : " .. string.gsub('xxxx-xxxx-xxxx-xxxx', '[x]', function() return string.format('%X', math.random(0, 15)) end) .. "\nVERSION : " .. settings()["Diagnostics"].RobloxVersion
	local IUID, AUID = WaitForChild(IntroFrame, "UUID", 10), WaitForChild(AboutPanel, "UUID", 10)
    IUID.TextWrapped = false
	AUID.TextWrapped = false
    IUID.Text = D
	AUID.Text = D
	if C.Save then
		local E = C.Save
		WaitForChild(SettingHeader, "TextLabel", 10).Text = string_format("Settings | Last Save - %s/%s/%s (%s:%s:%s.%s)", E.Day, E.Month, string_sub(E.Year, #E.Year - 1, #E.Year), E.Hours, E.Minutes, E.Seconds, E.Milliseconds)
	end
end

local function AfterInitialization()
    for _, v in ipairs(Dex:GetDescendants()) do
        if v:IsA("Frame") and v.Name ~= "Other" and v.Name ~= "SettingTemplate" and v.Name ~= "MapSettings" and v.Name ~= "SettingList" and (v.Name ~= "MainWindow" and v.Parent.Name ~= "ModelViewer") then
            local TL = Instance.new("TextLabel")
            TL.Name = "InputBlocker"
            TL.Active = v.Visible
            TL.BackgroundTransparency = 1
            TL.TextTransparency = 1
            TL.Size = UDim2.new(1, 0, 1, 0)
            TL.Parent = v
        end
    end
end

BeforeLoad()
AfterInitialization()

local function switchWindows(p1, p2)
	if CurrentWindow == p1 and not p2 then return end
	local A = 0
	for B, C in next, Windows do
		A = 0
		if B ~= p1 then
			for D, E in next, C do 
				local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local goal = {Position = UDim2_new(1, 30, A * 0.5, A * 36)}
				TweenService:Create(E, tweenInfo, goal):Play()
				A += 1
			end
		end
	end
	A = 0
	if Windows[p1] then
		for F, G in next, Windows[p1] do 
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local goal = {Position = UDim2_new(1, -300, A * 0.5, A * 36)}
			TweenService:Create(G, tweenInfo, goal):Play()
			A += 1
		end
	end
	if p1 ~= "Nothing c:" then
		CurrentWindow = p1
		for H, I in ipairs(GetChildren(SlideFrame)) do
            if not I:IsA("TextLabel") then
			    I.BackgroundTransparency = 1
			    I.Icon.ImageColor3 = Color3_new(.6, .6, .6)
            end
		end
		local J = FindFirstChild(SlideFrame, p1)
		if J then
			J.BackgroundTransparency = 1
			J.Icon.ImageColor3 = Color3_new(1,1,1)
		end
	end
end

local function toggleDex(p1)
	TweenPosition(SideMenu, p1 and UDim2_new(1, -330, 0, 0) or UDim2_new(1, 0, 0, 0), "Out", "Quad", .5, true)
	TweenPosition(OpenToggleButton, p1 and UDim2_new(1, 0, 0, 0) or UDim2_new(1, -40, 0, 0), "Out", "Quad", .5, true)
	switchWindows(p1 and CurrentWindow or "Nothing c:", p1 and true or nil)
end

local SaveMapSettings = {
	SaveScripts = true,
	AvoidPlayerCharacters = true,
	SaveNilInstances = true,
	CloseRobloxAfterSave = true,
    ProgressiveSave = false,
    Compress = true
}

local Settings = {
	ClickSelect = false,
	SelBox = false,
	ClearProps = false,
	SelectUngrouped = true,
	SkipToAfterSearch = true,
	UseInstanceBlacklist = true,
	UseRealclassName = false,
	RSSIncludeRL = false
}

pcall(function()
	local A, B = pcall(readfile, "dexv5_settings.json")
	if A then
		local C = JSONDecode(HttpService, B).Settings
		for D, E in next, C do
			if Settings[D] then
				Settings[D] = E
			end
		end
	end
end)

function SaveSettings()
	local A = {}
	local B = os_date("*t")
	local C, D, E, F, G = B.day, B.month, B.hour, B.min, B.sec
	A.Settings = Settings
	A.Save = {
		Day = ((C < 10) and "0"..tostring(C) or tostring(C)),
		Month = ((D < 10) and "0"..tostring(D) or tostring(D)),
		Year = tostring(B.year),
		Hours = ((E < 10) and "0"..tostring(E) or tostring(E)),
		Minutes = ((F < 10) and "0"..tostring(F) or tostring(F)),
		Seconds = ((G < 10) and "0"..tostring(G) or tostring(G)),
		Milliseconds = string_split(tick(),".")[2] or 0
	}
	pcall(writefile, "dexv5_settings.json", JSONEncode(HttpService, A))
end

Connect(OpenToggleButton.MouseButton1Up, function()
	toggleDex(true)
end)

Connect(OpenScriptEditorButton.MouseButton1Up, function()
	ScriptEditor.Visible = not ScriptEditor.Visible 
end)

Connect(ConsoleButton.MouseButton1Up, function()
    Dex.Console.Visible = not Dex.Console.Visible
end)

Connect(CloseToggleButton.MouseButton1Up, function()
	toggleDex(not CloseToggleButton.Active)
end)

for _,v in ipairs(GetChildren(SlideFrame)) do
    if not v:IsA("TextLabel") then
	    Connect(v.Activated, function()
		    switchWindows(tostring(v))
	    end)
    end
end

local function createSettingTitle(p1)
	local A = Instance.new("TextLabel")
	A.Name = "SettingLabel"
	A.Position = UDim2_new(0, 0, 0, #SettingList:GetChildren() * 60)
	A.Size = UDim2_new(1, 0, 0, 60)
	A.BackgroundTransparency = 1
	A.Font = Enum.Font.Arial
	A.TextSize = 18
	A.TextColor3 = Color3.new(1, 1, 1)
	A.Text = p1
	A.TextXAlignment = Enum.TextXAlignment.Center
	A.TextYAlignment = Enum.TextYAlignment.Center
	A.Visible = true
	A.Parent = SettingList
end

local function createSetting(p1, p2, p3, p5)
	local A = Clone(SettingTemplate)
	local pos = #SettingList:GetChildren() * 60
	if p5 then pos = pos - ((1 * pos) / 100) end
	A.Position = UDim2_new(0, 0, 0, pos)
	A.SName.Text = p1
	local B = A.Change
	local function C(p4)
		TweenPosition(B.Bar, p4 and UDim2_new(0,32,0,-2) or UDim2_new(0,-2,0,-2), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .25,true)
		TweenSize(B.OnBar, p4 and UDim2_new(0,40,0,15) or UDim2_new(0,0,0,15), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .25,true)
		A.Status.Text = p4 and "On" or "Off"
		Settings[p2] = p4 and true or false
	end	
	Connect(B.Activated, function()
		C(not Settings[p2])
		SetSetting_Bindable:Invoke(p2, not Settings[p2])
		task.wait(1 / 12)
		pcall(SaveSettings)
	end)
	A.Visible = true
	A.Parent = SettingList
	C(p3)
end

createSettingTitle("DEX SETTINGS")
createSetting("CLICK TO SELECT PART", "ClickSelect", Settings.ClickSelect, true)
createSetting("SHOW SELECTION BOX", "SelBox", Settings.SelBox)
createSetting("CLEAR PROPERTY VALUE ON FOCUS", "ClearProps", Settings.ClearProps)
createSetting("SELECT UNGROUPED MODELS" , "SelectUngrouped", Settings.SelectUngrouped)
createSetting("JUMP TO SELECTED OBJECT AFTER SEARCH EXIT", "SkipToAfterSearch", Settings.SkipToAfterSearch)
createSetting("HIDE UNNECESSARY SERVICES (REQUIRES RESTART)", "UseInstanceBlacklist", Settings.UseInstanceBlacklist)
createSetting("SHOW TRUE 'Instance' names (REQUIRES RESTART)", "UseRealclassName", Settings.UseRealclassName)
createSetting("SCRIPT STORAGE INCLUDES RobloxLocked SCRIPTS", "RSSIncludeRL", Settings.RSSIncludeRL)
createSettingTitle("ENVIRONMENT SETTINGS")
createSetting("SHOW BOUNDING BOXES", "BBoxes", Settings.BBoxes, true)
createSetting("SHOW MODEL REGIONS", "MRegions", Settings.MRegions)
createSetting("SHOW DECOMPOSITIONS", "Dcmptions", Settings.Dcmptions)
createSetting("SHOW NODES", "SNodes", Settings.SNodes)
createSetting("SHOW MECHANISMS", "SMechs", Settings.SMechs)
createSettingTitle("ANIMATION SETTINGS")
createSetting("SHOW ACTIVE ANIMATIONS", "AAnims", Settings.AAnims, true)

local function getSelection()
	local A = GetSelection_Bindable:Invoke()
	return (A and #A > 0) and A or {}
end

Connect(UserInputService.InputBegan, function(Input, GameProcessed)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 and CurrentWindow == "Explorer" and Settings.ClickSelect then
        pcall(SetSelection_Bindable.Invoke, SetSelection_Bindable, {Mouse.Target})
    end
end)

Connect(SelectionChanged_Bindable.Event, function()
	local A = getSelection()
	local function CleanSelectionBoxes()
		for _, C in ipairs(SelectionBoxes) do
			Destroy(C)
		end
	end
	local function CreateSelectionBoxes()
		for D, E in next, A do
			if typeof(E) == "Instance" then
				local F = Clone(SelectionBox)
				F.Adornee = E
				F.Parent = CoreGui
				table_insert(SelectionBoxes, F)
			end
		end
	end
	if Settings.SelBox then
		CleanSelectionBoxes()
		CreateSelectionBoxes()
	end
end)

function GetSetting_Bindable.OnInvoke(p1)
	local A = Settings[p1]
	if A then
		return A
	end
end

local function createMapSetting(p1, p2, p3)
	local A = p1.Change
	local function B(on)
		TweenPosition(A.Bar, on and UDim2_new(0, 32, 0, -2) or UDim2_new(0, -2, 0, -2), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .25, true)
		TweenSize(A.OnBar, on and UDim2_new(0, 40, 0, 15) or UDim2_new(0, 0, 0, 15), Enum.EasingDirection.Out,  Enum.EasingStyle.Quart, .25, true)
		p1.Status.Text = on and "On" or "Off"
		SaveMapSettings[p2] = on and true or false
	end	
	Connect(A.Activated, function()
		B(not SaveMapSettings[p2])
	end)
	p1.Visible = true
	p1.Parent = SaveMapSettingFrame
	if p3 then
		B(true)
	end
end

local function EscapeXml(value)
    if value == nil then
        return "Unnamed"
    end
    return tostring(value):gsub("[&<>\"']", {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&apos;"
    })
end
local function GetRef(instance)
    if instance == nil then
        RefCounter = RefCounter + 1
        local nilKey = "nil_" .. RefCounter
        if not RefCache[nilKey] then
            RefCache[nilKey] = "RBX" .. RefCounter
        end
        return RefCache[nilKey]
    end
    if not RefCache[instance] then
        RefCounter = RefCounter + 1
        RefCache[instance] = "RBX" .. RefCounter
    end
    return RefCache[instance]
end
local PropertySerializers = {
    string = function(name, value)
        if name == "MeshId" or name == "TextureId" or name == "TextureID" or name == "Texture" then
            if value == "" then
                return string.format('<Content name="%s"><null></null></Content>', name)
            else
                return string.format('<Content name="%s"><url>%s</url></Content>', name, EscapeXml(value))
            end
        elseif name == "PhysicsGrid" or name == "SmoothGrid" then
            return string.format('<BinaryString name="%s"><![CDATA[%s]]></BinaryString>', name, EscapeXml(value))
        else
            return string.format('<string name="%s">%s</string>', name, EscapeXml(value))
        end
    end,

    boolean = function(name, value)
        return string.format('<bool name="%s">%s</bool>', name, tostring(value):lower())
    end,

    customfloat = function(name, value)
        return string.format('<float name="%s">%s</float>', name, tostring(value))
    end,

    number = function(name, value)
        local s_value = tostring(value)
        if s_value:find("[.eE]") then
            local formatted_val = string.format('%.9f', value):gsub('0*$', ''):gsub('\\.$', '')
            return string.format('<float name="%s">%s</float>', name, formatted_val)
        else
            return string.format('<int name="%s">%d</int>', name, value)
        end
    end,

    Vector3 = function(name, value)
        if name == "Size" then name = "size" end
        return string.format('<Vector3 name="%s"><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></Vector3>', name, value.X, value.Y, value.Z)
    end,

    CFrame = function(name, value)
        local c = {value:GetComponents()}
        if name == "WorldPivot" then
            name = "WorldPivotData"
            return string.format('<OptionalCoordinateFrame name="%s"><CFrame><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z><R00>%.6f</R00><R01>%.6f</R01><R02>%.6f</R02><R10>%.6f</R10><R11>%.6f</R11><R12>%.6f</R12><R20>%.6f</R20><R21>%.6f</R21><R22>%.6f</R22></CFrame></OptionalCoordinateFrame>', name, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
        else
            return string.format('<CoordinateFrame name="%s"><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z><R00>%.6f</R00><R01>%.6f</R01><R02>%.6f</R02><R10>%.6f</R10><R11>%.6f</R11><R12>%.6f</R12><R20>%.6f</R20><R21>%.6f</R21><R22>%.6f</R22></CoordinateFrame>', name, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
        end
    end,

    EnumItem = function(name, value)
        return string.format('<token name="%s">%s</token>', name, value.Value)
    end,

    Color3 = function(name, value)
        return string.format('<Color3 name="%s"><R>%.6f</R><G>%.6f</G><B>%.6f</B></Color3>', name, value.R, value.G, value.B)
    end,

    BrickColor = function(name, value)
        return string.format('<BrickColor name="%s">%d</BrickColor>', name, value.Number)
    end,

    Instance = function(name, value)
        return string.format('<Ref name="%s">%s</Ref>', name, value and GetRef(value) or "null")
    end,

    UDim2 = function(name, value)
        return string.format('<UDim2 name="%s"><XS>%.6f</XS><XO>%d</XO><YS>%.6f</YS><YO>%d</YO></UDim2>', name, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    end,

    Vector2 = function(name, value)
        return string.format('<Vector2 name="%s"><X>%.6f</X><Y>%.6f</Y></Vector2>', name, value.X, value.Y)
    end,

    Rect = function(name, value)
        return string.format('<Rect2D name="%s"><min><X>%.6f</X><Y>%.6f</Y></min><max><X>%.6f</X><Y>%.6f</Y></max></Rect2D>', name, value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
    end,

    Faces = function(name, value)
        local bitfield = 0
        if value.Top then bitfield = bitfield + 1 end
        if value.Bottom then bitfield = bitfield + 2 end
        if value.Left then bitfield = bitfield + 4 end
        if value.Right then bitfield = bitfield + 8 end
        if value.Front then bitfield = bitfield + 16 end
        if value.Back then bitfield = bitfield + 32 end
        return string.format('<Faces name="%s"><faces>%d</faces></Faces>', name, bitfield)
    end,

    Axes = function(name, value)
        return string.format('<Axes name="%s">%d</Axes>', name, value.Value)
    end,
    
    UDim = function(name, value)
        return string.format('<UDim name="%s"><S>%.6f</S><O>%d</O></UDim>', name, value.Scale, value.Offset)
    end,

    ColorSequence = function(name, value)
        local points = ""
        for _, keypoint in ipairs(value.Keypoints) do
            points = points .. string.format('<ColorSequenceKeypoint><Time>%.6f</Time><Value><R>%.6f</R><G>%.6f</G><B>%.6f</B></Value></ColorSequenceKeypoint>', keypoint.Time, keypoint.Value.R, keypoint.Value.G, keypoint.Value.B)
        end
        return string.format('<ColorSequence name="%s">%s</ColorSequence>', name, points)
    end,

    NumberSequence = function(name, value)
        local points = ""
        for _, keypoint in ipairs(value.Keypoints) do
            points = points .. string.format('<NumberSequenceKeypoint><Time>%.6f</Time><Value>%.6f</Value><Envelope>%.6f</Envelope></NumberSequenceKeypoint>', keypoint.Time, keypoint.Value, keypoint.Envelope)
        end
        return string.format('<NumberSequence name="%s">%s</NumberSequence>', name, points)
    end,

    NumberRange = function(name, value)
        return string.format('<NumberRange name="%s">%.6f %.6f</NumberRange>', name, value.Min, value.Max)
    end,

    PhysicalProperties = function(name, value)
        local success, custom = pcall(function() return value.CustomPhysicalProperties end)
        if success and custom then
            return string.format('<PhysicalProperties name="%s"><CustomPhysics>true</CustomPhysics><Density>%.6f</Density><Friction>%.6f</Friction><Elasticity>%.6f</Elasticity><FrictionWeight>%.6f</FrictionWeight><ElasticityWeight>%.6f</ElasticityWeight></PhysicalProperties>', name, value.Density, value.Friction, value.Elasticity, value.FrictionWeight, value.ElasticityWeight)
        end
        return string.format('<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics><Density>%.6f</Density><Friction>%.6f</Friction><Elasticity>%.6f</Elasticity><FrictionWeight>%.6f</FrictionWeight><ElasticityWeight>%.6f</ElasticityWeight></PhysicalProperties>', name, value.Density, value.Friction, value.Elasticity, value.FrictionWeight, value.ElasticityWeight)
    end,

    Font = function(name, value)
        return string.format('<Font name="%s"><Family><url>%s</url></Family><Weight>%d</Weight><Style>%s</Style></Font>', name, EscapeXml(value.Family), value.Weight.Value, value.Style.Name)
    end,
    
    Region3 = function(name, value)
        return string.format('<Region3 name="%s"><min><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></min><max><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></max></Region3>', name, value.CFrame.X - value.Size.X/2, value.CFrame.Y - value.Size.Y/2, value.CFrame.Z - value.Size.Z/2, value.CFrame.X + value.Size.X/2, value.CFrame.Y + value.Size.Y/2, value.CFrame.Z + value.Size.Z/2)
    end,

    Region3int16 = function(name, value)
        return string.format('<Region3int16 name="%s"><min><X>%d</X><Y>%d</Y><Z>%d</Z></min><max><X>%d</X><Y>%d</Y><Z>%d</Z></max></Region3int16>', name, value.Min.X, value.Min.Y, value.Min.Z, value.Max.X, value.Max.Y, value.Max.Z)
    end,
    
    double = function(name, value)
        return string.format('<double name="%s">%.16e</double>', name, value)
    end,

    int64 = function(name, value)
        return string.format('<int64 name="%s">%d</int64>', name, value)
    end,

    BinaryString = function(name, value)
        return string.format('<BinaryString name="%s">%s</BinaryString>', name, value)
    end,

    SharedString = function(name, value)
        return string.format('<SharedString name="%s">%s</SharedString>', name, value)
    end,

    UniqueId = function(name, value)
        return string.format('<UniqueId name="%s">%s</UniqueId>', name, value)
    end,

    OptionalCoordinateFrame = function(name, value)
        if value then
            local c = {value.Value:GetComponents()}
            return string.format('<OptionalCoordinateFrame name="%s"><CFrame><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z><R00>%.6f</R00><R01>%.6f</R01><R02>%.6f</R02><R10>%.6f</R10><R11>%.6f</R11><R12>%.6f</R12><R20>%.6f</R21><R22>%.6f</R22></CFrame></OptionalCoordinateFrame>', name, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
        else
            return string.format('<OptionalCoordinateFrame name="%s"/>', name)
        end
    end
}
local function CountInstances(instance, avoidPlayerCharacters)
    local count = 1
    if Blacklist[instance.ClassName] or Blacklist[instance.Name] then
        return 0
    end
    if avoidPlayerCharacters and instance:IsA("Model") and Players:GetPlayerFromCharacter(instance) then
        return 0
    end
    for _, child in ipairs(instance:GetChildren()) do
        count = count + CountInstances(child, avoidPlayerCharacters)
    end
    return count
end

local function StartScaleBasedRendering(base, scale, interval, max, TitleLabel)
local base = base
repeat task.wait()
    TitleLabel.Text = string.format("Rendering [%s/%s]", tostring(base), tostring(max))
    sethiddenproperty(workspace, "StreamingMinRadius", base)
    sethiddenproperty(workspace, "StreamingTargetRadius", base + base)
    Player:RequestStreamAroundAsync(workspace.CurrentCamera.CFrame.p)
    base += scale
    task.wait(interval)
until base >= max
end

local function HandleAddition(Instance, Type, Scale, Base, ArgumentList)
local AddHover = true
Connect(Instance.MouseEnter, function()
	AddHover = true
end)
Connect(Instance.MouseLeave, function()
	AddHover = false
end)
Instance.MouseButton1Down:Connect(function()
    if CurrentSaveInstanceWindow then
        for _, v in pairs(GetChildren(ArgumentList)) do
            if v:FindFirstChild("Type") and v.Type.Text == Type then
                local success, val = pcall(tonumber, v.Value.Text)
                if success and val then
					val += Scale
                    v.Value.Text = tostring(val)
					task.wait(1)
					while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and AddHover do
						val += Scale
                    	v.Value.Text = tostring(val)
					    task.wait(0.05)
					end
                else
                    v.Value.Text = tostring(Base)
                end
            end
        end
    end
end)
end

local function HandleSubtraction(Instance, Type, Scale, Base, ArgumentList)
local SubHover = true
Connect(Instance.MouseEnter, function()
	SubHover = true
end)
Connect(Instance.MouseLeave, function()
	SubHover = false
end)
Instance.MouseButton1Down:Connect(function()
    if CurrentSaveInstanceWindow then
		for _, v in pairs(GetChildren(ArgumentList)) do
            if v.Type.Text == Type then
                local success, val = pcall(tonumber, v.Value.Text)
                if success and val then
					val -= Scale
					if val < Base then v.Value.Text = tostring(Base) else v.Value.Text = tostring(val) end
					task.wait(1)
					while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and SubHover do
						val -= Scale
						if val < Base then v.Value.Text = tostring(Base) else v.Value.Text = tostring(val) end
						task.wait(0.05)
					end
                else
                    v.Value.Text = tostring(Base)
                end
            end
        end
	end
end)
end
local function PromptStreamingEnabledCaution(TitleLabel)
    TitleLabel.Text = "Waiting..."
    local response = nil
    local ATDict = {[1] = nil, [2] = nil, [3] = nil, [4] = nil}
    local ATDictScale = {[1] = 500, [2] = 500, [3] = 0.5, [4] = 500}
    local ATDictBase = {[1] = 1000, [2] = 500, [3] = 0.5, [4] = 2500}
    if CurrentSaveInstanceWindow then
		Destroy(CurrentSaveInstanceWindow)
		CurrentSaveInstanceWindow = nil
	end
	CurrentSaveInstanceWindow = Clone(SaveCautionWindow)
	CurrentSaveInstanceWindow.Parent = Dex
	CurrentSaveInstanceWindow.Visible = true
    
    local AddHover, SubHover, ArgumentList, ArgumentTemplate = false, false, CurrentSaveInstanceWindow.MainWindow.Arguments, CurrentSaveInstanceWindow.MainWindow.ArgumentTemplate

	local BaseArg = Clone(ArgumentTemplate)
    BaseArg.Size = UDim2_new(0, 270, 0, BaseArg.Size.Y.Offset)
	BaseArg.Parent = ArgumentList
	BaseArg.Visible = true
    BaseArg.Value.Text = tostring(ATDictBase[1])
    ATDict[1] = BaseArg
	createDDown(BaseArg.Type, TitleLabel, "Base Render")

    local ScaleArg = Clone(ArgumentTemplate)
    ScaleArg.Size = UDim2_new(0, 270, 0, ScaleArg.Size.Y.Offset)
    ScaleArg.Position = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
	ArgumentList.CanvasSize = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
    ScaleArg.Parent = ArgumentList
	ScaleArg.Visible = true
    ScaleArg.Value.Text = tostring(ATDictBase[2])
    ATDict[2] = ScaleArg
	createDDown(ScaleArg.Type, TitleLabel, "Scale Render")

    local IntervalArg = Clone(ArgumentTemplate)
    IntervalArg.Size = UDim2_new(0, 270, 0, IntervalArg.Size.Y.Offset)
    IntervalArg.Position = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
	ArgumentList.CanvasSize = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
    IntervalArg.Parent = ArgumentList
	IntervalArg.Visible = true
    IntervalArg.Value.Text = tostring(ATDictBase[3])
    ATDict[3] = IntervalArg
	createDDown(IntervalArg.Type, TitleLabel, "Interval")

    local MaxArg = Clone(ArgumentTemplate)
    MaxArg.Size = UDim2_new(0, 270, 0, MaxArg.Size.Y.Offset)
    MaxArg.Position = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
	ArgumentList.CanvasSize = UDim2_new(0,0,0,#GetChildren(ArgumentList) * 20)
    MaxArg.Parent = ArgumentList
	MaxArg.Visible = true
    MaxArg.Value.Text = tostring(ATDictBase[4])
    ATDict[4] = MaxArg
	createDDown(MaxArg.Type, TitleLabel, "Max Render")

    for i = 1, 4 do
        HandleAddition(CurrentSaveInstanceWindow.MainWindow["Add" .. tostring(i)], ATDict[i].Type.Text, ATDictScale[i], ATDictBase[i], ArgumentList)
    end
    for i = 1, 4 do
        HandleSubtraction(CurrentSaveInstanceWindow.MainWindow["Subtract" .. tostring(i)], ATDict[i].Type.Text, ATDictScale[i], ATDictBase[i], ArgumentList)
    end
    Connect(CurrentSaveInstanceWindow.MainWindow.Ok.MouseButton1Up, function()
		if CurrentSaveInstanceWindow then
            TitleLabel.Text = "Starting..."
			local success, val = pcall(tonumber, BaseArg.Value.Text)
			local success2, val2 = pcall(tonumber, ScaleArg.Value.Text)
			local success3, val3 = pcall(tonumber, IntervalArg.Value.Text)
			local success4, val4 = pcall(tonumber, MaxArg.Value.Text)
			
            Destroy(CurrentSaveInstanceWindow)
			CurrentSaveInstanceWindow = nil
			StartScaleBasedRendering(val or ATDictBase[1], val2 or ATDictBase[2], val3 or ATDictBase[3], val4 or ATDictBase[4], TitleLabel)
            response = true
		end
	end)
    Connect(CurrentSaveInstanceWindow.MainWindow.Cancel.MouseButton1Up, function()
		if CurrentSaveInstanceWindow then
            Destroy(CurrentSaveInstanceWindow)
			CurrentSaveInstanceWindow = nil
			response = false
		end
	end)
    while response == nil do
        task.wait()
    end
    return response
end

local function SerializeInstance(instance, output, saveScripts, avoidPlayerCharacters, saveNilInstances, processed, total, statusCallback)
    if SaveMapSettings.ProgressiveSave and not instance == workspace.CurrentCamera then task.wait(0) end
    if instance.ClassName:find("Wrap") then return processed end
    if instance:IsA("Bone") and (not instance.Parent or not instance.Parent:IsA("BasePart") or instance.Parent:IsA("Bone")) then return processed end
    if Blacklist[instance.ClassName] or Blacklist[instance.Name] then
        statusCallback(processed, total, "Skipping blacklisted instance: " .. (instance:GetFullName() or "Unnamed"))
        return processed
    end

    if avoidPlayerCharacters and instance:IsA("Model") and Players:GetPlayerFromCharacter(instance) then
        table.insert(BlacklistModels, instance)
        statusCallback(processed, total, "Skipping player character: " .. (instance:GetFullName() or "Unnamed"))
        return processed
    end
    
    for _,v in pairs(BlacklistModels) do
    if instance:IsDescendantOf(v) then
        statusCallback(processed, total, "Skipping player character object: " .. (instance:GetFullName() or "Unnamed"))
        return processed
    end
    end
    
    statusCallback(processed, total, "Processing: " .. (instance:GetFullName() or "Unnamed"))
    processed = processed + 1

    local isLocalPlayer = instance == Player
    local ref = GetRef(instance)
    local scriptSource = nil

    if isLocalPlayer then
        table.insert(output, string.format('<Item class="Folder" referent="%s">', ref))
        table.insert(output, string.format('<string name="Name">%s</string>', EscapeXml(instance.Name .. "[LocalPlayer]")))
    else
        table.insert(output, string.format('<Item class="%s" referent="%s">', instance.ClassName or "Unknown", ref))
        table.insert(output, "<Properties>")
        table.insert(output, PropertySerializers.string("Name", instance.Name or "Unnamed"))

        local properties = {}
        if instance:IsA("BasePart") then
            properties = {
                Position = instance.Position,
                Size = instance.Size,
                CFrame = instance.CFrame,
                Color = instance.Color,
                BrickColor = instance.BrickColor,
                Transparency = instance.Transparency,
                Reflectance = instance.Reflectance,
                Anchored = instance.Anchored,
                CanCollide = instance.CanCollide,
                CastShadow = instance.CastShadow,
                Massless = instance.Massless,
                TopSurface = instance.TopSurface,
                BottomSurface = instance.BottomSurface,
                FrontSurface = instance.FrontSurface,
                BackSurface = instance.BackSurface,
                LeftSurface = instance.LeftSurface,
                RightSurface = instance.RightSurface,
                Material = instance.Material,
                Rotation = instance.Rotation
            }
            if instance:IsA("MeshPart") then
                properties.MeshId = instance.MeshId
                properties.TextureID = instance.TextureID
                properties.InitialSize = gethiddenproperty(instance, "InitialSize")
            end
            if instance:IsA("PartOperation") then
                properties.InitialSize = gethiddenproperty(instance, "InitialSize")
            end
            if instance:IsA("BasePart") and instance.MaterialVariant ~= "" then
                properties.MaterialVariant = instance.MaterialVariant
            end
            if instance:IsA("Part") then
                properties.Shape = instance.Shape
            end
        elseif instance:IsA("SpecialMesh") then
            properties = {
                MeshId = instance.MeshId,
                MeshType = instance.MeshType,
                Offset = instance.Offset,
                Scale = instance.Scale,
                VertexColor = instance.VertexColor,
                TextureId = instance.TextureId
            }
        elseif instance:IsA("Model") then
            properties = {
                PrimaryPart = instance.PrimaryPart,
                WorldPivot = instance.WorldPivot,
                ScaleFactor = instance:GetScale(),
                ModelMeshCFrame = gethiddenproperty(instance, "ModelMeshCFrame"),
                ModelMeshSize = gethiddenproperty(instance, "ModelMeshSize")
            }
        elseif saveScripts and (instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")) then
            local guid = tostring(gethiddenproperty(instance, "ScriptGuid")) or "{Couldn't grab GUID}"
            local triggers = '--This script could not be decompiled due to it having no bytecode'
            local path

            if not instance:IsDescendantOf(game) then
                local ancestors = {}
                local current = instance
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
                local current = instance
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

            scriptSource = "-- Failed to get source"
            if instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
                local bytecode = getscriptbytecode(instance) or ""
                if #bytecode == 0 then
                    if instance:IsA("LocalScript") then
                        scriptSource = string.format("-- Script GUID: NULL\n-- Script Path: %s\n-- Electron V3 Decompiler\n-- This script is an electron script.\n-- It can not be viewed.", path)
                    end
                else
                    local success, result = pcall(decompile, instance)
                    if success then
                        if result:find(triggers, 1, true) then
                            local sSuccess, sSource = pcall(function() return instance.Source end)
                            if sSuccess and #sSource > 0 then
                                scriptSource = string.format("-- Script GUID: %s\n-- Script Path: %s\n\n%s\n", guid, path, sSource)
                            else
                                scriptSource = string.format("-- Script GUID: %s\n-- Script Path: %s\n-- Electron V3 Decompiler\n-- This script has no bytecode and no source.\n-- It can not be viewed.", guid, path)
                            end
                        elseif #result <= 0 then
                            scriptSource = string.format("-- Script GUID: %s\n-- Script Path: %s\n-- Electron V3 Decompiler\n-- Decompiler returned nothing, script has no bytecode or has anti-decompiler implemented.", guid, path)
                        else
                            local lines = {}
                            for line in result:gmatch("[^\r\n]+") do
                                table.insert(lines, line)
                            end
                            if #lines > 0 and lines[1]:match("^%s*%-%-") then
                                table.remove(lines, 1)
                            end
                            if not instance:IsA("ModuleScript") then
                                scriptSource = string.format("-- Script GUID: %s\n-- Script Path: %s\n%s", guid, path, table.concat(lines, "\n"))
                            end
                        end
                    else
                        scriptSource = string.format("-- Script GUID: %s\n-- Script Path: %s\n-- Decompilation failed: %s", guid, path, tostring(result))
                    end
                end
            elseif instance:IsA("Script") then
                local passed = false
                local linkedSource = instance.LinkedSource
                if linkedSource and #linkedSource >= 1 then
                    local result = tonumber(string.match(linkedSource, "(%d+)"))
                    if result then
                        result = string.format("https://assetdelivery.roblox.com/v1/asset?id=%s", result)
                        scriptSource = string.format("-- Script GUID: %s\n-- Script Path: %s\n-- Open this link in your browser and it will automatically download the source: \n-- %s", guid, path, result)
                        passed = true
                    end
                end
                if not passed then
                    local sourceAssetId, success = gethiddenproperty(instance, "SourceAssetId")
                    if success and sourceAssetId and sourceAssetId ~= -1 then
                        local asset = LoadLocalAsset(InsertService, "rbxassetid://" .. sourceAssetId)
                        if asset then
                            local source = asset.Source
                            if source and #source > 0 then
                                scriptSource = string.format("-- Script GUID: %s\n-- Script Path: %s\n%s", guid, path, source)
                                passed = true
                            end
                        end
                    end
                end
                if not passed then
                    scriptSource = string.format("-- Script GUID: %s\n-- ServerScript", guid)
                end
            end
        properties = {
            Source = scriptSource,
            Enabled = instance:IsA("Script") or instance:IsA("LocalScript") and instance.Enabled or false
        }
        elseif instance:IsA("Decal") then
            properties = {
                Texture = instance.Texture,
                Transparency = instance.Transparency,
                Face = tostring(instance.Face)
            }
        elseif instance:IsA("PointLight") then
            properties = {
                Brightness = instance.Brightness,
                Color = instance.Color,
                Enabled = instance.Enabled,
                Range = instance.Range,
                Shadows = instance.Shadows
            }
        elseif instance:IsA("SpotLight") then
            properties = {
                Brightness = instance.Brightness,
                Color = instance.Color,
                Enabled = instance.Enabled,
                Range = instance.Range,
                Shadows = instance.Shadows,
                Angle = instance.Angle,
                Face = tostring(instance.Face)
            }
        elseif instance:IsA("SurfaceLight") then
            properties = {
                Brightness = instance.Brightness,
                Color = instance.Color,
                Enabled = instance.Enabled,
                Range = instance.Range,
                Shadows = instance.Shadows,
                Angle = instance.Angle
            }
        elseif instance:IsA("BlurEffect") then
            properties = {
                Enabled = instance.Enabled,
                Size = instance.Size
            }
        end
        if instance:IsA("Terrain") then
            properties = {
                PhysicsGrid = base64.encode(gethiddenproperty(instance, "PhysicsGrid")),
                SmoothGrid = base64.encode(gethiddenproperty(instance, "SmoothGrid")),
                GrassLength = gethiddenproperty(instance, "GrassLength"),
                Decoration = gethiddenproperty(instance, "Decoration"),
                AcquisitionMethod = gethiddenproperty(instance, "AcquisitionMethod")
            }
        end
        for _,v in pairs(getproperties(instance)) do
            local success, val = pcall(function() return instance[v] end)
            if success and val ~= nil and v ~= "Parent" and v ~= "brickcolor" and v ~= "className" and v ~= "archivable" and v ~= "formFactor" and v ~= "Name" and PropertySerializers[typeof(val)] then
                properties[v] = instance[v]
            end
        end

        for propName, propValue in pairs(properties) do
            local propType = typeof(propValue)
            local serializer = PropertySerializers[propType]
            if propName == "Source" and scriptSource then
                local eS = tostring(scriptSource):gsub("]]>", "]]]]><![CDATA[>")
                table.insert(output, string.format('<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>', eS))
            elseif propName == "ScaleFactor" then
                table.insert(output, PropertySerializers.customfloat(propName, propValue))
            elseif serializer and propValue ~= nil then
                if instance == workspace.CurrentCamera and propName == "CameraType" then
                    table.insert(output, serializer(propName, Enum.CameraType.Fixed))
                else
                    table.insert(output, serializer(propName, propValue))
                end
            end
        end

        table.insert(output, "</Properties>")
    end

    for _, child in ipairs(instance:GetChildren()) do
        processed = SerializeInstance(child, output, saveScripts, avoidPlayerCharacters, saveNilInstances, processed, total, statusCallback)
    end

    table.insert(output, "</Item>")
    return processed
end

local function XMLtoBinary(InputXMLFile, OutputRBXLFile)
    local function WriteString(Buffer, Offset, String)
        local StringBytes = buffer.fromstring(String)
        buffer.writeu32(Buffer, Offset, #String)
        buffer.copy(Buffer, Offset + 4, StringBytes, 0, #String)
        return Offset + 4 + #String
    end

    local function TransformInt32(Value)
        if Value >= 0 then
            return 2 * Value
        else
            return 2 * math.abs(Value) - 1
        end
    end

    local function WriteFloat32Roblox(Buffer, Offset, Value)
        local Bytes = buffer.create(4)
        buffer.writef32(Bytes, 0, Value)
        local Byte0 = buffer.readu8(Bytes, 0)
        local Byte1 = buffer.readu8(Bytes, 1)
        local Byte2 = buffer.readu8(Bytes, 2)
        local Byte3 = buffer.readu8(Bytes, 3)
        local Sign = bit32.rshift(Byte0, 7)
        Byte0 = bit32.band(Byte0, 0x7F)
        Byte3 = bit32.bor(bit32.lshift(Byte3, 1), Sign)
        buffer.writeu8(Buffer, Offset, Byte0)
        buffer.writeu8(Buffer, Offset + 1, Byte1)
        buffer.writeu8(Buffer, Offset + 2, Byte2)
        buffer.writeu8(Buffer, Offset + 3, Byte3)
        return Offset + 4
    end

    local function GetAxisIndex(Column)
        local AxisX = math.abs(Column[1])
        local AxisY = math.abs(Column[2])
        local AxisZ = math.abs(Column[3])
        if AxisX > AxisY and AxisX > AxisZ then
            return Column[1] > 0 and 0 or 1
        elseif AxisY > AxisX and AxisY > AxisZ then
            return Column[2] > 0 and 2 or 3
        else
            return Column[3] > 0 and 4 or 5
        end
    end

    local function InterleaveBytes(Arrays)
        if #Arrays == 0 then return buffer.create(0) end
        local BytesPerValue = buffer.len(Arrays[1])
        local Result = buffer.create(#Arrays * BytesPerValue)
        local Offset = 0
        for byteIndex = 0, BytesPerValue - 1 do
            for _, arr in ipairs(Arrays) do
                buffer.writeu8(Result, Offset, buffer.readu8(arr, byteIndex))
                Offset = Offset + 1
            end
        end
        return Result
    end

    local function ParseValue(Type, ValueString)
        ValueString = ValueString:gsub("%s+", "")
        if Type == "string" or Type == "Content" then return ValueString end
        if Type == "bool" then return ValueString == "true" end
        if Type == "int" or Type == "token" or Type == "BrickColor" then return tonumber(ValueString) end
        if Type == "float" or Type == "double" then return tonumber(ValueString) end
        if Type == "int64" then return tonumber(ValueString) end
        if Type == "Vector3" then
            local X = tonumber(ValueString:match("<X>(.-)</X>") or "0")
            local Y = tonumber(ValueString:match("<Y>(.-)</Y>") or "0")
            local Z = tonumber(ValueString:match("<Z>(.-)</Z>") or "0")
            return {X, Y, Z}
        end
        if Type == "Color3" then
            local R = tonumber(ValueString:match("<R>(.-)</R>") or "0")
            local G = tonumber(ValueString:match("<G>(.-)</G>") or "0")
            local B = tonumber(ValueString:match("<B>(.-)</B>") or "0")
            return {R, G, B}
        end
        if Type == "CoordinateFrame" or Type == "OptionalCoordinateFrame" then
            local X = tonumber(ValueString:match("<X>(.-)</X>") or "0")
            local Y = tonumber(ValueString:match("<Y>(.-)</Y>") or "0")
            local Z = tonumber(ValueString:match("<Z>(.-)</Z>") or "0")
            local R00 = tonumber(ValueString:match("<R00>(.-)</R00>") or "1")
            local R01 = tonumber(ValueString:match("<R01>(.-)</R01>") or "0")
            local R02 = tonumber(ValueString:match("<R02>(.-)</R02>") or "0")
            local R10 = tonumber(ValueString:match("<R10>(.-)</R10>") or "0")
            local R11 = tonumber(ValueString:match("<R11>(.-)</R11>") or "1")
            local R12 = tonumber(ValueString:match("<R12>(.-)</R12>") or "0")
            local R20 = tonumber(ValueString:match("<R20>(.-)</R20>") or "0")
            local R21 = tonumber(ValueString:match("<R21>(.-)</R21>") or "0")
            local R22 = tonumber(ValueString:match("<R22>(.-)</R22>") or "1")
            return {X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22}
        end
        if Type == "Ref" then return ValueString end
        if Type == "PhysicalProperties" then
            local Custom = ValueString:match("<CustomPhysics>(.-)</CustomPhysics>") == "true"
            local Density = tonumber(ValueString:match("<Density>(.-)</Density>") or "0.7")
            local Friction = tonumber(ValueString:match("<Friction>(.-)</Friction>") or "0.3")
            local Elasticity = tonumber(ValueString:match("<Elasticity>(.-)</Elasticity>") or "0.5")
            local FrictionWeight = tonumber(ValueString:match("<FrictionWeight>(.-)</FrictionWeight>") or "1")
            local ElasticityWeight = tonumber(ValueString:match("<ElasticityWeight>(.-)</ElasticityWeight>") or "1")
            return {Custom, Density, Friction, Elasticity, FrictionWeight, ElasticityWeight}
        end
        if Type == "Faces" then
            return tonumber(ValueString:match("<faces>(.-)</faces>") or "0")
        end
        return ValueString
    end

    local function GetTypeId(XMLType)
        if XMLType == "string" or XMLType == "Content" then return 0x01 end
        if XMLType == "bool" then return 0x02 end
        if XMLType == "int" or XMLType == "token" then return 0x03 end
        if XMLType == "float" then return 0x04 end
        if XMLType == "double" then return 0x05 end
        if XMLType == "BrickColor" then return 0x0b end
        if XMLType == "Color3" then return 0x0c end
        if XMLType == "Vector3" then return 0x0e end
        if XMLType == "CoordinateFrame" or XMLType == "OptionalCoordinateFrame" then return 0x10 end
        if XMLType == "Ref" then return 0x13 end
        if XMLType == "PhysicalProperties" then return 0x19 end
        if XMLType == "Faces" then return 0x09 end
        if XMLType == "int64" then return 0x1b end
        return 0x01 -- fallback
    end

    local XMLContent = readfile(InputXMLFile)
    local Instances = {}
    local ReferentMap = {}
    local NextReferent = 0
    local Stack = {}
    local CurrentPath = {}
    XMLContent = XMLContent:gsub("%s+", " ")
    local Index = 1
    while Index <= #XMLContent do
        local TagStart, TagEnd = XMLContent:find("<([^>/]+)>", Index)
        if not TagStart then break end
        local FullTag = XMLContent:sub(TagStart + 1, TagEnd - 1)
        Index = TagEnd + 1
        local TagName = FullTag:match("^(%S+)")
        local Attributes = {}
        for Key, Value in FullTag:gmatch('(%w+)="([^"]*)"') do Attributes[Key] = Value end
        if TagName == "Item" then
            local ReferenceString = Attributes["referent"]
            local ClassName = Attributes["class"]
            local ReferenceNumber = NextReferent
            NextReferent = NextReferent + 1
            ReferentMap[ReferenceString] = ReferenceNumber
            local Instance = {ClassName = ClassName, Referent = ReferenceNumber, Properties = {}, ReferenceString = ReferenceString}
            if #CurrentPath > 0 then
                Instance.ParentString = CurrentPath[#CurrentPath].ReferenceString
            end
            table.insert(Instances, Instance)
            table.insert(CurrentPath, Instance)
        elseif TagName == "/Item" or TagName == "/roblox" then
            table.remove(CurrentPath)
        else
            local PropertyType = TagName
            local PropertyName = Attributes["name"]
            local ContentStart = Index
            local EndTagPosition = XMLContent:find("</" .. TagName .. ">", Index)
            local ValueString = XMLContent:sub(ContentStart, EndTagPosition - 1)
            Index = EndTagPosition + #("</" .. TagName .. ">")
            local Value = ParseValue(PropertyType, ValueString)
            if #CurrentPath > 0 then
                CurrentPath[#CurrentPath].Properties[PropertyName] = {Type = PropertyType, Value = Value}
            end
        end
    end
    for _, instance in ipairs(Instances) do
        local ParentReferenceString = instance.Properties["Parent"] and instance.Properties["Parent"].Value or instance.ParentString or "null"
        instance.Parent = (ParentReferenceString == "null" or ParentReferenceString == "nil") and -1 or ReferentMap[ParentReferenceString] or -1
    end

    local Classes = {}
    for _, instance in ipairs(Instances) do
        local ClassName = instance.ClassName
        if not Classes[ClassName] then Classes[ClassName] = {Instances = {}, Properties = {}} end
        table.insert(Classes[ClassName].Instances, instance)
        for PropertyName, PropertyData in pairs(instance.Properties) do
            if not Classes[ClassName].Properties[PropertyName] then
                Classes[ClassName].Properties[PropertyName] = {TypeId = GetTypeId(PropertyData.Type), Values = {}}
            end
            table.insert(Classes[ClassName].Properties[PropertyName].Values, PropertyData.Value)
        end
    end
    for _, ClassData in pairs(Classes) do
        table.sort(ClassData.Instances, function(a, b) return a.Referent < b.Referent end)
    end
    local ClassList = {}
    for ClassName in pairs(Classes) do table.insert(ClassList, ClassName) end
    table.sort(ClassList)
    local GlobalInstances = {}
    for _, ClassName in ipairs(ClassList) do
        for _, instance in ipairs(Classes[ClassName].Instances) do
            table.insert(GlobalInstances, instance)
        end
    end

    local function WriteFileHeader()
        local Header = buffer.create(32)
        local Offset = 0
        buffer.writestring(Header, Offset, "<roblox!")
        Offset = Offset + 8
        buffer.writestring(Header, Offset, "\x89\xff\x0d\x0a\x1a\x0a")
        Offset = Offset + 6
        buffer.writeu16(Header, Offset, 0)
        Offset = Offset + 2
        buffer.writeu32(Header, Offset, #ClassList)
        Offset = Offset + 4
        buffer.writeu32(Header, Offset, #GlobalInstances)
        Offset = Offset + 4
        buffer.fill(Header, Offset, 0, 8)
        return Header
    end

    local function WriteChunkHeader(ChunkName, Data)
        local Header = buffer.create(16)
        local Offset = 0
        buffer.writestring(Header, Offset, ChunkName)
        Offset = Offset + 4
        buffer.writeu32(Header, Offset, 0)
        Offset = Offset + 4
        buffer.writeu32(Header, Offset, buffer.len(Data))
        Offset = Offset + 4
        buffer.fill(Header, Offset, 0, 4)
        return Header
    end

    local function WriteINSTChunk(ClassName, ClassId)
        local ClassData = Classes[ClassName]
        local IsService = ClassName:match("Service$") ~= nil
        local DataSize = 4 + (#ClassName + 4) + 1 + 4 + (#ClassData.Instances * 4) + (IsService and #ClassData.Instances or 0)
        local Data = buffer.create(DataSize)
        local Offset = 0
        buffer.writeu32(Data, Offset, ClassId)
        Offset = Offset + 4
        Offset = WriteString(Data, Offset, ClassName)
        buffer.writeu8(Data, Offset, IsService and 1 or 0)
        Offset = Offset + 1
        buffer.writeu32(Data, Offset, #ClassData.Instances)
        Offset = Offset + 4
        local Arrays = {}
        local Previous = 0
        for _, instance in ipairs(ClassData.Instances) do
            local Delta = instance.Referent - Previous
            local Transformed = TransformInt32(Delta)
            local ReferenceBuffer = buffer.create(4)
            buffer.writeu32(ReferenceBuffer, 0, Transformed)
            table.insert(Arrays, ReferenceBuffer)
            Previous = instance.Referent
        end
        local Interleaved = InterleaveBytes(Arrays)
        buffer.copy(Data, Offset, Interleaved, 0, buffer.len(Interleaved))
        Offset = Offset + buffer.len(Interleaved)
        if IsService then
            for _ = 1, #ClassData.Instances do
                buffer.writeu8(Data, Offset, 1)
                Offset = Offset + 1
            end
        end
        return Data
    end

    local function WritePROPChunk(ClassName, ClassId, PropertyName, PropertyType, Values)
        local Data = buffer.create(4 + (#PropertyName + 4) + 1 + 1024 * #Values)
        local Offset = 0
        buffer.writeu32(Data, Offset, ClassId)
        Offset = Offset + 4
        Offset = WriteString(Data, Offset, PropertyName)
        buffer.writeu8(Data, Offset, PropertyType)
        Offset = Offset + 1
        if PropertyType == 0x01 then -- String
            for _, Value in ipairs(Values) do
                Offset = WriteString(Data, Offset, tostring(Value))
            end
        elseif PropertyType == 0x02 then -- Bool
            for _, Value in ipairs(Values) do
                buffer.writeu8(Data, Offset, Value and 1 or 0)
                Offset = Offset + 1
            end
        elseif PropertyType == 0x03 or PropertyType == 0x0b then -- Int32, BrickColor
            local Arrays = {}
            local Previous = 0
            for _, Value in ipairs(Values) do
                local Delta = Value - Previous
                local Transformed = TransformInt32(Delta)
                local Buffer = buffer.create(4)
                buffer.writeu32(Buffer, 0, Transformed)
                table.insert(Arrays, Buffer)
                Previous = Value
            end
            local Interleaved = InterleaveBytes(Arrays)
            buffer.copy(Data, Offset, Interleaved, 0, buffer.len(Interleaved))
            Offset = Offset + buffer.len(Interleaved)
        elseif PropertyType == 0x04 then -- Float32
            local Arrays = {}
            for _, Value in ipairs(Values) do
                local Buffer = buffer.create(4)
                WriteFloat32Roblox(Buffer, 0, Value)
                table.insert(Arrays, Buffer)
            end
            local Interleaved = InterleaveBytes(Arrays)
            buffer.copy(Data, Offset, Interleaved, 0, buffer.len(Interleaved))
            Offset = Offset + buffer.len(Interleaved)
        elseif PropertyType == 0x0c or PropertyType == 0x0e then -- Color3, Vector3
            local Arrays = {}
            for _, Value in ipairs(Values) do
                local Buffer1 = buffer.create(4)
                WriteFloat32Roblox(Buffer1, 0, Value[1])
                table.insert(Arrays, Buffer1)
                local Buffer2 = buffer.create(4)
                WriteFloat32Roblox(Buffer2, 0, Value[2])
                table.insert(Arrays, Buffer2)
                local Buffer3 = buffer.create(4)
                WriteFloat32Roblox(Buffer3, 0, Value[3])
                table.insert(Arrays, Buffer3)
            end
            local Interleaved = InterleaveBytes(Arrays)
            buffer.copy(Data, Offset, Interleaved, 0, buffer.len(Interleaved))
            Offset = Offset + buffer.len(Interleaved)
        elseif PropertyType == 0x10 then -- CFrame
            for _, Value in ipairs(Values) do
                Offset = WriteFloat32Roblox(Data, Offset, Value[1])
                Offset = WriteFloat32Roblox(Data, Offset, Value[2])
                Offset = WriteFloat32Roblox(Data, Offset, Value[3])
                buffer.writeu8(Data, Offset, 255)
                Offset = Offset + 1
                local ColumnX = {Value[4], Value[7], Value[10]}
                local ColumnY = {Value[5], Value[8], Value[11]}
                local ColumnZ = {Value[6], Value[9], Value[12]}
                buffer.writeu8(Data, Offset, GetAxisIndex(ColumnX))
                Offset = Offset + 1
                buffer.writeu8(Data, Offset, GetAxisIndex(ColumnY))
                Offset = Offset + 1
                buffer.writeu8(Data, Offset, GetAxisIndex(ColumnZ))
                Offset = Offset + 1
            end
        elseif PropertyType == 0x13 then -- Referent
            local Arrays = {}
            local Previous = 0
            for _, Value in ipairs(Values) do
                local ReferenceNumber = (Value == "null" or Value == "nil") and -1 or ReferentMap[Value] or -1
                local Delta = ReferenceNumber - Previous
                local Transformed = TransformInt32(Delta)
                local Buffer = buffer.create(4)
                buffer.writeu32(Buffer, 0, Transformed)
                table.insert(Arrays, Buffer)
                Previous = ReferenceNumber
            end
            local Interleaved = InterleaveBytes(Arrays)
            buffer.copy(Data, Offset, Interleaved, 0, buffer.len(Interleaved))
            Offset = Offset + buffer.len(Interleaved)
        elseif PropertyType == 0x19 then -- PhysicalProperties
            for _, Value in ipairs(Values) do
                if not Value[1] then
                    buffer.writeu8(Data, Offset, 0)
                    Offset = Offset + 1
                else
                    buffer.writeu8(Data, Offset, 1)
                    Offset = Offset + 1
                    Offset = WriteFloat32Roblox(Data, Offset, Value[2])
                    Offset = WriteFloat32Roblox(Data, Offset, Value[3])
                    Offset = WriteFloat32Roblox(Data, Offset, Value[4])
                    Offset = WriteFloat32Roblox(Data, Offset, Value[5])
                    Offset = WriteFloat32Roblox(Data, Offset, Value[6])
                end
            end
        elseif PropertyType == 0x09 then -- Faces
            for _, Value in ipairs(Values) do
                buffer.writeu8(Data, Offset, Value)
                Offset = Offset + 1
            end
        end
        local FinalData = buffer.create(Offset)
        buffer.copy(FinalData, 0, Data, 0, Offset)
        return FinalData
    end

    local function WritePRNTChunk()
        local Data = buffer.create(1 + 4 + (#GlobalInstances * 8))
        local Offset = 0
        buffer.writeu8(Data, Offset, 0)
        Offset = Offset + 1
        buffer.writeu32(Data, Offset, #GlobalInstances)
        Offset = Offset + 4
        local ChildArrays = {}
        local ChildPrevious = 0
        for _, instance in ipairs(GlobalInstances) do
            local Delta = instance.Referent - ChildPrevious
            local Transformed = TransformInt32(Delta)
            local Buffer = buffer.create(4)
            buffer.writeu32(Buffer, 0, Transformed)
            table.insert(ChildArrays, Buffer)
            ChildPrevious = instance.Referent
        end
        local InterleavedChildren = InterleaveBytes(ChildArrays)
        buffer.copy(Data, Offset, InterleavedChildren, 0, buffer.len(InterleavedChildren))
        Offset = Offset + buffer.len(InterleavedChildren)
        local ParentArrays = {}
        local ParentPrevious = 0
        for _, instance in ipairs(GlobalInstances) do
            local Parent = instance.Parent
            local Delta = Parent - ParentPrevious
            local Transformed = TransformInt32(Delta)
            local Buffer = buffer.create(4)
            buffer.writeu32(Buffer, 0, Transformed)
            table.insert(ParentArrays, Buffer)
            ParentPrevious = Parent
        end
        local InterleavedParents = InterleaveBytes(ParentArrays)
        buffer.copy(Data, Offset, InterleavedParents, 0, buffer.len(InterleavedParents))
        Offset = Offset + buffer.len(InterleavedParents)
        return Data
    end

    local function WriteENDChunk()
        local Data = buffer.create(9)
        buffer.writestring(Data, 0, "</roblox>")
        return Data
    end

    local Chunks = {}
    table.insert(Chunks, WriteFileHeader())
    local ClassId = 0
    for _, ClassName in ipairs(ClassList) do
        local InstanceChunk = WriteINSTChunk(ClassName, ClassId)
        table.insert(Chunks, WriteChunkHeader("INST", InstanceChunk))
        table.insert(Chunks, InstanceChunk)
        ClassId = ClassId + 1
    end
    ClassId = 0
    for _, ClassName in ipairs(ClassList) do
        for PropertyName, PropertyInfo in pairs(Classes[ClassName].Properties) do
            local PropertyChunk = WritePROPChunk(ClassName, ClassId, PropertyName, PropertyInfo.TypeId, PropertyInfo.Values)
            table.insert(Chunks, WriteChunkHeader("PROP", PropertyChunk))
            table.insert(Chunks, PropertyChunk)
        end
        ClassId = ClassId + 1
    end
    local ParentChunk = WritePRNTChunk()
    table.insert(Chunks, WriteChunkHeader("PRNT", ParentChunk))
    table.insert(Chunks, ParentChunk)
    table.insert(Chunks, WriteENDChunk())
    local TotalSize = 0
    for _, chunk in ipairs(Chunks) do TotalSize = TotalSize + buffer.len(chunk) end
    local Result = buffer.create(TotalSize)
    local Offset = 0
    for _, chunk in ipairs(Chunks) do
        buffer.copy(Result, Offset, chunk, 0, buffer.len(chunk))
        Offset = Offset + buffer.len(chunk)
    end
    writefile(OutputRBXLFile, buffer.tostring(Result))
end

local function saveinstance(saveScripts, avoidPlayerCharacters, saveNilInstances)
    local ScreenGui = Instance.new("ScreenGui")
    local Started = true
    ScreenGui.Parent = CoreGui

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = ScreenGui
    TitleLabel.Visible = true
    TitleLabel.Name = "Title"
    TitleLabel.Font = Enum.Font.SourceSans
    TitleLabel.Text = "Starting serialization..."
    TitleLabel.Position = UDim2.new(1, -220, 0, -45)
    TitleLabel.Size = UDim2.new(0, 180, 0, 30)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16
    TitleLabel.FontFace.Weight = Enum.FontWeight.Bold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Right

    local Loading = Instance.new("ImageLabel")
    Loading.Parent = ScreenGui
    Loading.Visible = true
    Loading.Position = UDim2.new(1, -30, 0, -45)
    Loading.Size = UDim2.new(0, 30, 0, 30)
    Loading.BackgroundTransparency = 1
    Loading.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Loading.Image = getcustomasset("DEXV5\\Assets\\Loading.png")

    local function ManageLoadingIcon(Icon)
        local RotSpeed = 0.4
        local TweenInformation = TweenInfo.new(RotSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        while Started do
            task.wait()
            local Tween = TweenService:Create(Icon, TweenInformation, {Rotation = 360})
            Tween:Play()
            Tween.Completed:Wait()
            Icon.Rotation = 0
        end
    end

    task.spawn(function()
        ManageLoadingIcon(Loading)
    end)

    if workspace.StreamingEnabled then
        TitleLabel.Text = "StreamingEnabled Detected"
        task.wait(0.575)
        local val = PromptStreamingEnabledCaution(TitleLabel)
        if not val then TitleLabel.Text = "Cancelled." task.wait(0.5) Started = false Loading:Destroy() TitleLabel:Destroy() return end
        game.DescendantAdded:Connect(function(v)
            if v:IsA("Model") then
                v.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
            end
        end)
    end

    local output = {XmlHeader}
    local totalInstances = 0
    for _, instance in ipairs(game:GetChildren()) do
        totalInstances = totalInstances + CountInstances(instance, avoidPlayerCharacters)
    end
    if saveNilInstances then
        local Nil = getnilinstances() or {}
        totalInstances = totalInstances + #Nil
    end

    local processedInstances = 0
    local function statusCallback(processed, total, message)
        if total and total > 0 then
            local percentage = (processed / total) * 100
            TitleLabel.Text = string.format("[%.2f%%] %s", percentage, message)
        else
            TitleLabel.Text = string.format("[N/A] %s", message)
        end
    end

    statusCallback(0, totalInstances, "Starting serialization...")

    for _, instance in ipairs(game:GetChildren()) do
        if instance == Players then
            local ref = GetRef(instance)
            statusCallback(processedInstances, totalInstances, "Processing Players service")
            table.insert(output, string.format('<Item class="Players" referent="%s">', ref))
            table.insert(output, "<Properties>")
            table.insert(output, PropertySerializers.string("Name", instance.Name))
            table.insert(output, "</Properties>")
            if Player then
                processedInstances = SerializeInstance(Player, output, saveScripts, avoidPlayerCharacters, saveNilInstances, processedInstances, totalInstances, statusCallback)
            end
            table.insert(output, "</Item>")
        else
            processedInstances = SerializeInstance(instance, output, saveScripts, avoidPlayerCharacters, saveNilInstances, processedInstances, totalInstances, statusCallback)
        end
    end

    if saveNilInstances then
        statusCallback(processedInstances, totalInstances, "Processing Nil Instances folder")
        local ref = GetRef(Workspace)
        table.insert(output, string.format('<Item class="Workspace" referent="%s">', ref))
        table.insert(output, "<Properties>")
        table.insert(output, PropertySerializers.string("Name", "Workspace"))
        table.insert(output, "</Properties>")
        ref = GetRef("NilInstancesFolder")
        table.insert(output, string.format('<Item class="Folder" referent="%s">', ref))
        table.insert(output, "<Properties>")
        table.insert(output, PropertySerializers.string("Name", "Nil Instances"))
        table.insert(output, "</Properties>")
        local Nil = getnilinstances() or {}
        for _, v in ipairs(Nil) do
            local Class = v.ClassName
            if not Class:find("Wrap") and not Class == "Attachment" and not Class == "Bone" then
                statusCallback(processedInstances, totalInstances, "Processing nil instance: " .. (v:GetFullName() or "Unnamed Nil"))
                processedInstances = processedInstances + 1
                local ref = GetRef(v)
                table.insert(output, string.format('<Item class="%s" referent="%s">', className or "Unknown", ref))
                table.insert(output, "<Properties>")
                table.insert(output, PropertySerializers.string("Name", v.Name or "Unnamed"))
                table.insert(output, "</Properties>")

                for _, k in ipairs(v:GetChildren()) do
                    processedInstances = SerializeInstance(k, output, saveScripts, avoidPlayerCharacters, saveNilInstances, processedInstances, totalInstances, statusCallback)
                end

                table.insert(output, "</Item>")
            end
        end
        table.insert(output, "</Item>")
        table.insert(output, "</Item>")
    end

    table.insert(output, XmlFooter)
    statusCallback(processedInstances, totalInstances, "Serialization complete, writing file...")

    local xml = table.concat(output, "\n")
    local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
    if ok and info and info.Name then
        placeName = info.Name:gsub("[%s%p]+", "_")
    end
    if SaveMapSettings.Compress then
        local fileName = placeName .. ".rbxl"
        local savepath = "DEXV5\\SaveInstances\\" .. fileName
        local success, errorMsg = pcall(XMLtoBinary, xml, savepath)
        if success then
            statusCallback(totalInstances, totalInstances, string.format("Saved instance as %s", fileName))
        else
            warn(errorMsg)
            statusCallback(totalInstances, totalInstances, string.format("Failed to save %s: %s", fileName, errorMsg))
        end
        Started = false
        Loading.Image = getcustomasset("DEXV5\\Assets\\Finished.png")
        task.delay(2, function()
            ScreenGui:Destroy()
        end)
    else
        local fileName = placeName .. ".rbxlx"
        local savepath = "DEXV5\\SaveInstances\\" .. fileName
        local success, errorMsg = pcall(Writefile, savepath, xml)
        if success then
            statusCallback(totalInstances, totalInstances, string.format("Saved instance as %s", fileName))
        else
            warn(errorMsg)
            statusCallback(totalInstances, totalInstances, string.format("Failed to save %s: %s", fileName, errorMsg))
        end
        Started = false
        Loading.Image = getcustomasset("DEXV5\\Assets\\Finished.png")
        task.delay(2, function()
            ScreenGui:Destroy()
        end)
    end
end
createMapSetting(SaveMapSettingFrame.Scripts, "SaveScripts", SaveMapSettings.SaveScripts)
createMapSetting(SaveMapSettingFrame.ProgressiveSave, "ProgressiveSave", SaveMapSettings.ProgressiveSave)
createMapSetting(SaveMapSettingFrame.Compress, "Compress", SaveMapSettings.Compress)
createMapSetting(SaveMapSettingFrame.SaveNilInstances, "SaveNilInstances", SaveMapSettings.SaveNilInstances)
createMapSetting(SaveMapSettingFrame.AvoidPlayerCharacters, "AvoidPlayerCharacters", SaveMapSettings.AvoidPlayerCharacters)
createMapSetting(SaveMapSettingFrame.CloseRobloxAfterSave, "CloseRobloxAfterSave", SaveMapSettings.CloseRobloxAfterSave)

Connect(SaveMapButton.Activated, function()
	saveinstance(SaveMapSettings.SaveScripts, SaveMapSettings.AvoidPlayerCharacters, SaveMapSettings.SaveNilInstances)
end)

task.wait(0)

TweenPosition(IntroFrame, UDim2_new(1 ,-301, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)

task.wait(0.5)

switchWindows("Explorer")

task.wait(1)

SideMenu.Visible = true

repeat task.wait() until getgenv().InitLoaded == true

for i = 0,1,.1 do
	IntroFrame.BackgroundTransparency = i
	IntroFrame.Main.BackgroundTransparency = i
	IntroFrame.Slant.ImageTransparency = i
	IntroFrame.Title.TextTransparency = i
	IntroFrame.Version.TextTransparency = i
	IntroFrame.Creator.TextTransparency = i
	IntroFrame.Sad.ImageTransparency = i
	task.wait(0)
end

IntroFrame.Visible = false

TweenPosition(SlideFrame, UDim2_new(), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(OpenScriptEditorButton, UDim2_new(0,0,0,150), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(ConsoleButton, UDim2_new(0,0,0,180), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(CloseToggleButton, UDim2_new(0,0,0,210), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(Slant, UDim2_new(0,0,0,240), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)

task.wait(.5)

for i = 1,0,-.1 do
	OpenScriptEditorButton.Icon.ImageTransparency = i
    ConsoleButton.Icon.ImageTransparency = i
	CloseToggleButton.TextTransparency = i
	task.wait(0)
end
