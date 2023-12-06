
AtmosClass = atmos_class();

function AtmosClass:__constructor()

	self.Weathers = {};

	self.HeightMin = 0;
	self.NextOutsideCheck = 0;
	self.OutsideCheckDelay = 1;

	self.Valid = true;

end

function AtmosClass:__tostring()

	return "[Atmos Object]";

end

function AtmosClass:IsValid()

	return self.Valid;

end

function AtmosClass:Initialize()

	self.Initialized = true;

	for k, v in pairs( self:GetSettings().Blacklist ) do

		if ( string.find( self:GetMap(), string.lower( v ) ) ) then

			atmos_log( "Disabling atmos on " .. self:GetMap() .. " because it's in the blacklist." );

			self:SetEnabled( false );
			break;

		end

	end

	if SERVER then

		timer.Create( "AtmosWeatherCheck", self:GetSettings().WeatherCheck, 0, function()

			Atmos:WeatherCheck();

		end );

	end
end

function AtmosClass:SetEnabled( bEnabled )

	self:GetSettings().Enabled = bEnabled;

	self.Settings:Save();

end

function AtmosClass:GetEnabled()

	return self:GetSettings().Enabled;

end

function AtmosClass:WeatherCheck()

	if ( !self:GetSettings().Weather || IsValid( self:GetWeather() ) ) then return end

	local roll = math.random( 1, 100 );
	local chance = self:GetSettings().WeatherChance;

	atmos_log( "WeatherCheck rolled " .. tostring( roll ) .. " <= " .. tostring( chance ) );

	if ( roll <= chance && #self.Weathers > 0 ) then

		local weather = table.Random( self.Weathers );

		self:StartWeather( weather );

		hook.Call( "AtmosWeatherStart", GAMEMODE || nil, tostring( self:GetWeather() ) );

		timer.Create( "AtmosWeatherFinish", self:GetSettings().WeatherLength, 1, function()

			self:FinishWeather( tostring( weather ) );

		end );

	end

end

function AtmosClass:RegisterWeather( weather )

	atmos_log( string.format( "registered weather %s", tostring( weather ) ) );

	table.insert( self.Weathers, weather );

end

function AtmosClass:GetWeathers()

	return self.Weathers;

end

function AtmosClass:StartWeather( weather )

	atmos_log( "starting weather " .. tostring( weather ) );

	self:SetWeather( weather );
	weather:Start();

	self:SendWeather();

end

function AtmosClass:FinishWeather()

	local weather = self:GetWeather();

	atmos_log( "finishing weather " .. tostring( weather ) );

	if ( IsValid( weather ) ) then

		hook.Call( "AtmosWeatherFinish", GAMEMODE || nil, tostring( weather ) );

		weather:Finish();
		self:SetWeather( nil );

		self:SendWeather();

	end

end

function AtmosClass:SendWeather( pl )

	local exists = IsValid( Atmos:GetWeather() );
	local id = (exists && Atmos:GetWeather():GetID() || (self.LastWeather && self.LastWeather.ID || 0));

	if ( id != nil ) then

		atmos_log( string.format( "sending weather %s to %s", id, tostring( (pl && pl:Nick() || "everyone") ) ) );

		net.Start( "atmos_weather" );
		net.WriteBool( exists );
		net.WriteUInt( id, 8 );

		if ( IsValid( pl ) ) then

			net.Send( pl );

		else

			net.Broadcast();

		end

	end

end

function AtmosClass:SetWeather( weather )

	atmos_log( "weather set to " .. tostring( weather ) );

	self.LastWeather = self.Weather;
	self.Weather = weather;

end

function AtmosClass:GetWeather()

	return self.Weather;

end

function AtmosClass:GetSettings()

	if ( self.Settings == nil ) then

		self.Settings = SettingsClass();

	end

	return self.Settings:GetSettingsTable();

end

function AtmosClass:ResetSettings()

	self.Settings:Reset();

end

function AtmosClass:CanEditSettings( pl )

	if ( IsValid( pl ) ) then

		-- Prevent SteamID Spoofers from abusing admin access
		if ( !pl:IsFullyAuthenticated() ) then return false end

		-- Atmos moderators
		--if ( table.HasValue( self:GetSettings().Admins, tostring( pl:SteamID() ) ) ) then return true end

		-- GMod moderators
		if ( pl:IsAdmin() || pl:IsSuperAdmin() ) then return true end

		-- ULX moderators
		if ( ( ucl && pl.CheckGroup ) && ( pl:CheckGroup( "owner") || pl:CheckGroup( "moderator" ) || pl:CheckGroup( "atmos" ) ) ) then return true end

		-- Evolve moderators
		if ( evolve && ( pl:EV_IsOwner() || pl:EV_IsSuperAdmin() || pl:EV_IsAdmin() || pl:EV_GetRank() == "moderator" ) ) then return true end

		-- ServerGuard moderators
		if ( serverguard ) then

			local group = serverguard.player:GetRank( pl );
			local name = serverguard.ranks:GetRank( group ).name || "";

			if ( name == "owner" || name == "moderator" || name == "atmos" || name == "superadmin" || name == "admin" ) then

				return true;

			end

		end

		-- Custom moderators
		if ( hook.Call( "AtmosCanEditSettings", GAMEMODE || nil, pl ) ) then return true end

	else

		-- Console
		return true;

	end

	return false;

end

function AtmosClass:Think()

	if ( !self:GetEnabled() ) then return end

	-- NOTE: required wait for ISteamHTTP to be initialized
	if ( !self.Initialized ) then

		self:Initialize();

	end

	if ( IsValid( self.Sky ) ) then

		self.Sky:Think();

	end

	if ( IsValid( self.Fog ) ) then

		self.Fog:Think();

	end

	if ( IsValid( self.Weather ) ) then

		self.Weather:Think();

	end

	if SERVER then

		if ( IsValid( self.Wind ) ) then

			self.Wind:Think();

		end

	end

	if CLIENT then

		if ( IsValid( LocalPlayer() ) ) then

			if ( self.NextOutsideCheck < CurTime() ) then

				local pos = LocalPlayer():EyePos();

				LocalPlayer().isOutside = atmos_outside( pos );
				LocalPlayer().isSkyboxVisible = util.IsSkyboxVisibleFromPoint( pos );

				self.NextOutsideCheck = CurTime() + self.OutsideCheckDelay;

			end

			-- update particles
			self:ParticleThink();

		end

	end

end

if CLIENT then

	function AtmosClass:ParticleThink()

		if ( !IsValid( Atmos:GetWeather() ) ) then

			if ( self.Emitter2D ) then

				self.Emitter2D:Finish();
				self.Emitter2D = nil;

				atmos_log( "Emitter2D destroyed" );

			end

			if ( self.Emitter3D ) then

				self.Emitter3D:Finish();
				self.Emitter3D = nil;

				atmos_log( "Emitter3D destroyed" );

			end

		else

			local pos = LocalPlayer():EyePos();

			if ( !self.Emitter2D ) then

				self.Emitter2D = ParticleEmitter( pos );

				atmos_log( "Emitter2D created" );

			else

				self.Emitter2D:SetPos( pos );

			end

			if ( !self.Emitter3D ) then

				self.Emitter3D = ParticleEmitter( pos, true );

				atmos_log( "Emitter3D created" );

			else

				self.Emitter3D:SetPos( pos );

			end

		end

	end

end

function AtmosClass:SetSky( sky )

	self.Sky = sky;

end

function AtmosClass:GetSky()

	return self.Sky;

end

function AtmosClass:SetFog( fog )

	self.Fog = fog;

end

function AtmosClass:GetFog()

	return self.Fog;

end

function AtmosClass:SetWind( wind )

	self.Wind = wind;

end

function AtmosClass:GetWind()

	return self.Wind;

end

function AtmosClass:GetMap()

	return string.lower( tostring( game.GetMap() ) );

end

if CLIENT then

	function AtmosClass:HUDPaint()

		if ( IsValid( self.Weather ) ) then

			self.Weather:HUDPaint();

		end

	end

end
