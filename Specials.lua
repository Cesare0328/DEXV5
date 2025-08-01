-- < Fix for module threads not being supported since synapse x > --
local script = getgenv().Dex:WaitForChild("Specials")
-- < Override getnilinstances to not rely on table > --
do local o=getgenv().getnilinstances;getgenv().getnilinstances=function()return setmetatable(o(),{__index=function(t,k)for _,v in pairs(t)do if v and v.Name==k then return v end end end})end end
-- < Services > --
local HttpService = cloneref(game:GetService("HttpService"))
-- < Aliases > --
local bit32_band = bit32.band
local bit32_rshift = bit32.rshift
local bit32_lshift = bit32.lshift
local math_random = math.random
local math_floor = math.floor
local string_format = string.format
local string_sub = string.sub
local string_find = string.find
local string_split = string.split
local table_insert = table.insert
local isexecutorfunction = isvolcanofunction or iselectronfunction
--
local WaitForChild = HttpService.WaitForChild
local JSONDecode = HttpService.JSONDecode
-- < Upvalues > --
local Dex = script.Parent
local newline = tostring("\n")
local InitScript = rawget(getfenv(gethiddenprop), "script")
-- < Bindables > --
local Bindables = WaitForChild(Dex, "Bindables", 300)
local GetSpecials_Bindable = WaitForChild(Bindables, "GetSpecials", 300)
-- < Libraries > --
local Api = {
	Dump = JSONDecode(HttpService, game:HttpGet("https://raw.githubusercontent.com/Cesare0328/DEXV5/refs/heads/main/API-DUMP.JSON"))
}

Api.Dump.Properties = {}

for _, Class in next, Api.Dump.Classes do
	local A = Class.Members
	Api.Dump.Properties[Class.Name] = {}
	for _, Member in next, A do
		if Member.MemberType == "Property" then
			Api.Dump.Properties[Class.Name][Member.Name] = Member.ValueType.Name
		end
	end
end

local Xml = {
	start = '<roblox xmlns:xmime="https://www.w3.org/2005/05/xmlmime" xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://www.roblox.com/roblox.xsd" version="4">'..newline..'<Meta name="ExplicitAutoJoints">true</Meta>'..newline..'<External>null</External>'..newline..'<External>nil</External>',
	finish = '</roblox>'
}

local Property = {}

