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
local RefCounter = 0
local RefCache = {}
-- < Custom Aliases > --
local wait = task.wait
-- < Source > --
local function BeforeLoad()
	local A, B = pcall(readfile, "dexv5_settings.json")
	local C = A and JSONDecode(HttpService, B) or {}
    local D = "UUID : " .. string.gsub('xxxx-xxxx-xxxx-xxxx', '[x]', function() return string.format('%X', math.random(0, 15)) end) .. "\nVERSION : " .. settings()["Diagnostics"].RobloxVersion
	WaitForChild(IntroFrame, "UUID", 10).Text = D
	WaitForChild(AboutPanel, "UUID", 10).Text = D
	if C.Save then
		local E = C.Save
		WaitForChild(SettingHeader, "TextLabel", 10).Text = string_format("Settings | Last Save - %s/%s/%s (%s:%s:%s.%s)", E.Day, E.Month, string_sub(E.Year, #E.Year - 1, #E.Year), E.Hours, E.Minutes, E.Seconds, E.Milliseconds)
	end
end

BeforeLoad()

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
			I.BackgroundTransparency = 1
			I.Icon.ImageColor3 = Color3_new(.6, .6, .6)
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
	CloseRobloxAfterSave = true
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
	ScriptEditor.Visible = OpenScriptEditorButton.Active 
end)

Connect(CloseToggleButton.MouseButton1Up, function()
	toggleDex(not CloseToggleButton.Active)
end)

for _,v in ipairs(GetChildren(SlideFrame)) do
	Connect(v.Activated, function()
		switchWindows(tostring(v))
	end)
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

Connect(Mouse.Button1Down, function()
	if CurrentWindow == "Explorer" and Settings.ClickSelect then
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
        if name == "MeshId" or name == "TextureID" then
            return string.format('<Content name="%s">%s</Content>', name, EscapeXml(value))
        else
            return string.format('<string name="%s">%s</string>', name, EscapeXml(value))
        end
    end,
    bool = function(name, value)
        return string.format('<bool name="%s">%s</bool>', name, tostring(value):lower())
    end,
    number = function(name, value)
        return string.format('<float name="%s">%.6f</float>', name, value)
    end,
    Vector3 = function(name, value)
        return string.format('<Vector3 name="%s"><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z></Vector3>',
            name, value.X, value.Y, value.Z)
    end,
    CFrame = function(name, value)
        local c = {value:GetComponents()}
        return string.format(
            '<CoordinateFrame name="%s"><X>%.6f</X><Y>%.6f</Y><Z>%.6f</Z>' ..
            '<R00>%.6f</R00><R01>%.6f</R01><R02>%.6f</R02>' ..
            '<R10>%.6f</R10><R11>%.6f</R11><R12>%.6f</R12>' ..
            '<R20>%.6f</R20><R21>%.6f</R21><R22>%.6f</R22></CoordinateFrame>',
            name, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
    end,
    Color3 = function(name, value)
        return string.format('<Color3 name="%s"><R>%.6f</R><G>%.6f</G><B>%.6f</B></Color3>',
            name, value.R, value.G, value.B)
    end,
    BrickColor = function(name, value)
        return string.format('<BrickColor name="%s">%d</BrickColor>', name, value.Number)
    end,
    Instance = function(name, value)
        return string.format('<Ref name="%s">%s</Ref>', name, value and GetRef(value) or "null")
    end,
    EnumItem = function(name, value)
        return string.format('<token name="%s">%s</token>', name, tostring(value))
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
            if v.Type.Text == Type then
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
    local ATDictBase = {[1] = 1000, [2] = 500, [3] = 0.5, [4] = 10000}
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
    if Blacklist[instance.ClassName] or Blacklist[instance.Name] then
        statusCallback(processed, total, "Skipping blacklisted instance: " .. (instance:GetFullName() or "Unnamed"))
        return processed
    end

    if avoidPlayerCharacters and instance:IsA("Model") and Players:GetPlayerFromCharacter(instance) then
        statusCallback(processed, total, "Skipping player character: " .. (instance:GetFullName() or "Unnamed"))
        return processed
    end

    statusCallback(processed, total, "Processing: " .. (instance:GetFullName() or "Unnamed"))
    processed = processed + 1

    local isLocalPlayer = instance == Player
    local ref = GetRef(instance)

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
            end
            if instance:IsA("BasePart") and instance.MaterialVariant ~= "" then
                properties.MaterialVariant = instance.MaterialVariant
            end
            if instance:IsA("Part") then
                properties.Shape = instance.Shape
            end
        elseif instance:IsA("Model") then
            properties = {
                PrimaryPart = instance.PrimaryPart,
                WorldPivot = instance.WorldPivot
            }
        elseif saveScripts and (instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")) then
            local source = "Decompile failed"
            local success, result = pcall(function() return decompile(instance) end)
            if success then
                local lines = {}
                for line in result:gmatch("[^\r\n]+") do
                    table.insert(lines, line)
                end
                table.remove(lines, 1)
                source = table.concat(lines, "\n")
            end
            properties = {
                Source = source,
                Disabled = instance:IsA("Script") or instance:IsA("LocalScript") and instance.Disabled or nil
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
                Enabled = false,
                Size = instance.Size
            }
        end

        for propName, propValue in pairs(properties) do
            local propType = typeof(propValue)
            local serializer = PropertySerializers[propType]
            if serializer and propValue ~= nil then
                table.insert(output, serializer(propName, propValue))
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
            --else
                --v:Clone().Parent = v.Parent
                --v:Destroy()
            end
        end)
    end

    local output = {XmlHeader}
    local totalInstances = 0
    for _, instance in ipairs(game:GetChildren()) do
        totalInstances = totalInstances + CountInstances(instance, avoidPlayerCharacters)
    end
    if saveNilInstances then
        local nilInstances = getnilinstances() or {}
        totalInstances = totalInstances + #nilInstances
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
        table.insert(output, string.format('<string name="Name">Nil Instances</string>'))
        local nilInstances = getnilinstances() or {}
        for _, nilInstance in ipairs(nilInstances) do
            statusCallback(processedInstances, totalInstances, "Processing nil instance: " .. (nilInstance:GetFullName() or "Unnamed Nil"))
            processedInstances = processedInstances + 1
            ref = GetRef(nilInstance)
            table.insert(output, string.format('<Item class="%s" referent="%s">', nilInstance.ClassName or "Unknown", ref))
            table.insert(output, "<Properties>")
            table.insert(output, PropertySerializers.string("Name", nilInstance.Name or "Unnamed"))
            table.insert(output, "</Properties>")
            table.insert(output, "</Item>")
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
    local fileName = placeName .. ".rbxlx"
    local savepath = "DEXV5\\SaveInstances\\" .. fileName
    local success, errorMsg = pcall(Writefile, savepath, xml)
    if success then
        statusCallback(totalInstances, totalInstances, string.format("Saved instance as %s", fileName))
    else
        statusCallback(totalInstances, totalInstances, string.format("Failed to save %s: %s", fileName, errorMsg))
    end
    Started = false
    Loading.Image = getcustomasset("DEXV5\\Assets\\Finished.png")
    task.delay(2, function()
        ScreenGui:Destroy()
    end)
end
createMapSetting(SaveMapSettingFrame.Scripts, "SaveScripts", SaveMapSettings.SaveScripts)
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
TweenPosition(CloseToggleButton, UDim2_new(0,0,0,180), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(Slant, UDim2_new(0,0,0,210), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)

task.wait(.5)

for i = 1,0,-.1 do
	OpenScriptEditorButton.Icon.ImageTransparency = i
	CloseToggleButton.TextTransparency = i
	task.wait(0)
end
