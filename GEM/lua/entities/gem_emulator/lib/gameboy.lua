local mt = gem.GBZ80

local string_format = string.format

function mt:Restart()

	self:ClearRT()

	-- Memory
	self.Memory = {}	-- Main Memory RAM
	self.ROM = {} 		-- Used for external Cart ROM, each bank is offset by 0x4000
	self.RAM = {}		-- Used for external Cart RAM

	self:LoadRom()
	

	for i = 0, 0x1FFFF do
		self.Memory[i] = 0
		self.RAM[i] = 0
	end

	self.VideoArray = {} -- simple bitmap of the display for mt:draw()

	self.BIOS = { 0xFE, 0xFF, 0xAF, 0x21, 0xFF, 0x9F, 0x32, 0xCB, 0x7C, 0x20, 0xFB, 0x21, 0x26, 0xFF, 0x0E, 0x11, 0x3E, 0x80, 0x32, 0xE2, 0x0C, 0x3E, 0xF3, 0xE2, 0x32, 0x3E, 0x77, 0x77, 0x3E, 0xFC, 0xE0, 0x47, 0x11, 0x04, 0x01, 0x21, 0x10, 0x80, 0x1A, 0xCD, 0x95, 0x00, 0xCD, 0x96, 0x00, 0x13, 0x7B, 0xFE, 0x34, 0x20, 0xF3, 0x11, 0xD8, 0x00, 0x06, 0x08, 0x1A, 0x13, 0x22, 0x23, 0x05, 0x20, 0xF9, 0x3E, 0x19, 0xEA, 0x10, 0x99, 0x21, 0x2F, 0x99, 0x0E, 0x0C, 0x3D, 0x28, 0x08, 0x32, 0x0D, 0x20, 0xF9, 0x2E, 0x0F, 0x18, 0xF3, 0x67, 0x3E, 0x64, 0x57, 0xE0, 0x42, 0x3E, 0x91, 0xE0, 0x40, 0x04, 0x1E, 0x02, 0x0E, 0x0C, 0xF0, 0x44, 0xFE, 0x90, 0x20, 0xFA, 0x0D, 0x20, 0xF7, 0x1D, 0x20, 0xF2, 0x0E, 0x13, 0x24, 0x7C, 0x1E, 0x83, 0xFE, 0x62, 0x28, 0x06, 0x1E, 0xC1, 0xFE, 0x64, 0x20, 0x06, 0x7B, 0xE2, 0x0C, 0x3E, 0x87, 0xE2, 0xF0, 0x42, 0x90, 0xE0, 0x42, 0x15, 0x20, 0xD2, 0x05, 0x20, 0x4F, 0x16, 0x20, 0x18, 0xCB, 0x4F, 0x06, 0x04, 0xC5, 0xCB, 0x11, 0x17, 0xC1, 0xCB, 0x11, 0x17, 0x05, 0x20, 0xF5, 0x22, 0x23, 0x22, 0x23, 0xC9, 0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D, 0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E, 0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99, 0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC, 0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E, 0x3C, 0x42, 0xB9, 0xA5, 0xB9, 0xA5, 0x42, 0x3C, 0x21, 0x04, 0x01, 0x11, 0xA8, 0x00, 0x1A, 0x13, 0xBE, 0x20, 0xFE, 0x23, 0x7D, 0xFE, 0x34, 0x20, 0xF5, 0x06, 0x19, 0x78, 0x86, 0x23, 0x05, 0x20, 0xFB, 0x86, 0x20, 0xFE, 0x3E, 0x01, 0xE0, 0x50 }
	self.BIOS[0] = 0x31		-- Used on startup, loads at 0x0 and is promptly turned off when PC hits 100


	
	-- Memory & Cart Flags
	self.EnableBios = true 	-- Enables the Bios, disabled after the bios is used
	self.CartMBCMode = 3	-- 0 for ROM mode, 1 for MBC1, 2 for MBC2, 3 for MBC3
	self.RomBank = 1 		-- The current ROM bank stored in 0x4000 to 0x7FFF
	self.RamBank = 0		-- The current RAM bank
	
	-- Registers
	self.A = 0
	self.B = 0
	self.C = 0	
	self.D = 0
	self.E = 0
	self.H = 0
	self.L = 0x20

	self.PC = 0x0
	self.SP = 0x0
	
	-- Internal Flags
	self.Cf = false -- Carry
	self.Hf = false -- Half Carry
	self.Zf = false -- Zero 
	self.Nf = false -- Subtract
	
	-- Virtual Flags
	self.IME = true		-- Interupt Master Enable
	self.Halt = false 		-- is halt engaged (do nothing until an interupt)



	-- Interupt Hardware Registers
	self.IE = 0 -- Interupt Enable Register: Bit0 = VBlank, Bit1 = LCD, Bit2 = Timer, Bit4 = Joypad
	self.IF = 0 -- Interupt Request Register
	
	


	--------------------------------
	-- LCD/GPU Hardware Registers --
	--------------------------------

	self.ScanCycle = 0	-- The number of cycles executed so far, resets at end of hblank.

	-- LCD Control Register
	self.LCDEnable = false -- Disables and enables the LCD
	self.WindowMap = 0x98000 -- Pointer to the Map used by the Window Tile map. 0 = 0x9800, 1 = 0x9C00
	self.WindowEnable = false -- Enables and Disables drawing of the window
	self.TileData = 0x8800 -- Pointer to the tiledata used by both window and bg. 0 = 0x8800, 1 =0x8000
	self.BGMap = 0x9800 -- Pointer to the Map used by the BG. 0 = 0x9800, 1 = 0x9C00
	self.SpriteSize = 8 -- Sprite Vertical size. 0 = 8, 1 = 16
	self.SpriteEnable = false -- Enables/Disables drawing of sprites
	self.BGEnable = false -- Enabled/Disables the drawing of the BG

	-- LCD Status Register
	self.CoincidenceInterupt = false
	self.ModeTwoInterupt = false
	self.ModeOneInterupt = false
	self.ModeZeroInterupt = false

	self.CoincidenceFlag = 0
	self.Mode = 0

	-- Scroll Registers
	self.ScrollX = 0
	self.ScrollY = 0
	self.WindowX = 0
	self.WindowY = 0

	-- Current scanline Y coordinate register
	self.ScanlineY = 1

	-- Value to compare with ScanLineY for Coincidence (Nothing special, just a value you can R/W to)
	self.CompareY = 0

	-- Palettes
	

	------------------------------
	-- Timer Hardware Registers --
	------------------------------
	
	-- Timer
	self.TimerEnabled = false 	-- Is the timer enabled?
	self.TimerCounter = 1024  	-- The number of cycles per timer incriment
	self.TimerCycles   = 0		-- The cycle counter for timers, resets every timer incriment.
	self.TimerDB = {16, 64, 256}; self.TimerDB[0] = 1024 -- Cheaper than an elseif stack
	self.TimerBase = 0 			-- The timer base, when timer overflows it resets itself to this.
	self.Timer = 0			-- The timer itself
	
	-- Divider Timer (Incriments every 256 cycles, no interupt)
	self.DividerCycles = 0 		-- The cycle counter for the Didiver, resets every timer incriment
	self.Divider = 0			-- Easier to store it in a variable than in memory. 

	-- Cycles and other timing
	self.TotalCycles = 0
	self.Cycle = 0

	-- 
	self.DPadByte = 0xF
	self.ButtonByte = 0xF

	self.SelectButtonKeys = true
	self.SelectDirectionKeys = false


	--Drawing Method stuff
	self.ColourDB = {150, 50, 0}; self.ColourDB[0] = 255 -- Basic palette
	self.interleve = 0x300
	self.FrameSkip = 5

	self.Pixels = {} -- Stores the pixels drawn last frame, this way we only redraw what we need to. 

	for n = 0, 23040 do
		self.Pixels[n] = 1
	end

	-- Debugging
	self.LastOpcode = 0
	self.TotalIterations = 0
	self.oldPC = 0
	self.NextPC = 0
	self.Iter = 0

	self:ClearRT()



	-- Sound Sweep
	self.Sweep = CreateSound(self.entity, "synth/square_1760.wav")
	self.Sweep:ChangeVolume(1)
	self.Sweep:Play()

	self.SweepFreq = 0
	self.SweepLimit = true
	self.SweepTimer = 0

	self.SweepTimerCycle = 0

	self.SweepTimerEnable = true

	-- Tone

	self.Tone = CreateSound(player.GetByID( 1 ), "synth/square_1760.wav")
	self.Tone:ChangeVolume(1)
	self.Tone:Play()

	self.ToneFreq = 0
	self.ToneLimit = true
	self.ToneTimer = 0

	self.ToneTimerCycle = 0

	self.ToneTimerEnable = true

