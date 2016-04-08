
SettingsClass = atmos_class();

function SettingsClass:__constructor()

	local SkyColors = {
		[TIME_DAWN] = {
			TopColor 		= Vector( 0.64, 0.73, 0.91 ),
			BottomColor 	= Vector( 0.74, 0.86, 0.98 ),
			FadeBias 		= 0.82,
			HDRScale 		= 0.66,
			DuskIntensity 	= 2.44,
			DuskScale 		= 0.54,
			DuskColor 		= Vector( 1, 0.38, 0 ),
			SunSize 		= 2,
			SunColor 		= Vector( 0.2, 0.1, 0 )
		},
		[TIME_NOON] = {
			TopColor 		= Vector( 0.24, 0.61, 1 ),
			BottomColor 	= Vector( 0.4, 0.8, 1 ),
			FadeBias 		= 0.27,
			HDRScale 		= 0.66,
			DuskIntensity 	= 0,
			DuskScale 		= 0.54,
			DuskColor 		= Vector( 1, 0.38, 0 ),
			SunSize 		= 5,
			SunColor 		= Vector( 0.2, 0.1, 0 )
		},
		[TIME_DUSK] = {
			TopColor 		= Vector( 0.45, 0.55, 1 ),
			BottomColor 	= Vector( 0.91, 0.64, 0.05 ),
			FadeBias 		= 0.61,
			HDRScale 		= 0.66,
			DuskIntensity 	= 1.56,
			DuskScale 		= 0.54,
			DuskColor 		= Vector( 1, 0, 0 ),
			SunSize 		= 2,
			SunColor 		= Vector( 1, 0.47, 0 )
		},
		[TIME_NIGHT] = {
			TopColor 		= Vector( 0, 0.01, 0.02 ),
			BottomColor 	= Vector( 0, 0, 0 ),
			FadeBias 		= 0.82,
			HDRScale 		= 0.66,
			DuskIntensity 	= 0,
			DuskScale 		= 0.54,
			DuskColor 		= Vector( 1, 0.38, 0 ),
			SunSize 		= 0,
			SunColor 		= Vector( 1, 1, 1 )
		}
	};

	local FogValues = {
		[TIME_DAWN] = {
			FogStart = 0.0,
			FogEnd = 25000.0,
			FogDensity = 0.3,
			FogColor = Vector( 0.6, 0.7, 0.8 )
		},
		[TIME_NOON] = {
			FogStart = 0.0,
			FogEnd = 35000.0,
			FogDensity = 0.0,
			FogColor = Vector( 0.6, 0.7, 0.8 )
		},
		[TIME_DUSK] = {
			FogStart = 0.0,
			FogEnd = 55000.0,
			FogDensity = 0.1,
			FogColor = Vector( 0.6, 0.7, 0.8 )
		},
		[TIME_NIGHT] = {
			FogStart = 0.0,
			FogEnd = 45000.0,
			FogDensity = 0.1,
			FogColor = Vector( 0.6, 0.7, 0.8 )
		}
	};

	self.ServerSettings = {
		Version = ATMOS_VERSION,
		Enabled = true,
		Fog = true,
		Shadows = true,
		Weather = true, -- TODO: implement weather (light rain, thunder storm, blizzard, dust storm)
		Wind = true,
		Earthquakes = true, -- TODO: implement earthquakes
		StartTime = 4.0,
		Paused = false,
		Realtime = false,
		TimeMul = 0.01,
		WeatherChance = 25,
		WeatherCheck = 5 * 60,
		WeatherLength = 10 * 60,
		TransitionMul = 1,
		TimeUpdateDelay = 0,
		SunUpdateDelay = 0,
		MoonDistance = 14000,
		MoonSize = 3000,
		Blacklist = { "tornado" },
		WeatherBlacklist = {},
		Admins = {},
		SkyColors = SkyColors,
		FogValues = FogValues
	};

	self.ClientSettings = {
		MaxParticles = 5000,
		VolumeMultiplier = 1,
		RainSmoke = true,
		RainSplashes = true,
		RainDieTime = 3,
		RainRadius = 900,
		RainCount = 60,
		RainSmokeChance = 10,
		RainHeightMax = 300,
		SnowDieTime = 3,
		SnowRadius = 1200,
		SnowCount = 20,
		SnowHeightMax = 200,
		SkyColors = SkyColors,
		FogValues = FogValues
	};

	self.Settings = table.Copy( self:GetInternalSettings() );
	self.DefaultSettings = table.Copy( self.Settings );

	self:Load();

