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
local CoreGui =cloneref( game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
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
local GetSelection_Bindable = WaitForChild(Bindables, "GetSelection", 300)
local SetSelection_Bindable = WaitForChild(Bindables, "SetSelection", 300)
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
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
-- < Custom Aliases > --
local wait = task.wait
-- < Source > --
local function BeforeLoad()
	local A, B = pcall(readfile, "dexv4_settings.json")
	local C = A and JSONDecode(HttpService, B) or {}
	local D = Player:GetDebugId()
	WaitForChild(IntroFrame, "USID", 10).Text = string_format("USID: %s", D)
	WaitForChild(AboutPanel, "USID", 10).Text = string_format("USID: %s", D)
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
				TweenPosition(E, UDim2_new(1, 30, A * .5, A * 36), "Out", "Quad", .5, true)
				A += 1
			end
		end
	end
	A = 0
	if Windows[p1] then
		for F, G in next, Windows[p1] do 
			TweenPosition(G, UDim2_new(1, -300, A * .5, A * 36), "Out", "Quad", .5, true) 
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
	ScriptCache = true
}

local Settings = {
	ClickSelect = false,
	SelBox = false,
	ClearProps = false,
	SelectUngrouped = true,
	UseInstanceBlacklist = true,
	RSSIncludeRL = false
}

pcall(function()
	local A, B = pcall(readfile, "dexv4_settings.json")
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
	pcall(writefile, "dexv4_settings.json", JSONEncode(HttpService, A))
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

local function createSetting(p1, p2, p3)
	local A = Clone(SettingTemplate)
	A.Position = UDim2_new(0, 0, 0, #GetChildren(SettingList) * 60)
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
		wait(1 / 12)
		pcall(SaveSettings)
	end)
	A.Visible = true
	A.Parent = SettingList
	C(p3)
end

createSetting("Click part to select", "ClickSelect", Settings.ClickSelect)
createSetting("Selection Box", "SelBox", Settings.SelBox)
createSetting("Clear property value on focus", "ClearProps", Settings.ClearProps)
createSetting("Select ungrouped models" ,"SelectUngrouped", Settings.SelectUngrouped)
createSetting("Hide unnecessary services (requires restart)", "UseInstanceBlacklist", Settings.UseInstanceBlacklist)
createSetting("Script Storage includes RobloxLocked scripts", "RSSIncludeRL", Settings.RSSIncludeRL)

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
		TweenPosition(A.Bar, on and UDim2_new(0, 32, 0, -2) or UDim2_new(0, 32, 0, -2), Enum.EasingDirection.Out,  Enum.EasingStyle.Quart, .25, true)
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

createMapSetting(SaveMapSettingFrame.Scripts, "SaveScripts", SaveMapSettings.SaveScripts)
createMapSetting(SaveMapSettingFrame.ScriptCache, "ScriptCache", SaveMapSettings.ScriptCache)

Connect(SaveMapButton.Activated, function()
	saveinstance({noscripts = not SaveMapSettings.SaveScripts, scriptcache = SaveMapSettings.ScriptCache, mode = "optimized"})
end)

wait(0)

TweenPosition(IntroFrame, UDim2_new(1 ,-301, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)

switchWindows("Explorer")

wait(1)

SideMenu.Visible = true

for i = 0,1,.1 do
	IntroFrame.BackgroundTransparency = i
	IntroFrame.Main.BackgroundTransparency = i
	IntroFrame.Slant.ImageTransparency = i
	IntroFrame.Title.TextTransparency = i
	IntroFrame.Version.TextTransparency = i
	IntroFrame.Creator.TextTransparency = i
	IntroFrame.Sad.ImageTransparency = i
	wait(0)
end

IntroFrame.Visible = false

TweenPosition(SlideFrame, UDim2_new(), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(OpenScriptEditorButton, UDim2_new(0,0,0,150), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(CloseToggleButton, UDim2_new(0,0,0,180), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)
TweenPosition(Slant, UDim2_new(0,0,0,210), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)

wait(.5)

for i = 1,0,-.1 do
	OpenScriptEditorButton.Icon.ImageTransparency = i
	CloseToggleButton.TextTransparency = i
	wait(0)
end