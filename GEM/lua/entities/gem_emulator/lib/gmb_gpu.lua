local mt = gem.GBZ80


local surface_DrawRect = surface.DrawRect
local surface_DrawText = surface.DrawText
local surface_SetTextPos = surface.SetTextPos
local surface_SetFont = surface.SetFont
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetTextColor = surface.SetTextColor
local math_ceil = math.ceil
local math_floor = math.floor



function mt:Draw()

	if self.FrameSkip != 0 then
		self.FrameSkip = self.FrameSkip - 1
		return
	else
		self.FrameSkip = 2
	end

	self:StartRenderTarget()



	local WindowX = self.WindowX
	local WindowY = self.WindowY

	local XMax = 21
	local YMax = 19

	if self.WindowEnable and WindowX >= 0 and WindowX < 167 and WindowY >= 0 and WindowY < 144  then
		XMax = math_floor((WindowX - 7)/8)
		YMax = math_floor((WindowY)/8)
	end




	if self.BGEnable then

		local PalMem = self.Memory[ 0xFF47 ]
		local BGPal = { (PalMem>>2)&3, (PalMem>>4)&3, (PalMem>>6)&3 }; BGPal[0] = (PalMem)&3

		local TileX = math_floor(self.ScrollX/8)
		local TileY = math_floor(self.ScrollY/8)

		local TileData = self.TileData
		local TileMap = self.BGMap

		for i = 0, 18 do -- The Vertical, 19 tiles max high (Possible 18 if it's lined up)

			for j = 0, 20 do -- The Horizontal, 21 tiles max high (Possibly 20 if it's lined up)


				local iy = (i + TileY)
				local jx = (j + TileX)

				local ii = iy & 0x1F -- Wrap Around
				local jj = jx & 0x1F -- Wrap Around



				-- Get the current Tile based on the current map
				local TileID = 0
					
				if TileData == 0x8000 then
					TileID = self.Memory[ TileMap + ii*32 + jj ]
				else
					TileID = self.Memory[ TileMap + ii*32 + jj ]
					TileID = (TileID&127) - (TileID&128)
					TileData = 0x9000
				end

				-- Loop through the 8 by 8 tile. 
				
				if not (i > YMax and j > XMax) then

					for k = 0,7 do

						local ByteA = self.Memory[ TileData + TileID*16 + k*2]
						local ByteB = self.Memory[ TileData + TileID*16 + k*2 + 1]

						for l = 0,7 do

							local BitA = (ByteA>>l)&1 --that's a lower-case L, not a 1
							local BitB = (ByteB>>l)&1
								
							local PixelX = (jx*8 - l + 7	) - self.ScrollX
							local PixelY = (iy*8 + k + 0) - self.ScrollY

							if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

								local Colour = self.ColourDB[ BGPal[ (BitB<<1) |  BitA] ]

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170

								if self.Pixels[ArrayCoords] ~= Colour then

									surface_SetDrawColor( Colour, Colour, Colour, 255 )
									surface_DrawRect( PixelX*3 + 16, PixelY*3 + 40, 3 , 3 ) 

									self.Pixels[ArrayCoords] = Colour

								end
							end
						end
					end
				end
			end
		end
	end






	if self.WindowEnable and WindowX >= 0 and WindowX < 167 and WindowY >= 0 and WindowY < 144  then

		WindowX = WindowX - 7

		XMax = math_floor((160 - WindowX)/8)
		YMax = math_floor((144 - WindowY)/8)

		local PalMem = self.Memory[ 0xFF47 ]
		local WinPal = { (PalMem>>2)&3, (PalMem>>4)&3, (PalMem>>6)&3 }; WinPal[0] = (PalMem)&3

		local WinMap = self.WindowMap
		local TileData = self.TileData

			for i = 0, YMax do

				for j = 0, XMax do

				local TileID
					
				if TileData == 0x8000 then
					TileID = self.Memory[ WinMap + i*32 + j ]
				else
					TileID = self.Memory[ WinMap + i*32 + j ]
					TileID = (TileID&127) - (TileID&128)
					TileData = 0x9000
				end

				for k = 0,7 do

					local ByteA = self.Memory[ TileData + TileID*16 + k*2]
					local ByteB = self.Memory[ TileData + TileID*16 + k*2 + 1]

					for l = 0,7 do

						local BitA = (ByteA>>l)&1 --that's a lower-case L, not a 1
						local BitB = (ByteB>>l)&1
							
						local PixelX = (j*8 - l + 7 ) + WindowX 
						local PixelY = (i*8 + k ) + WindowY

						if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

							local Colour = self.ColourDB[ WinPal[ (BitB<<1) |  BitA] ]

							local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170

							if self.Pixels[ArrayCoords] ~= Colour then

								surface_SetDrawColor( Colour, Colour, Colour, 255 )
								surface_DrawRect( PixelX*3 + 16, PixelY*3 + 40, 3 , 3 ) 

								self.Pixels[ArrayCoords] = Colour
							end
						end
					end
				end
			end
		end
	end














	if self.SpriteSize == 8 then


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

								local PixelX = XPos - 1 + (XFlip and j - 7 or -j)
								local PixelY = YPos - 16 + (YFlip and -i + 7 or i)

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
								
								local Colour = self.ColourDB[ SpPal[ (BitB<<1) |  BitA] ]

								if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

									if self.Pixels[ArrayCoords] ~= Colour then

										surface_SetDrawColor( Colour, Colour, Colour, 255 )
										surface_DrawRect( PixelX*3 + 16, PixelY*3 + 40, 3 , 3 ) 

										self.Pixels[ArrayCoords] = Colour

									end
								end
							end
						end
					end
				end
			end
		end
	else

		local PalMem1 = self.Memory[ 0xFF49 ]
		local PalMem2 = self.Memory[ 0xFF48 ]

		for n = 0, 159, 4 do
			local YPos = self.Memory[ 0xFE00 | n ]
			if YPos > 0 and YPos < 160 then
				local XPos = self.Memory[ 0xFE00 | (n+1) ]
				if XPos > 0 and XPos < 168 then

					local SpriteFlags = self.Memory[ 0xFE00 | (n+3) ]
					
					local TileID = self.Memory[ 0xFE00 | (n+2) ] & 0xFE
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

								local PixelX = XPos - 1 + (XFlip and j - 7 or -j)
								local PixelY = YPos - 16 + (YFlip and -i + 7 or i) + (YFlip and 8 or 0)

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
								
								local Colour = self.ColourDB[ SpPal[ (BitB<<1) |  BitA] ]

								if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

									if self.Pixels[ArrayCoords] ~= Colour then

										surface_SetDrawColor( Colour, Colour, Colour, 255 )
										surface_DrawRect( PixelX*3 + 16, PixelY*3 + 40, 3 , 3 ) 

										self.Pixels[ArrayCoords] = Colour

									end
								end
							end
						end
					end

					n2 = n + 1
					
					
					local TileID = TileID | 0x01


					for i = 0,7 do

						local ByteA = self.Memory[ 0x8000 + TileID*16 + i*2 + 0]
						local ByteB = self.Memory[ 0x8000 + TileID*16 + i*2 + 1]

						for j = 0,7 do

							local BitA = (ByteA>>j)&1 
							local BitB = (ByteB>>j)&1

							if ((BitB<<1) |  BitA) > 0 then

								local PixelX = XPos - 1 + (XFlip and j - 7 or -j) 
								local PixelY = YPos - 16 + (YFlip and -i + 7 or i) + (YFlip and 0 or 8)

								local ArrayCoords = (PixelX + 1) + (PixelY + 1)*170
								
								local Colour = self.ColourDB[ SpPal[ (BitB<<1) |  BitA] ]

								if PixelX >= 0 and PixelX < 160 and PixelY >= 0 and PixelY < 144 then

									if self.Pixels[ArrayCoords] ~= Colour then

										surface_SetDrawColor( Colour, Colour, Colour, 255 )
										surface_DrawRect( PixelX*3 + 16, PixelY*3 + 40, 3 , 3 ) 

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
















	self:EndRenderTarget()
end