end

----------------------------------------------------------------------
-- Name: Initialize
-- Desc: Called when the instance is created
----------------------------------------------------------------------
function mt:Initialize()
	self:Restart()
end

function mt:KeyChanged( key, bool )
	if key == "Start" then self.ButtonByte = (bool and self.ButtonByte&(15 - 8) or self.ButtonByte|8 ) end
	if key == "Select" then self.ButtonByte = (bool and self.ButtonByte&(15 - 4) or self.ButtonByte|4 ) end
	if key == "B" then self.ButtonByte = (bool and self.ButtonByte&(15 - 2) or self.ButtonByte|2 ) end
	if key == "A" then self.ButtonByte = (bool and self.ButtonByte&(15 - 1) or self.ButtonByte|1 ) end

	if key == "Down" then self.DPadByte = (bool and self.DPadByte&(15 - 8) or self.DPadByte|8 ) end
	if key == "Up" then self.DPadByte = (bool and self.DPadByte&(15 - 4) or self.DPadByte|4 ) end
	if key == "Left" then self.DPadByte = (bool and self.DPadByte&(15 - 2) or self.DPadByte|2 ) end
	if key == "Right" then self.DPadByte = (bool and self.DPadByte&(15 - 1) or self.DPadByte|1 ) end
end




function mt:Think()
	if self.SweepTimer != 0 or self.SweepTimerEnable == false then
		self.Sweep:ChangePitch( 131072/(2048-self.SweepFreq)  /17.6    )
		self.Sweep:ChangeVolume(1)
	else
		self.Sweep:ChangeVolume(0)
	end


	if self.ToneTimer != 0 or self.ToneTimerEnable == false then
		self.Tone:ChangePitch( 131072/(2048-self.ToneFreq)  /17.6    )
		self.Tone:ChangeVolume(1)
	else
		self.Tone:ChangeVolume(0)
	end

	self.TotalCycles = 0

	while self.TotalCycles < 70224*2 do


		self:Step()

		--if self:Read(self.PC) == 0xFf then 
		--if self.PC >= self.NextPC then
		--if self:IsDebugging() then
		--if self.L > 0xFF or self.H > 0xFF then
		--if false then
		--if self.SP > 0xFFFE then
		--if self.PC == 0x4FEB then
		--	self:EnableDebugging()

		--	break
		--end


	end



	