function Property:convert(p1, p2, p3, p4)
	local p4_gsub = {
		double = "number",
		int = "number",
		int32 = "number",
		int64 = "number",
		float = "number",
		float32 = "number",
		float64 = "number",
		bool = "boolean",
		CreatorType = "EnumItem",
		MeshType = "EnumItem",
		CameraType = "EnumItem",
		RenderFidelity = "EnumItem",
		Color3uint8 = "Fault",
		SystemAddress = "Fault",
		Camera = "Ref",
		BasePart = "Ref",
		Workspace = "Ref",
		Instance = "Ref",
		Player = "Ref",
		GuiObject = "Ref",
		LocalizationTable = "Ref"
	}
	local Convert_Types = {
		number = function()
			local p3 = p3[1]
			local isInteger = p3 % 1 == 0
			local ConversionType = isInteger and "int" or "float"
			local Conversion_Format = [[<%s name="%s">%s</%s>]]
			return string_format(Conversion_Format, ConversionType, p2, p3, ConversionType)
		end,
		NumberRange = function()
			local p3 = p3[1]
			local Conversion_Format = [[<NumberRange name="%s">%s</NumberRange>]]
			return string_format(Conversion_Format, p2, p2.Min.." "..p2.Max)
		end,
		NumberSequence = function()
			local p3 = p3[1]
			local Conversion_Format = [[<NumberSequence name="%s">%s</NumberSequence>]]
			local ConvertedArray = {}
			for _, Keypoints in next, p3.Keypoints do
				table_insert(ConvertedArray, unpack(Keypoints))
			end
			return string_format(Conversion_Format, p2, tostring(unpack(ConvertedArray)))
		end,
		ColorSequence = function()
			local p3 = p3[1]
			local Conversion_Format = [[<ColorSequence name="%s">%s</ColorSequence>]]
			local ConvertedArray = {}
			for _, Keypoints in next, p3.Keypoints do
				table_insert(ConvertedArray, unpack(Keypoints))
			end
			return string_format(Conversion_Format, p2, tostring(unpack(ConvertedArray)))
		end,
		string = function()
			local p3 = p3[1]
			local Conversion_Format = [[<string name="%s">%s</string>]]
			return string_format(Conversion_Format, p2, p3)
		end,
		BinaryString = function()
			local p3 = p3[1]
			local Conversion_Format = '<BinaryString name="%s"><![CDATA[%s]]></BinaryString>'
			local Raw_Conversion_Format = '<BinaryString name="%s">%s</BinaryString>'
			local isNilValue = tostring(p3) == "nil"
			return string_format(isNilValue and Raw_Conversion_Format or Conversion_Format, p2, isNilValue and "" or p3)
		end,
		ProtectedString = function()
			local p3 = p3[1]
			local Conversion_Format = '<ProtectedString name="%s"><![CDATA[%s]]></ProtectedString>'
			return string_format(Conversion_Format, p2, p3)
		end,
		Content = function()
			local p3 = p3[1]
			local Conversion_Format = p4 ~= nil and [[<Content name="%s"><url>%s</url></Content>]] or [[<Content name="%s"><null></null></Content>]]
			return string_format(Conversion_Format, p2, p3)
		end,
		Ray = function()
			local p3 = p3[1]
			local Conversion_Format = [[<Ray name="%s">
                <origin>
                <X>%s</X>
                <Y>%s</Y>
                <Z>%s</Z>
                </origin>
                <direction>
                <X>%s</X>
                <Y>%s</Y>
                <Z>%s</Z>
                </direction>
                </Ray>]]
			return string_format(Conversion_Format, p2, p3.Origin.X, p3.Origin.Y, p3.Origin.Z, p3.Direction.X, p3.Direction.Y, p3.Direction.Z)
		end,
		boolean = function()
			local p3 = p3[1]
			local Conversion_Format = [[<bool name="%s">%s</bool>]]
			return string_format(Conversion_Format, p2, tostring(p3))
		end,
		EnumItem = function()
			local p3 = p3[1]
			local Conversion_Format = [[<token name="%s">%s</token>]]
			return string_format(Conversion_Format, p2, p3.Value)
		end,
		CFrame = function()
			local p3 = p3[1]
			local Conversion_Format = [[<CoordinateFrame name="%s">
                <X>%s</X>
                <Y>%s</Y>
                <Z>%s</Z>
                <R00>%s</R00>
                <R01>%s</R01>
                <R02>%s</R02>
                <R10>%s</R10>
                <R11>%s</R11>
                <R12>%s</R12>
                <R20>%s</R20>
                <R21>%s</R21>
                <R22>%s</R22>
                </CoordinateFrame>]]
			return string_format(Conversion_Format, p2, p3.X, p3.Y, p3.Z, p3.RightVector.X, p3.RightVector.Y, p3.RightVector.Z, p3.UpVector.X, p3.UpVector.Y, p3.UpVector.Z, p3.LookVector.X, p3.LookVector.Y, p3.LookVector.Z)
		end,
		Vector3 = function()
			local p3 = p3[1]
			local Conversion_Format = [[<Vector3 name="%s">
                <X>%s</X>
                <Y>%s</Y>
                <Z>%s</Z>
                </Vector3>]]
			return string_format(Conversion_Format, p2, p3.X, p3.Y, p3.Z)
		end,
		Vector2 = function()
			local p3 = p3[1]
			local Conversion_Format = [[<Vector2 name="%s">
                <X>%s</X>
                <Y>%s</Y>
                </Vector2>]]
			return string_format(Conversion_Format, p2, p3.X, p3.Y)
		end,
		UDim = function()
			local p3 = p3[1]
			local Conversion_Format = [[<UDim name="%s">
                <S>%s</S>
                <O>%s</O>
                </UDim>]]
			return string_format(Conversion_Format, p2, p3.Scale, p3.Offset)
		end,
		UDim2 = function()
			local p3 = p3[1]
			local Conversion_Format = [[<UDim2 name="%s">
                <XS>%s</XS>
                <XO>%s</XO>
                <YS>%s</YS>
                <YO>%s</YO>
                </UDim2>]]
			return string_format(Conversion_Format, p2, p3.X.Scale, p3.X.Offset, p3.Y.Scale, p3.Y.Offset)
		end,
		Rect = function()
			local p3 = p3[1]
			local Conversion_Format = [[<Rect2D name="%s">
				<min>
				<X>%s</X>
                <Y>%s</Y>
                </min>
                <max>
                <X>%s</X>
                <Y>%s</Y>
                </max>
                </Rect2D>]]
			return string_format(Conversion_Format, p2, p3.Min.X, p3.Min.Y, p3.Max.X, p3.Max.Y)
		end,
		Color3 = function()
			local p3 = p3[1]
			local Conversion_Format = [[<Color3 name="%s">
                <R>%s</R>
                <G>%s</G>
                <B>%s</B>
                </Color3>]]
			return string_format(Conversion_Format, p2, p3.R, p3.G, p3.B)
		end,
		PhysicalProperties = function()
			local Conversion_Format = [[<PhysicalProperties name="%s">
                <CustomPhysics>false</CustomPhysics>
                </PhysicalProperties>]]
			return string_format(Conversion_Format, p2)
		end,
		Axes = function()
			local Conversion_Format = [[<Axes name="%s">
                <axes>7</axes>
                </Axes>]]
			return string_format(Conversion_Format, p2)
		end,
		Ref = function()
			local Conversion_Format = [[<Ref name="%s">null</Ref>]]
			return string_format(Conversion_Format, p2)
		end,
		Fault = function()
			return '<!--Property "'..p2..'" was not saved as it might affect inserting in Studio.-->'
		end,
		Faces = function()
			return "<!--We are not saving Faces type properties! This is literally useless, lol.-->"
		end,
		Region3int16 = function()
			return "<!--We are not saving Region3int16 type properties! This is literally useless, lol.-->"
		end,
		Vector3int16 = function()
			return "<!--We are not saving Vector3int16 type properties! This is literally useless, lol.-->"
		end,
		Vector2int16 = function()
			return "<!--We are not saving Vector2int16 type properties! This is literally useless, lol.-->"
		end,
		BrickColor = function()
			return "<!--We are not saving BrickColor type properties! This might hurt Color3 / Color3uint8 properties.-->"
		end
	}
	p4 = p4_gsub[p4] and p4_gsub[p4] or p4
	if Convert_Types[p4] then
		return Convert_Types[p4]()
	else
		return "<!--Couldn't load Property '"..p2.."' with type '"..p4.."'-->"
	end
