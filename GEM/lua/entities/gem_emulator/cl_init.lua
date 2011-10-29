include("shared.lua")

----------------------------------------------------------------------
-- Name: SimpleWordWrap
-- Desc: Helper function
----------------------------------------------------------------------
local function simpleWordWrap( msg, w )
	local newmsg = ""
	local temp = ""
	surface.SetFont( "Trebuchet18" )
	for i=1,#msg do
		if surface.GetTextSize( temp .. msg:sub(i,i) ) >= w then
			newmsg = newmsg .. temp .. "\n"
			temp = msg:sub(i,i)
		else
			temp = temp .. msg:sub(i,i)
		end
	end
	newmsg = newmsg .. temp
	return newmsg
end

----------------------------------------------------------------------
-- Name: drawTextWithNewlines
-- Desc: Helper function
----------------------------------------------------------------------
local function drawTextWithNewlines( msg, x, y )
	if not msg:find( "\n" ) then
		surface.SetTextPos( x, y )
		surface.DrawText( msg )
	else
		local data = string.Explode( "\n", msg )
		local w, h = surface.GetTextSize( data[1] )
		local ofs = 0
		for k,v in pairs( data ) do
			surface.SetTextPos( x, y + ofs )
			surface.DrawText( v )
			ofs = ofs + h
		end
	end
end

----------------------------------------------------------------------
-- Name: Initialize
-- Desc: -
----------------------------------------------------------------------
function ENT:Initialize()
	self:LoadMainMenu()
end

----------------------------------------------------------------------
-- Name: Restart
-- Desc: Reset the emulator
----------------------------------------------------------------------
function ENT:Restart()
	self.Emulator = nil
	self.errordata = nil
	self:LoadMainMenu()
end

----------------------------------------------------------------------
-- Name: LoadMainMenu
-- Desc: Creates the Main Menu buttons
----------------------------------------------------------------------
function ENT:LoadMainMenu()
	self.buttons = {
		y = 15,
		{	text = "Select ROM",
			OnPress = function( self )
					self.buttons = {
						y = 15,
						{	text = "8080",
							OnPress = function( self ) self:ListROMs( "8080" ) end,
						},
						{	text = "GBZ80",
							OnPress = function( self ) self:ListROMs( "GBZ80" ) end,
						},
						{ 	text = "Back",
							OnPress = self.LoadMainMenu,
						},
					}
			end,
		},
		{	text = "Key Bindings",
			OnPress = self.LoadKeyBindButtonsMenu,
		},
		{	text = "Screen Model",
			OnPress = function( self )
				self.buttons = {
					y = 15,
					{	text = "1x1",
						OnPress = function()
							RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "1" )
						end,
					},
					{	text = "2x2",
						OnPress = function()
							RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "2" )
						end,
					},
					{	text = "3x3",
						OnPress = function()
							RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "3" )
						end,
					},
					{	text = "4x4",
						OnPress = function()
							RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "4" )
						end,
					},
					{	text = "Back",
						OnPress = self.LoadMainMenu,
					},
				}
			end
		},
	}
end

----------------------------------------------------------------------
-- Name: CreateFolders
-- Desc: Creates the necessary folders if they don't exist
----------------------------------------------------------------------
function ENT:CreateFolders()
	if not file.IsDir( "gem_emulator" ) then
		file.CreateDir( "gem_emulator" )
	end
	
	if not file.IsDir( "gem_emulator/8080" ) then
		file.CreateDir( "gem_emulator/8080" )
	end
	
	if not file.IsDir( "gem_emulator/GBZ80" ) then
		file.CreateDir( "gem_emulator/GBZ80" )
	end
end