end

function mt:NextLine()
	self.NextPC = self.PC + 1
	self:DisableDebugging()
end



----------------
--Step function excutes a single operation at a time. 
----------------
function mt:Step()

	--self.LastOpcode = self:Read(self.PC) -- Debugging
	--self.oldPC = self.PC

	if not self.Halt then
		local TotalCycle = 0
		while TotalCycle < 200 do
			self.Operators[self:Read(self.PC)]( self )
			TotalCycle = TotalCycle + self.Cycle
		end
		self.Cycle = TotalCycle
	else
		self.Cycle = 200
	end

	local Cycle = self.Cycle

	if self.SweepTimer != 0 then

		self.SweepTimerCycle = self.SweepTimerCycle + Cycle


		if self.SweepTimerCycle > 16384 then
			self.SweepTimerCycle = self.SweepTimerCycle - 16384
			self.SweepTimer = self.SweepTimer - 1
		end

	end

	if self.ToneTimer != 0 then

		self.ToneTimerCycle = self.ToneTimerCycle + Cycle


		if self.ToneTimerCycle > 16384 then
			self.ToneTimerCycle = self.ToneTimerCycle - 16384
			self.ToneTimer = self.ToneTimer - 1
		end

	end




--[[
	if not self.EnableBios then
		self.TotalIterations = self.TotalIterations + 1
	end
]]
	--Incriment all the counters based on cycles.
	self.TotalCycles = self.TotalCycles + Cycle


	--Manage the timers

	-- Divider, consider changing this to subtract 256 from Divider Cycles rather than setting to 0, test this as it might boost compatability.
	self.DividerCycles = self.DividerCycles + Cycle
	while self.DividerCycles > 255 do
		self.Divider = (self.Divider + 1) & 0xFF
		self.DividerCycles = self.DividerCycles - 256
	end


	if self.TimerEnabled then -- if the timer is enabled
		self.TimerCycles = self.TimerCycles + Cycle -- incriment the cycles until next timer inc
		while self.TimerCycles > self.TimerCounter do -- if they overflow, then reset the timer cycles and incriment the timer
			self.Timer = self.Timer +1
			self.TimerCycles = self.TimerCycles - self.TimerCounter
			if self.Timer > 255 then -- if the timer overflows, reset the timer and do the timer interupt. 
				self.Timer = self.TimerBase
				self.IF = self.IF|4
			end
		end
	end






	--Scanline management, might need to insert drawing code in here eventually for proper GPU emulation :o
	if self.LCDEnable then

		local ScanCycle = self.ScanCycle
		local ScanlineY = self.ScanlineY
		local Mode = self.Mode

		ScanCycle = ScanCycle + Cycle

		if ScanCycle > 456 then
			ScanCycle = ScanCycle - 456
			ScanlineY = ScanlineY + 1
		end

		if ScanlineY > 153 then
			ScanlineY = 0
		end

		if ScanlineY >= 145 and ScanlineY <= 153 then

			if Mode ~= 1 and self.ModeOneInterupt then self.IF = self.IF|2 end -- request LCD interupt for entering Mode 1
			if Mode ~= 1 and ScanlineY == 145 then self.IF = self.IF|1 end -- Reques VBlank
			Mode = 1

		elseif ScanlineY >= 0 and ScanlineY <= 144 then -- not vblank

			if ScanCycle >= 1 and ScanCycle <= 80 then
				if Mode ~= 2 and self.ModeTwoInterupt then self.IF = self.IF|2 end -- request LCD interupt for entering Mode 2
				Mode = 2
			elseif ScanCycle >= 81 and ScanCycle <= 252 then
				Mode = 3
			elseif ScanCycle >= 253 and ScanCycle <= 456 then
				if Mode ~= 0 and self.ModeZeroInterupt then self.IF = self.IF|2 end -- request LCD interupt for entering Mode 0
				Mode = 0
			end

		end

		self.ScanlineY = ScanlineY
		self.ScanCycle = ScanCycle
		self.Mode = Mode
	else
		self.ScanlineY = 0
		self.ScanCycle = 0
		self.Mode = 0
	end


	if ScanlineY == self.CompareY and self.CoincidenceInterupt then
		self.IF = self.IF|2 -- request LCD interrupt
	end





	if self.IME and self.IE > 0 and self.IF > 0 then
		if (self.IE&1 == 1) and (self.IF&1 == 1) then --VBlank interrupt
			--self:EnableDebugging()
			self.IME = false
			self.Halt = false

			self.IF = self.IF&(255 - 1)

			self.SP = self.SP - 2
			self:Write(self.SP + 1, ((self.PC) & 0xFF00)>>8)
			self:Write(self.SP    , (self.PC) & 0xFF       )

			self.PC = 0x40
		elseif (self.IE&2 == 2) and (self.IF&2 == 2) then -- LCD Interrupt
			self.IME = false
			self.Halt = false

			self.IF = self.IF&(255 - 2)

			self.SP = self.SP - 2
			self:Write(self.SP + 1, ((self.PC) & 0xFF00)>>8)
			self:Write(self.SP    , (self.PC) & 0xFF       )

			self.PC = 0x48
		elseif (self.IE&4 == 4) and (self.IF&4 == 4) then -- TImer Interrupt

			self.IME = false
			self.Halt = false

			self.IF = self.IF&(255 - 4)

			self.SP = self.SP - 2
			self:Write(self.SP + 1, ((self.PC) & 0xFF00)>>8)
			self:Write(self.SP    , (self.PC) & 0xFF       )

			self.PC = 0x50
		elseif (self.IE&8 == 8) and (self.IF&8 == 8) then -- Serial Interrupt

			self.IME = false
			self.Halt = false

			self.IF = self.IF&(255 - 8)

			self.SP = self.SP - 2
			self:Write(self.SP + 1, ((self.PC) & 0xFF00)>>8)
			self:Write(self.SP    , (self.PC) & 0xFF       )

			self.PC = 0x58
		elseif (self.IE&16 == 16) and (self.IF&16 == 16) then -- Joy Interrupt

			self.IME = false
			self.Halt = false

			self.IF = self.IF&(255 - 16)

			self.SP = self.SP - 2
			self:Write(self.SP + 1, ((self.PC) & 0xFF00)>>8)
			self:Write(self.SP    , (self.PC) & 0xFF       )

			self.PC = 0x60
		end
	end




	
	-- Disabling the Bios is done now by writing to hardware register 0xFF50, like in a real gameboy
	--if self.EnableBios then
	--	if self.PC > 0xFF then self.EnableBios = false end
	--end