end

function Property:get(p1, p2, Value)
	local SpecialProperties = {
		CustomPhysicalProperties =
			{
				function()
				return PhysicalProperties.new(.7,.3,.5,1,1)
			end,
				{},
				"PhysicalProperties"
			},
		Source =
			{
				decompile,
				{
					p1
				},
				"ProtectedString"
			},
		ChildData =
			{
				readbinarystring,
				{
					p1,
					"ChildData"
				},
				"BinaryString"
			},
		PhysicsData =
			{
				readbinarystring,
				{
					p1,
					"PhysicsData"
				},
				"BinaryString"
			},
		MeshData =
			{
				readbinarystring,
				{
					p1,
					"MeshData"
				},
				"BinaryString"
			},
		SmoothGrid =
			{
				readbinarystring,
				{
					p1,
					"SmoothGrid"
				},
				"BinaryString"
			},
		PhysicsGrid =
			{
				readbinarystring,
				{
					p1,
					"PhysicsGrid"
				},
				"BinaryString"
			},
		MaterialColors =
			{
				readbinarystring,
				{
					p1,
					"MaterialColors"
				},
				"BinaryString"
			},
		Tags =
			{
				readbinarystring,
				{
					p1,
					"Tags"
				},
				"BinaryString"
			},
		AttributesReplicate =
			{
				readbinarystring, 
				{
					p1,
					"AttributesReplicate"
				},
				"BinaryString"
			},
		AttributesSerialize =
			{
				readbinarystring,
				{
					p1,
					"AttributesSerialize"
				},
				"BinaryString"
			},
		RobloxLocked =
			{
				checkrbxlocked,
				{
					p1
				},
				"boolean"
			},
		siz =
			{
				gethiddenproperty,
				{
					p1,
					"Size"
				},
				"Vector3"
			},
		shap =
			{
				gethiddenproperty,
				{
					p1,
					"Shape"
				},
				"EnumItem"
			}
	}
	local SpecialData = SpecialProperties[p2]
	if SpecialData then
		local f = SpecialData[1]
		if f then
			local r1, r2 = f(unpack(SpecialData[2]))
			return self:convert(p1, p2, {r1, r2}, SpecialData[3])
		end
	end
	local ValueType = "string"
	if Value ~= nil then
		ValueType = typeof(Value)
	elseif Value == nil then
		ValueType = Api.Dump.Properties[p1.ClassName][p2]
	end
	if typeof(ValueType) ~= "string" then
		ValueType = "string"
		Value = ""
	end
	return self:convert(p1, p2, {Value}, ValueType)
end

local Class = {}

function Class:new(p1)
	local Referent = "RBX"
	for i = 1, 32 do
		local Random = math_random(36)
		Referent ..= string_sub("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", Random, Random)
	end
	return string_format('<Item class="%s" referent="%s">', p1, Referent), Referent
end

function Class:properties(p1, p2)
	local Properties = getproperties(p2)
	for Prop, Value in next, Properties do
		p1 ..= Property:get(p2, Prop, Value)..newline
	end
	return p1
end

function Class:finish()
	return '</Item>'
end
-- < Source > --
local Specials = {
	checkrbxlocked = function(p1)
    	local success, err = pcall(function()
        	p1.Parent = p1
    	end)
    	if not success and type(err) == "string" and (err:find("locked", 1, true) or err:find("Cannot change", 1, true)) then
        	return true
    	end
    return false
	end,
	fireclickdetector = fireclickdetector,
	firetouchinterest = firetouchinterest,
	fireproximityprompt = fireproximityprompt,
	getpropertylist = getproperties,
	getinstancelist = getinstances or getinstancelist,
	writeinstance = function(p1, p2)
		local A, B = Class:new(p1.ClassName)
		local C = B.." ("..tostring(p1)..")."..p2
		local D = Xml.start..newline
		D ..= A..newline
		D ..= [[<Properties>]]..newline
		D = Class:properties(D, p1)
		D ..= [[</Properties>]]..newline
		D ..= Class:finish()..newline
		D ..= [[<SharedStrings>]]..newline
		D ..= [[</SharedStrings>]]..newline
		D ..= Xml.finish
		writefile(C, D)
		return C
	end
}

function GetSpecials_Bindable.OnInvoke()
	return Specials
end