end

function SettingsClass:__tostring()

	return "[Atmos Settings Object]";

end

function SettingsClass:IsValid()

	return true;

end

function SettingsClass:Save()

	if ( !file.IsDir( "atmos", "DATA" ) ) then

		file.CreateDir( "atmos" );

		atmos_log( "created atmos directory" );

	end

	if ( !file.IsDir( "atmos/maps", "DATA" ) ) then

		file.CreateDir( "atmos/maps" );

		atmos_log( "created atmos maps directory" );

	end

	-- preserve floating point precision
	local settings = atmos_ntos( self:GetInternalSettings() );
	local settingsPath = (SERVER && "atmos/sv_settings.txt" || "atmos/cl_settings.txt");

	file.Write( settingsPath, util.TableToJSON( settings, true ) );

end

function SettingsClass:Load()

	atmos_log( "loading settings..." );

	local settingsPath = (SERVER && "atmos/sv_settings.txt" || "atmos/cl_settings.txt");

	if ( file.Exists( settingsPath, "DATA" ) ) then

		local settingsFile = file.Read( settingsPath, "DATA" );
		local settings = util.JSONToTable( settingsFile );

		-- preserve floating point precision
		settings = atmos_ston( settings );

		-- merge any new or missing settings
		self.Settings = self:MergeSettings( settings );
		--self.InternalSettings = self.Settings;

		--[[
		if SERVER then

			self.ServerSettings = self.Settings;

		else

			self.ClientSettings = self.Settings;

		end
		--]]

		-- let map settings override global settings
		self:LoadMap();

	else

		self:Save();

	end

	atmos_log( "settings loaded." );

	if SERVER then

		self:SendSettings();

	end

end

function SettingsClass:LoadMap()

	-- check if map specific settings exist, if so override default global settings
	local mapSettingsPath = "atmos/maps/" .. Atmos:GetMap() .. ".txt";

	if ( file.Exists( mapSettingsPath, "DATA" ) ) then

		atmos_log( "loading map settings..." );

		local mapSettingsFile = file.Read( mapSettingsPath, "DATA" );
		local mapSettings = util.JSONToTable( mapSettingsFile );

		mapSettings = atmos_ston( mapSettings );

		for k, v in pairs( mapSettings ) do

			if ( self.Settings[ k ] != mapSettings[ k ] ) then

				self.Settings[ k ] = mapSettings[ k ];

			end

		end

		atmos_log( "map settings loaded." );

	end

end

function SettingsClass:MergeSettings( settings )

	if ( settings.Version != ATMOS_VERSION ) then

		atmos_log( string.format( "Updating settings to version %s", tostring( ATMOS_VERSION ) ) );

		local newSettings = table.Copy( self.DefaultSettings );
		local oldSettings = table.Copy( settings );

		-- Preserve any modified settings, but add any new settings
		table.Merge( newSettings, oldSettings );

		-- Remove any outdated settings
		for k, v in pairs( newSettings ) do

			if ( self.DefaultSettings[ k ] == nil ) then

				newSettings[ k ] = nil;

				atmos_log( string.format( "removed deprecated setting %s during merge", tostring( k ) ) );

			end

		end

		settings = newSettings;

		-- Mark the new settings as up to date
		settings.Version = ATMOS_VERSION;

		-- Save new merged settings
		self:Save();

	end

	return settings;

end

function SettingsClass:SendSettings( pl )

	atmos_log( string.format( "streaming server settings to %s", tostring( (pl && pl:Nick() || "everyone") ) ) );

	net.Start( "atmos_settings" );
	net.WriteTable( self:GetSettingsTable() );

	if ( IsValid( pl ) ) then

		net.Send( pl );

	else

		net.Broadcast();

	end

end

function SettingsClass:Reset()

	self.Settings = self.DefaultSettings;

	self:Save();

end

function SettingsClass:GetSettingsTable()

	return self.Settings;

end

function SettingsClass:GetInternalSettings()

	return (SERVER && self.ServerSettings || self.ClientSettings);

end