end










-- Upgraded and moved to gmb_gpu



----------------------------------------------------------------------
-- Name: Draw
-- Desc: Called in the entity's Draw hook
----------------------------------------------------------------------

--[[
local surface_DrawRect = surface.DrawRect
local surface_DrawText = surface.DrawText
local surface_SetTextPos = surface.SetTextPos
local surface_SetFont = surface.SetFont
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetTextColor = surface.SetTextColor
local math_ceil = math.ceil
local math_floor = math.floor

function mt:oldDraw()

	if self.FrameSkip != 0 then
		self.FrameSkip = self.FrameSkip - 1
		return
	else
		self.FrameSkip = 3
	end

	--self:ClearRT()
	
	self:StartRenderTarget()
	
	--surface_SetDrawColor( 0, 0, 0, 255 )

	--surface_DrawRect( 1, 1, 512 , 512 ) 

	local VRAM = self.Memory
	local WindowX = self.WindowX
	local WindowY = self.WindowY


	if self.BGEnable then

		local PalMem = VRAM[ 0xFF47 ]
		local BGPal = { (PalMem>>2)&3, (PalMem>>4)&3, (PalMem>>6)&3 }; BGPal[0] = (PalMem)&3

		local TileX = math_floor(self.ScrollX/8)
		local TileY = math_floor(self.ScrollY/8)

		local TileData = self.TileData
		local TileMap = self.BGMap

		for i = 0, 19 do -- The Vertical, 19 tiles max high (Possible 18 if it's lined up)

			for j = 0, 21 do -- The Horizontal, 21 tiles max high (Possibly 20 if it's lined up)

				local iy = (i + TileY)
				local jx = (j + TileX)

				if (iy < WindowY or jx < WindowX) or not self.WindowEnable then

					local ii = iy & 0x1F
					local jj = jx & 0x1F

					local TileID = 0
						
					if TileData == 0x8000 then
						TileID = VRAM[ TileMap + ii*32 + jj ]
					else
						TileID = VRAM[ TileMap + ii*32 + jj ]
						TileID = (TileID&127) - (TileID&128)
						TileData = 0x9000
					end

					for k = 0,7 do

						local ByteA = VRAM[ TileData + TileID*16 + k*2]
						local ByteB = VRAM[ TileData + TileID*16 + k*2 + 1]

						for l = 0,7 do

							local BitA = (ByteA>>l)&1 --that's a lower-case L, not a 1
							local BitB = (ByteB>>l)&1
								
							local PixelX = (jx*8 - l + 9	) - self.ScrollX
							local PixelY = (iy*8 + k + 2) - self.ScrollY

							if PixelX >= 0 and PixelX < 162 and PixelY >= 0 and PixelY < 146 then

								local Colour = self.ColourDB[ BGPal[ (BitB<<1) |  BitA] ]

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170

								if self.Pixels[ArrayCoords] ~= Colour then

									surface_SetDrawColor( Colour, Colour, Colour, 255 )
									surface_DrawRect( PixelX*3 + 1, PixelY*3 + 1, 3 , 3 ) 

									self.Pixels[ArrayCoords] = Colour

								end
							end
						end
					end
				end
			end
		end
	end

	if self.WindowEnable then

		if WindowX >= 0 and WindowX < 144 and WindowY >= 1 and WindowY < 144 then

			local XMax = math_floor((160 - WindowX )/8)
			local YMax = math_floor((144 - WindowY)/8)

			local PalMem = VRAM[ 0xFF47 ]
			local WinPal = { (PalMem>>2)&3, (PalMem>>4)&3, (PalMem>>6)&3 }; WinPal[0] = (PalMem)&3

			local WinMap = self.WindowMap
			local TileData = self.TileData

			if YMax > 1 and XMax > 0 then

				for i = 0, XMax do

					for j = 0, YMax + 2  do

						local TileID
							
						if TileData == 0x8000 then
							TileID = VRAM[ WinMap + i*32 + j ]
						else
							TileID = VRAM[ WinMap + i*32 + j ]
							TileID = (TileID&127) - (TileID&128)
							TileData = 0x9000
						end

						for k = 0,7 do

							local ByteA = VRAM[ TileData + TileID*16 + k*2]
							local ByteB = VRAM[ TileData + TileID*16 + k*2 + 1]

							for l = 0,7 do

								local BitA = (ByteA>>l)&1 --that's a lower-case L, not a 1
								local BitB = (ByteB>>l)&1
									
								local PixelX = (j*8 - l + 9 ) + WindowX 
								local PixelY = (i*8 + k + 3 - 8) + WindowY

								if PixelX >= 0 and PixelX < 162 and PixelY >= 0 and PixelY < 146 then

									local Colour = self.ColourDB[ WinPal[ (BitB<<1) |  BitA] ]

									local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170

									if self.Pixels[ArrayCoords] ~= Colour then

										surface_SetDrawColor( Colour, Colour, Colour, 255 )
										surface_DrawRect( PixelX*3 + 1, PixelY*3 + 1, 3 , 3 ) 

										self.Pixels[ArrayCoords] = Colour
									end
								end
							end
						end
					end
				end
			end
		end
	end




-- Add support for 16 bit sprites
	local PalMem1 = self.Memory[ 0xFF49 ]
	local PalMem2 = self.Memory[ 0xFF48 ]

	for n = 0, 159, 4 do
		local YPos = self.Memory[ 0xFE00 | n ]
		if YPos > 0 and YPos < 160 then
			local XPos = self.Memory[ 0xFE00 | (n+1) ]
			if XPos > 0 and XPos < 168 then

				local SpriteFlags = self.Memory[ 0xFE00 | (n+3) ]
				
				local TileID = self.Memory[ 0xFE00 | (n+2) ]
				local Alpha =  (SpriteFlags  & 128) == 128
				local YFlip = (SpriteFlags & 64)    == 64
				local XFlip = (SpriteFlags & 32)    == 32
				local SPalID = (SpriteFlags & 16)   == 16

				if SPalID then
					SpPal = { (PalMem1>>2)&3, (PalMem1>>4)&3, (PalMem1>>6)&3 }
				else
					SpPal = { (PalMem2>>2)&3, (PalMem2>>4)&3, (PalMem2>>6)&3 }
				end


				for i = 0,7 do

					local ByteA = self.Memory[ 0x8000 + TileID*16 + i*2]
					local ByteB = self.Memory[ 0x8000 + TileID*16 + i*2 + 1]

					for j = 0,7 do

						local BitA = (ByteA>>j)&1 
						local BitB = (ByteB>>j)&1

						if ((BitB<<1) |  BitA) > 0 then

							local PixelX = XPos + 1 + (XFlip and j - 7 or -j)
							local PixelY = YPos - 16 + 2 + (YFlip and -i + 7 or i)

							local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
							
							local Colour = self.ColourDB[ SpPal[ (BitB<<1) |  BitA] ]

							if PixelX >= 0 and PixelX < 162 and PixelY >= 0 and PixelY < 146 then

								if self.Pixels[ArrayCoords] ~= Colour then

									surface_SetDrawColor( Colour, Colour, Colour, 255 )
									surface_DrawRect( PixelX*3 + 1, PixelY*3 + 1, 3 , 3 ) 

									self.Pixels[ArrayCoords] = Colour

								end
							end
						end
					end
				end
			end
		end
	end




				
			
]]--


	-- Very temporary drawing, simply draws the 256 by 256 background tile map

--[[
	self.interleve = self.interleve + 0x100
	if self.interleve >= 0x400 then self.interleve = 0 end

	for i = 0x9800 + self.interleve, 0x9800 + 0x00FF + self.interleve do

		local TileID = self.Memory[ i ]

		for j = 0,7 do

			local ByteA = self.Memory[ 0x8000 + TileID*16 + j*2]
			local ByteB = self.Memory[ 0x8000 + TileID*16 + j*2 + 1]

			for k = 7,0,-1 do

				local BitA = (ByteA>>k)&1
				local BitB = (ByteB>>k)&1

				local Colour = self.ColourDB[(BitA + BitB)]


				surface_SetDrawColor( Colour, Colour, Colour,255 )
				surface_DrawRect( (self.x + -(k-7) + 4)*2 , (self.y + j + 4)*2, 2 , 2 ) 

			end


		end

		self.x = self.x + 8
		if self.x > 255 then
			self.x = 0
			self.y = self.y + 8
		end
		if self.y > 255 then
			self.y = 0
		end

	end
]]--
--[[
	if self:IsDebugging() then
		local x, y = 400, 0 -- Offset (cant draw outside screen when using RT. 400 is at the edge)
		
		-- Background
		surface_SetDrawColor( 0,0,0, 255 )
		surface_DrawRect( x, y, 256, 512 )

		-- Title
		surface_SetFont( "Trebuchet18" )
		surface_SetTextColor( 255, 255, 255, 255 )
		
		-- Registers
		local toDraw = {
		{ "A", self.A },
		{ "B", self.B },
		{ "C", self.C },
		{ "D", self.D },
		{ "E", self.E },
		{ "H", self.H },
		{ "L", self.L },
		{ "Op", self.LastOpcode },
		{ "CurOp", self:Read(self.PC) },
		{ "FF80", self:Read( 0xFF80	 ) },
		{ "PC", self.PC },
		{ "oldPC", self.oldPC },
		{ "Z", self.Zf and 1 or 0 },
		{ "N", self.Nf and 1 or 0 },
		{ "H", self.Hf and 1 or 0 },
		{ "C", self.Cf and 1 or 0 },
		{ "SP", self.SP },
		{ "I", self.TotalIterations, true },
		{ "LCD Mode", self.Mode, true },
		{ "ScLine", self.ScanlineY},
		{ "RomB", self.RomBank},
		{ "IE", self.IE},
		{ "IF", self.IF},
		{ "IME", self.IME and 1 or 0}}

		for i=1,#toDraw do
			local name, value, notHex = toDraw[i][1], toDraw[i][2], toDraw[i][3]
			surface_SetTextPos( x + 10, y + i * 20 )
			if notHex then
				if not value then value = 0x1337 end
				surface_DrawText( name .. ": " .. value )
			else
				if not value then value = 0x1337 end
				surface_DrawText( name .. ": " .. string_format( "%05X", value ) )
			end
		end

	end


	self:EndRenderTarget()
end
]]--


local string_byte = string.byte
local string_sub = string.sub



function mt:LoadRom()
	--[[
	for N = 0, #self.ROMstring -1 do
		self.ROM[N] = string_byte(string_sub(self.ROMstring,N+1,N+1))	
	end
	]]--
	local x = 0
	for i=1,#self.ROMstring,2 do
		self.ROM[x] = tonumber( self.ROMstring:sub(i,i+1), 16 )
		x = x + 1
	end
end













































--[[




function mt:Read(Addr)

	local TAddr = 0xF000&Addr
	

	-- first 4KB of Bank 0 ROM, clause for readin the Bios.
	if TAddr == 0x0000 or TAddr == 0x1000 or TAddr == 0x2000 or TAddr == 0x3000 then
		if self.EnableBios and Addr >= 0x00 and Addr <= 0xFF then
			return self.BIOS[Addr]
		else
			return self.ROM[Addr]
		end



	-- Bank 1 ROM, hot swappable
	elseif TAddr == 0x4000 or TAddr == 0x5000 or TAddr == 0x6000 or TAddr == 0x7000 then
		return self.ROM[Addr]


	--- Video Memory
	elseif TAddr == 0x8000 or TAddr == 0x9000 then
		return self.Memory[Addr]

	--- External ram, not emulated yet.
	elseif TAddr == 0xA000 or TAddr == 0xB000 then
		return 0
	
	--- Main ram, remember the second 4KB is hot swappable in the CBC
	elseif TAddr == 0xC000 or TAddr == 0xD000 then
		return self.Memory[Addr]

	-- Echo Memory, this needs to be emulated but it's not mission typical... I think
	elseif TAddr == 0xE000 then
		return 0

	-- Registers, High Ram, Etcetera
	elseif TAddr == 0xF000 then


		-- Returns the current timer
		if Addr == 0xFF05 then
			return self.Timer


		--- High ram, this needs to be the most optomised, remember to convert all memory operations to a lookup table once compatability is looking good.
		elseif Addr >= 0xFF80 and Addr <= 0xFFFE then

			return self.Memory[Addr]

		else 
			return self.Memory[Addr]
		end

	end


	
end



function mt:Write(Addr,Data)


	local TAddr = 0xF000&Addr
	
	-- ROM 0
	if Taddr == 0x000 or TAddr == 0x1000 or TAddr == 0x2000 or TAddr == 0x3000 then
		-- do nothing, this is ROM, it'll eventually be used for changing banks however.


	-- ROM 1
	elseif TAddr == 0x4000 or TAddr == 0x5000 or TAddr == 0x6000 or TAddr == 0x7000 then
		-- as above


	--- Video Memory
	elseif TAddr == 0x8000 or TAddr == 0x9000 then
		self.Memory[Addr] = Data

	--- External ram, not emulated yet.
	elseif TAddr == 0xA000 or TAddr == 0xB000 then
		-- Un emulated
	
	--- Main ram, remember the second 4KB is hot swappable in the CBC
	elseif TAddr == 0xC000 or TAddr == 0xD000 then
		self.Memory[Addr] = Data

	-- Echo Memory, this needs to be emulated but it's not mission typical... I think
	elseif TAddr == 0xE000 then
		-- unneded I think




	elseif TAddr == 0xF000 then
		
		-- TIMERS --

		if Addr == 0xFF04 then --divider, writing to the divider resets it.
			self.Divider = 0


		elseif Addr == 0xFF05 then -- Timer itself
			self.Timer = Data


		elseif Addr == 0xFF06 then -- Timer Base
			self.Memory[Addr] = Data
			self.TimerBase = Data


		elseif Addr == 0xFF07 then --Timer Control Register
			self.Memory[Addr] = Data --Not sure if any game would actually read timer but better to be safe than sorry

			self.TimerCounter = self.TimerDB[Data & 0x3]  -- This is set to the first 2 bits of data based on the lookup of timerTB

			self.TimerEnabled = Data & 0x4 == 0x4 -- Disables the timer based on the value of the 3rd bit.


		elseif Addr >= 0xFF80 and Addr <= 0xFFFE then
			self.Memory[Addr] = Data

		end

	end


end







]]--






---------------- FULL MEMORY MAP INFO (Excluded are gameboy colour, sound related and serial port hardware registers)

--         	FFFF: Interupt Enable Register

-- 	FF80 to FFFE: High Ram

--			FF4B: Window X Position
--			FF4A: Window Y Position
--			FF49: Sprite Palette 1
--			FF48: Sprite Palette 0
--			FF47: Background Palette
--			FF46: DMA Transfer
--			FF45: LY Compare, no idea what this does D:
--			FF44: LCDC Y-Coords, no idea what this does D:
--			FF43: Scroll X
--			FF42: Scroll Y
--			FF41: LCD Status
--			FF40: LCD Control

--			FF0F: Interupt Flag
--			FF07: Timer Control
--			FF06: Timer Modulo
--			FF05: Timer Counter
--			FF04: Diviver

--			FF00: Joypad info

--			