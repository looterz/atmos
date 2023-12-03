
local Weather = atmos_class();

function Weather:__constructor()

	self.ID = 1;
	self.MaxDarkness = "d";
	self.MaxLightness = "d";

	if CLIENT then

		-- sounds
		self.RainSounds = {
			"atmos/rain.wav"
		};

		self.ThunderSounds = {
			"atmos/thunder/thunder_1.mp3",
			"atmos/thunder/thunder_2.mp3",
			"atmos/thunder/thunder_3.mp3",
			"atmos/thunder/thunder_4.mp3",
			"atmos/thunder/thunder_5.mp3"
		};

		self.LastRainSoundVolume = 0;
		self.NextThunder = 0;
		self.RainVolumeChangeDelta = 1.5;

		-- rain drops effect on players hud
		self.HUDRainDropTextureID = surface.GetTextureID( "atmos/rainsplash" );
		self.HUDRainDropsNext = 0;
		self.HUDRainDrops = {};

		-- rain particle effect
		self.RainEffect = false;

		-- skybox colors
		self.DayColors = {
			TopColor = Vector( 0.22, 0.22, 0.22 ),
			BottomColor	= Vector( 0.05, 0.05, 0.07 ),
			FadeBias = 1,
			HDRScale = 0.26,
			DuskIntensity	= 0.0,
			DuskScale	= 0.0,
			DuskColor	= Vector( 0.23, 0.23, 0.23 ),
			SunSize = 0,
			SunColor = Vector( 0.83, 0.45, 0.11 )
		};

		self.NightColors = {
			TopColor = Vector( 0.22, 0.22, 0.22 ),
			BottomColor	= Vector( 0.05, 0.05, 0.07 ),
			FadeBias = 1,
			HDRScale = 0.26,
			DuskIntensity	= 0.0,
			DuskScale	= 0.0,
			DuskColor	= Vector( 0.23, 0.23, 0.23 ),
			SunSize = 0,
			SunColor = Vector( 0.83, 0.45, 0.11 )
		};

		-- fog values
		self.DayFog = {
			FogStart = 0.0,
			FogEnd = 18000.0,
			FogDensity = 0.55,
			FogColor = Vector( 0.23, 0.23, 0.23 )
		};

		self.NightFog = {
			FogStart = 0.0,
			FogEnd = 18000.0,
			FogDensity = 0.55,
			FogColor = Vector( 0.23, 0.23, 0.23 )
		};

	end

end

function Weather:__tostring()

	return "Storm";

end

function Weather:IsValid()

	return self.Valid;

end

function Weather:Initialize()

    self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)

end

function Weather:GetID()

	return self.ID;

end

function Weather:Start()

	self.Valid = true;

	atmos_log( tostring( self ) .. " start" );

	if SERVER then

		local sky = Atmos:GetSky();

		if ( IsValid( sky ) ) then

			sky:UpdateLightStyle( 'd' );

		end

	end

	if CLIENT then

		local pl = LocalPlayer();
		local pos = LocalPlayer():EyePos();

		-- sound
		if ( self.RainSound ) then

			self.RainSound:Stop();

		end

		if ( self.ThunderSound ) then

			self.ThunderSound:Stop();

		end

		self.RainSound = CreateSound( pl, table.Random( self.RainSounds ) );
		self.RainSound:PlayEx( 0, 100 );

	end

end

function Weather:Finish()

	self.Valid = false;

	atmos_log( tostring( self ) .. " finish" );

	if CLIENT then

		if ( self.RainSound ) then

			self.RainSound:FadeOut( 5 );
			self.LastRainSoundVolume = 0;

		end

		if ( self.ThunderSound ) then

			self.ThunderSound:FadeOut( 5 );

		end

	end

end

function Weather:Think()

	if CLIENT then

		if ( !IsValid( LocalPlayer() ) ) then return end

		local pl = LocalPlayer();
		local pos = pl:EyePos();
		local volumeMul = Atmos:GetSettings().VolumeMultiplier;

		-- particles
		local rainEffectData = EffectData();
		rainEffectData:SetOrigin( pos );

		util.Effect( "atmos_rain", rainEffectData );

		-- rain sound (adjusts volume depending on location)
		if ( self.RainSound ) then

			if ( pl.isOutside && self.LastRainSoundVolume != 0.4 ) then

				self.RainSound:ChangeVolume( 0.4 * volumeMul, self.RainVolumeChangeDelta );
				self.LastRainSoundVolume = 0.4;

			end

			if ( !pl.isOutside ) then

				if ( pl.isSkyboxVisible && self.LastRainSoundVolume != 0.15 ) then

					self.RainSound:ChangeVolume( 0.15 * volumeMul, self.RainVolumeChangeDelta );
					self.LastRainSoundVolume = 0.15;

				end

				if ( !pl.isSkyboxVisible && self.LastRainSoundVolume != 0 ) then

					self.RainSound:ChangeVolume( 0, self.RainVolumeChangeDelta );
					self.LastRainSoundVolume = 0;

				end

			end

		end

		-- thunder sound (adjusts volume depending on location)
		if ( self.NextThunder < CurTime() ) then

			self.NextThunder = CurTime() + math.Rand( 10, 60 );

			self.ThunderSound = CreateSound( pl, table.Random( self.ThunderSounds ) );

			if ( pl.isOutside ) then

				self.ThunderSound:PlayEx( 1, 100 );

			else

				self.ThunderSound:PlayEx( math.Rand( 0.3, 0.7 ), math.Rand( 60, 85 ) );

			end

		end

	end

end

function Weather:GetSkyColors( time )

	local nightTime = (time >= 20 || time <= 4);

	return (!nightTime && self.DayColors || self.NightColors);

end

function Weather:GetFogValues( time )

	local nightTime = (time >= 20 || time <= 4);

	return (!nightTime && self.DayFog || self.NightFog);

end

function Weather:ShouldUpdateLighting()

	return true;

end

function Weather:ShouldUpdateSky()

	return true;

end

function Weather:ShouldUpdateFog()

	return true;

end

function Weather:ShouldUpdateWind()

	return true;

end

function Weather:IsCloudy()

	return true;

end

if CLIENT then

	function Weather:HUDPaint()

		local pl = LocalPlayer();

		if ( !IsValid( pl ) ) then return end
		if ( render.GetDXLevel() <= 90 ) then return end
		if ( pl:InVehicle() || pl:WaterLevel() >= 1 ) then return end

		-- draw hud rain drops effect
		local angles = pl:EyeAngles();

		if ( pl.isOutside && angles.p < 15 ) then

			if ( CurTime() > self.HUDRainDropsNext ) then

				self.HUDRainDropsNext = CurTime() + math.Rand( 0.1, 0.4 );

				local rainDrop = {};
				rainDrop.x = math.random( 0, ScrW() );
				rainDrop.y = math.random( 0, ScrH() );
				rainDrop.r = math.random( 20, 40 );
				rainDrop.creationTime = CurTime();

				table.insert( self.HUDRainDrops, rainDrop );

			end

		end

		for k, rainDrop in pairs( self.HUDRainDrops ) do

			if ( CurTime() - rainDrop.creationTime > 1 ) then

				table.remove( self.HUDRainDrops, k );
				continue;

			end

			local alpha = (255 * ( 1 - ( CurTime() - rainDrop.creationTime ) ));

			surface.SetDrawColor( 255, 255, 255, alpha );
			surface.SetTexture( self.HUDRainDropTextureID );
			surface.DrawTexturedRect( rainDrop.x, rainDrop.y, rainDrop.r, rainDrop.r );

		end

	end

end

Atmos:RegisterWeather( Weather() );