----------------------------------------------------------------------
-- Name: ListROMs
-- Desc: Lists all available roms on the client in the specified folder
----------------------------------------------------------------------
function ENT:ListROMs( fld )
	self:CreateFolders()

	local folder = "gem_emulator/" .. fld
	
	local files = file.Find( folder .. "/*.txt" )
	
	if #files == 0 then
		self.buttons = { y = 15 + 25 * 2, { text = " Back ", OnPress = self.LoadMainMenu } }
		return
	end
	
	local pages = {}
	local n = 1
	
	local temp = {}
	
	for k,v in pairs( files ) do
		temp[#temp+1] = v
		if n == 1 and #temp == 7 then -- we can fit one more in the first page because there is no "prev" button
			pages[n] = temp
			temp = {}
			n = n + 1
		elseif n > 1 and #temp == 6 then
			pages[n] = temp
			-- If there's only one left, add that one too (because we can fit one more on the last page since there is no "next" button)
			if k == #files-1 then
				local page = pages[n]
				page[#page+1] = files[#files]
				break
			end
			temp = {}
			n = n + 1
		end
	end
	if #temp > 0 then -- Add any stragglers
		pages[n] = temp
	end
	
	for pagenum,page in pairs( pages ) do
		for key,curfile in pairs( page ) do
			pages[pagenum][key] = { text = curfile, OnPress = function( self ) self:LoadROM( folder .. "/" .. curfile, fld ) end }
		end
		
		if pagenum > 1 then 
			table.insert( page, { text = "Prev page", OnPress = function( self ) self.buttons = pages[pagenum-1] end } ) 
		end
		
		if pagenum < #pages then
			page[#page+1] = { text = "Next page", OnPress = function( self ) self.buttons = pages[pagenum+1] end }
		end
		
		page[#page+1] = { text = "Back", OnPress = function( self )
											self.buttons = {
												y = 15,
												{	text = "8080",
													OnPress = function( self ) self:ListROMs( "8080" ) end,
												},
												{	text = "GBZ80",
													OnPress = function( self ) self:ListROMs( "GBZ80" ) end,
												},
												{ 	text = "Back",
													OnPress = self.LoadMainMenu,
												},
											}
										end,
						}
		
		page.y = 15
	end
	
	self.buttons = pages[1]
end
----------------------------------------------------------------------
-- Name: LoadROM
-- Desc: Loads the specified ROM
----------------------------------------------------------------------
function ENT:LoadROM( curfile, filetype )
	local data = file.Read( curfile )
	--self:Enter()
	self.Emulator = gem.New( self, data, filetype )
end

----------------------------------------------------------------------
-- Name: DrawError
-- Desc: Draws the error screen
----------------------------------------------------------------------
function ENT:DrawError()
	if not self.errordata then
		self.errordata = nil
		return
	end
	
	surface.SetDrawColor( 0,0,0,255 )
	surface.DrawRect( 0, 0, 256, 256 )
	
	surface.SetTextColor( 150, 0, 0, 255 )
	surface.SetFont( "Trebuchet18" )
	local msg = self.errordata.draw_message
	local w = surface.GetTextSize( msg )
	--surface.SetTextPos( 128-w/2, 80 )
	drawTextWithNewlines( msg, 128-w/2, 45 )
	
	self:DrawButtons()
end

----------------------------------------------------------------------
-- Name: Error
-- Desc: Stores the error data and updates the buttons
----------------------------------------------------------------------
function ENT:Error( msg )
	msg = simpleWordWrap( msg, 250 )
	self.errordata = {
		draw_message = "An error has occurred!",
		message = msg,
	}
	self.buttons = {
		y = 100,
		{ 	
			text = "Restart Emulator", 
			OnPress = function( self ) self:Restart() end,
		},
		{   text = "Show Full Error", 
			OnPress = function( self ) 
				self.buttons = {
					y = 100,
					{ 	
						text = "Restart Emulator", 
						OnPress = function( self ) self:Restart() end,
					} 
					}
				self.errordata.draw_message = self.errordata.message
			end,
		},
	}
end

----------------------------------------------------------------------
-- Name: DrawButtons
-- Desc: Draws the buttons
----------------------------------------------------------------------
function ENT:DrawButtons()
	surface.SetFont( "Trebuchet18" )
	surface.SetTextColor( 0,0,0,255 )
	local maxw
	for i=1,#self.buttons do
		local v = self.buttons[i]
		local w = surface.GetTextSize( v.text )
		if not maxw or maxw < w then
			maxw = w
		end
	end
	
	local y = self.buttons.y
	for i=1,#self.buttons do
		local v = self.buttons[i]
		surface.SetDrawColor( 200, 50, 50, 255 )
		local x = 128-maxw/2-8
		surface.DrawOutlinedRect( x, y, maxw+16, 20 )
		
		surface.SetDrawColor( 100, 0, 0, v.hover and 50 or 150 )
		surface.DrawRect( x, y, maxw+16, 20 )
		
		local str = v.text
		local w = surface.GetTextSize( str )
		drawTextWithNewlines( str, 128-w/2, y + 2 )
		
		v.x = x
		v.y = y
		v.w = maxw+16
		
		y = y + 25
	end
end

function ENT:DrawScreen()
	surface.SetDrawColor( 0,0,0,255 )
	surface.DrawRect( 0, 0, 256, 256 )
	self:DrawButtons()
end

----------------------------------------------------------------------
-- Name: Draw
-- Desc: Draws the entity and screen
----------------------------------------------------------------------
local draw_positions = {
	-- Model									Position offset	 		Angle offset  		Scale
	["models/hunter/plates/plate1x1.mdl"] = { Vector(-23.725,-23.725,1.8), Angle(0,90,0), 0.1854 },
	["models/hunter/plates/plate2x2.mdl"] = { Vector(-47.45,-47.45,1.8), Angle(0,90,0), 0.3707 },
	["models/hunter/plates/plate3x3.mdl"] = { Vector(-71.175,-71.175,1.8), Angle(0,90,0), 0.5561 },
	["models/hunter/plates/plate4x4.mdl"] = { Vector(-94.9,-94.9,1.8), Angle(0,90,0), 0.7414 },
}

local matscreen = CreateMaterial("GEMRT","UnlitGeneric",{
	["$vertexcolor"] = 1,
	["$vertexalpha"] = 1,
	["$ignorez"] = 1,
	["$nolod"] = 1,
})

local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetMaterial = surface.SetMaterial
local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D

function ENT:Draw()
	self:DrawModel()
	
	if LocalPlayer():GetPos():Distance( self:GetPos() ) > 1000 then return end
	
	if not self:GetPly() then return end -- Wait until the owner has been transferred
	
	if self.SERIOUSERROR then return end

	local draw_data = draw_positions[self:GetModel()]
	if not draw_data then return end
	
	if self.Emulator and not self.errordata then
	
		self.Emulator:Draw()

		local OldTex = matscreen:GetMaterialTexture("$basetexture")
		matscreen:SetMaterialTexture("$basetexture", self.Emulator.RTMaterial)
		
		local pos, ang, scale = draw_data[1], draw_data[2], draw_data[3]
		cam_Start3D2D( self:LocalToWorld( pos ), self:LocalToWorldAngles( ang ), scale )
		
			surface_SetDrawColor( 255,255,255,255 )
			surface_SetMaterial( matscreen )
			surface_DrawTexturedRect( 0, 0, 256, 256 )
			
		cam_End3D2D()
		
		matscreen:SetMaterialTexture("$basetexture", OldTex)
	else
		local pos, ang, scale = draw_data[1], draw_data[2], draw_data[3]
		cam_Start3D2D( self:LocalToWorld( pos ), self:LocalToWorldAngles( ang ), scale )
			if self.errordata then
				local ok, msg = pcall( self.DrawError, self )
				if not ok then
					self:GetPly():ChatPrint( "SERIOUS ERROR IS SERIOUS: " .. tostring(msg) )
					self.SERIOUSERROR = true
				end
			else
				local ok, msg = pcall( self.DrawScreen, self )
				if not ok then
					self:GetPly():ChatPrint( "ERROR: " .. tostring(msg) )
					self:Error( msg )
				end
			end
		cam_End3D2D()
	
	end
end

-- Helper function
local function inrange( x1, y1, x2, y2, x3, y3 )
	if x1 < x2 then return false end
	if y1 < y2 then return false end
	if x1 > x3 then return false end
	if y1 > y3 then return false end
	
	return true
end

----------------------------------------------------------------------
-- Name: Create/RemoveTextEntry
-- Desc: Creates/Removes the text entry for input
----------------------------------------------------------------------
function ENT:CreateTextEntry( OnChanged )
	if self.Panel and self.Panel:IsValid() then self.Panel:Remove() end
	
	self.Panel = vgui.Create( "DFrame" )
	self.Panel:SetSize( 1,1 )
	self.Panel:SetPos( 50, 50 )
		
	local txt = vgui.Create( "DTextEntry", self.Panel )
	txt:SetEnabled( true )
	txt:SetEditable( true )
	txt:SetSize( 1,1 )
	
	OnChanged = OnChanged or function() end
	txt.OnKeyCodeTyped = function( pnl, code )
		if code == 81 then
			self:Exit()
			return
		end
		OnChanged( code )
	end
	txt.OnTextChanged = function( pnl, txt )
		pnl:SetText( "" )
	end
	
	function txt:OnLoseFocus() self:RequestFocus() end
	
	self.Panel:MakePopup()
	txt:RequestFocus()
end

function ENT:RemoveTextEntry()
	if self.Panel and self.Panel:IsValid() then
		self.Panel:Remove()
	end
	self.Panel = nil
end

----------------------------------------------------------------------
-- Name: KeyChanged
-- Desc: Filters out the keys we don't need and forwards the rest to the emulator
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Name: Think
-- Desc: Handles the touch screen among other things
----------------------------------------------------------------------
local keys = {}
for k,v in pairs( _E ) do
	if k:sub(1,4) == "KEY_" then
		keys[k] = v
	end
end

local validKeys = { A = true, B = true, Start = true, Select = true, Up = true, Left = true, Down = true, Right = true, Exit = true }


function ENT:Think()
	if not self:GetPly() then return end -- Wait until the owner has been transferred
	if not self.errordata and self.Emulator then self.Emulator:Think() end
	
	if self:GetPly() ~= LocalPlayer() then return end -- Only do below actions for the owner of the screen
	
	if self.Emulator and not self.errordata then
		if not self.Keys then
			self:ExtractKeyBinds()
		end
		
		for k,v in pairs( self.Keys ) do
			if input.IsKeyDown( v ) and not self.KeyPresses[k] then
				if k == "Exit" then continue end
				self.Emulator:KeyChanged( k, true )
				self.KeyPresses[k] = true
			elseif self.KeyPresses[k] and not input.IsKeyDown( v ) then
				if k == "Exit" then continue end
				self.Emulator:KeyChanged( k, false )
				self.KeyPresses[k] = nil
			end
		end
		
	else
	
	--if not self.Emulator or self.errordata then

		if not self.Pressing then
			local x, y = self:GetCursor()
			if x and y then
				if self:GetPly():KeyDown( IN_USE ) then
					self.Pressing = true
				end

				for i=1,#self.buttons do
					local v = self.buttons[i]
					if v then
						local bx, by, w, h = v.x, v.y, v.w, 20
						if bx and by and w and h then
							if inrange( x, y, bx, by, bx+w, by+h ) then
								v.hover = true
								if not v.pressed and self.Pressing then
									v.pressed = true
									local ok, msg = pcall( v.OnPress, self )
									if not ok then
										self:Error( msg )
									end
								end				
							else
								v.hover = false
							end
							
							if v.pressed and not self:GetPly():KeyDown( IN_USE ) then
								v.pressed = nil
								if v.OnRelease then 
									local ok, msg = pcall( v.OnRelease, self )
									if not ok then
										self:Error( msg )
									end
								end
							end
						end
					end
				end
			end
		elseif self.Pressing and not self:GetPly():KeyDown( IN_USE ) then
			self.Pressing = nil
		end
	
	end
	
	self:NextThink( CurTime() )
	return true
end

----------------------------------------------------------------------
-- Name: ExtractKeyBinds
-- Desc: Load key bindings
----------------------------------------------------------------------
function ENT:ExtractKeyBinds()
	self.Keys = {}
	self.KeyPresses = {}
	
	if not file.IsDir( "gem_emulator" ) or not file.Exists( "gem_emulator/keybinds.txt" ) then
		self.Keys.A 		= KEY_H
		self.Keys.B 		= KEY_J
		self.Keys.Start 	= KEY_ENTER
		self.Keys.Select 	= KEY_LSHIFT
		self.Keys.Up 		= KEY_W
		self.Keys.Left 		= KEY_A
		self.Keys.Down 		= KEY_S
		self.Keys.Right 	= KEY_D
		self.Keys.Exit		= KEY_LALT
		self:SaveKeyBinds()
		return
	end
	
	local lines = string.Explode( "\n", file.Read( "gem_emulator/keybinds.txt" ) )
	for k,v in pairs( lines ) do
		local key, enum = v:match( "(.+)=(.+)" )
		if validKeys[key] and tonumber(enum) ~= nil then
			self.Keys[key] = tonumber(enum)
		end
	end
end

----------------------------------------------------------------------
-- Name: SaveKeyBinds
-- Desc: Save key bindings
----------------------------------------------------------------------
function ENT:SaveKeyBinds()
	if not self.Keys then return end
	file.Write( "gem_emulator/keybinds.txt", string.format( "A=%s\nB=%s\nStart=%s\nSelect=%s\nUp=%s\nLeft=%s\nDown=%s\nRight=%s\nExit=%s", self.Keys.A, self.Keys.B, self.Keys.Start, self.Keys.Select, self.Keys.Up
																																			, self.Keys.Left, self.Keys.Down, self.Keys.Right, self.Keys.Exit ) )
end


----------------------------------------------------------------------
-- Name: AskForKeyBind
-- Desc: Function called by the key bind buttons in the bind options menu
----------------------------------------------------------------------
function ENT:AskForKeyBind( key )
	self:CreateTextEntry( function( code )
		self.Keys[key] = code
		self:RemoveTextEntry()
		self:LoadKeyBindButtonsMenu()
		self:SaveKeyBinds()
	end )
end

----------------------------------------------------------------------
-- Name: LoadKeyBindButtonsMenu
-- Desc: -
----------------------------------------------------------------------
function ENT:LoadKeyBindButtonsMenu()
	if not self.Keys then self:ExtractKeyBinds() end
	
	local keynames = {}
	for keyname, value in pairs( self.Keys ) do
		for k,v in pairs( keys ) do
			if value == v then
				keynames[keyname] = k:sub(5)
			end
		end
	end
	
	self.buttons = {
		y = 15,
		{	text = "Up (" .. keynames.Up .. ")",
			OnPress = function( self ) self:AskForKeyBind( "Up" ) end,
		},
		{	text = "Down (" .. keynames.Down .. ")",
			OnPress = function( self ) self:AskForKeyBind( "Down" ) end,
		},
		{	text = "Left (" .. keynames.Left .. ")",
			OnPress = function( self ) self:AskForKeyBind( "Left" ) end,
		},
		{	text = "Right (" .. keynames.Right .. ")",
			OnPress = function( self ) self:AskForKeyBind( "Right" ) end,
		},
		{	text = "A/Shoot (" .. keynames.A .. ")",
			OnPress = function( self ) self:AskForKeyBind( "A" ) end,
		},
		{	text = "B (" .. keynames.B .. ")",
			OnPress = function( self ) self:AskForKeyBind( "B" ) end,
		},
		{	text = "Start (" .. keynames.Start .. ")",
			OnPress = function( self ) self:AskForKeyBind( "Start" ) end,
		},
		{	text = "Select (" .. keynames.Select .. ")",
			OnPress = function( self ) self:AskForKeyBind( "Select" ) end,
		},
		{	text = "Back",
			OnPress = self.LoadMainMenu,
		},
	}
end

----------------------------------------------------------------------
-- Name: GetCursor
-- Desc: Returns the 2D position of the cursor on the screen
----------------------------------------------------------------------
local aabb_sizes = { 	["models/hunter/plates/plate1x1.mdl"] = 47.45,
						["models/hunter/plates/plate2x2.mdl"] = 94.9,
						["models/hunter/plates/plate3x3.mdl"] = 142.35,
						["models/hunter/plates/plate4x4.mdl"] = 189.8,
					}

function ENT:GetCursor()
	local draw_data = draw_positions[self:GetModel()]
	if not draw_data then return end
	
	local trace = self:GetPly():GetEyeTrace()
	if trace.Entity ~= self or trace.HitPos:Distance( self:GetPly():GetShootPos() ) > 200 then return end
	
	local HitPos = self:WorldToLocal( trace.HitPos ) - draw_data[1]
	
	local size = aabb_sizes[self:GetModel()]
	
	local x = HitPos.y / size * 256 -- * (w2-w) * draw_data[3]-- / 24.15 * 256
	local y = HitPos.x / size * 256-- * (h2-h) * draw_data[3]-- / 24.15 * 256
	return x, y
end

----------------------------------------------------------------------
-- Name: OnRemove
-- Desc: -
----------------------------------------------------------------------
function ENT:OnRemove()
	if self.Emulator then
		self.Emulator:OnRemove()
	end
	self:RemoveTextEntry()
end