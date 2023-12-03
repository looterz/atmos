
SkyClass = atmos_class();

function SkyClass:__constructor()

	if SERVER then

		self.Time = Atmos:GetSettings().StartTime;

		self.NextTimeUpdate = 0;
		self.NextSunUpdate = 0;
		self.LastLightStyle = "";
		self.MaxDarkness = "b";
		self.MaxLightness = "y";

		self.LightEnvironment = ents.FindByClass( "light_environment" )[1];
		self.ShadowControl = ents.FindByClass( "shadow_control" )[1];
		self.Sun = ents.FindByClass( "env_sun" )[1];
		self.SkyPaint = ents.FindByClass( "env_skypaint" )[1];

		if ( Atmos:GetEnabled() ) then

			if ( IsValid( self.SkyPaint ) ) then

				self.SkyPaint:Remove();

			end

			self.SkyPaint = ents.Create( "atmos_sky" );
			self.SkyPaint:Spawn();
			self.SkyPaint:Activate();

		end

	else

		self.LastSceneOrigin = Vector( 0, 0, 0 );
		self.LastSceneAngles = Angle( 0, 0, 0 );

		self.SkyColors = Atmos:GetSettings().SkyColors;

	end

	self.Valid = true;

end

function SkyClass:__tostring()

	return "[Atmos Sky Object]";

end

function SkyClass:IsValid()

	return self.Valid;

end

function SkyClass:Initialize()

    self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)

end

function SkyClass:Think()

	if ( !IsValid( self ) ) then return end

	if SERVER then

		-- update time
		self:UpdateTime();

		-- update map lighting
		self:UpdateLighting();

		-- update sun position and shadows
		self:UpdateSun();

		-- check if we should trigger any relays
		self:UpdateOutputs();

	else

		-- update skybox
		self:UpdateSkybox();

	end

end

function SkyClass:GetRealTime()

	local t = os.date( "*t" );

	return t.hour + (t.min / 60) + (t.sec / 3600);

end

function SkyClass:UpdateLightStyle( style )

	if ( self.LastLightStyle == style ) then return end

	if ( IsValid( self.LightEnvironment ) ) then

		self.LightEnvironment:Fire( "FadeToPattern", tostring( style ) );

	else

		engine.LightStyle( 0, style );

		timer.Simple( 0.1, function()

			net.Start( "atmos_lightmaps" );
			net.Broadcast();

		end );

	end

	self.LastLightStyle = style;

end

local lastTime = 0;
local lastTimeMul = 0;
local lastTransitionMul = 0;

function SkyClass:UpdateTime()

	if ( Atmos:GetSettings().Paused ) then return end
	if ( !IsValid( g_AtmosManager ) ) then return end

	self.Time = (Atmos:GetSettings().Realtime and self:GetRealTime() or self.Time + (FrameTime() * Atmos:GetSettings().TimeMul));

	if ( self.Time >= 24 ) then

		self.Time = 0;

	end

	if ( lastTime != self.Time and self.NextTimeUpdate < CurTime() ) then

		g_AtmosManager:SetTime( self.Time );
		lastTime = self.Time;

		self.NextTimeUpdate = CurTime() + Atmos:GetSettings().TimeUpdateDelay;

	end

	if ( lastTimeMul != Atmos:GetSettings().TimeMul ) then

		g_AtmosManager:SetTimeMul( Atmos:GetSettings().TimeMul );
		lastTimeMul = Atmos:GetSettings().TimeMul;

	end

	if ( lastTransitionMul != Atmos:GetSettings().TransitionMul ) then

		g_AtmosManager:SetTransitionMul( Atmos:GetSettings().TransitionMul );
		lastTransitionMul = Atmos:GetSettings().TransitionMul;

	end

end

function SkyClass:UpdateLighting()

	local mul = 0;

	if ( self.Time >= 4 and self.Time < 12 ) then

		mul = math.EaseInOut( ( self.Time - 4 ) / 8, 0, 1 );

	elseif ( self.Time >= 12 and self.Time < 20 ) then

		mul = math.EaseInOut( 1 - ( self.Time - 12 ) / 8, 1, 0 );

	end

	local weather = Atmos:GetWeather();
	local maxDarkness = self.MaxDarkness;
	local maxLightness = self.MaxLightness;

	if ( IsValid( weather ) and weather:ShouldUpdateLighting() ) then

		maxDarkness = weather.MaxDarkness;
		maxLightness = weather.MaxLightness;

	end

	local s = string.char( math.Round( Lerp( mul, string.byte( maxDarkness ), string.byte( maxLightness ) ) ) );

	self:UpdateLightStyle( s );

end

local lastSunState = nil;
local lastSunAng = Angle( 0, 0, 0 );
local lastSunNormal = Vector( 0, 0, 0 );

function SkyClass:UpdateSun()

	if ( !IsValid( self.Sun ) ) then return end
	if ( CurTime() < self.NextSunUpdate ) then return end

	local cloudy = IsValid( Atmos:GetWeather() ) and Atmos:GetWeather():IsCloudy();
	local night = ((self.Time < 4 or self.Time > 20) and true or false);
	local mul = 1 - ( self.Time - 4 ) / 16;
	local ang = Angle( 180 * mul, 0, 0 );
	local SunAng = -ang:Forward();

	local SunNormal = self.Sun:GetInternalVariable( "m_vDirection" );

	if ( lastSunAng != SunAng ) then

		-- update sun direction
		self.Sun:SetKeyValue( "sun_dir", tostring( SunAng ) );
		lastSunAng = SunAng;

	end

	-- update sun normal for clientside effects
	if ( IsValid( g_AtmosManager ) and isvector( SunNormal ) and lastSunNormal != SunNormal ) then

		g_AtmosManager:SetSunNormal( SunNormal );

	end

	-- update map shadows based on sun direction
	self:UpdateShadows( ang );

	if ( cloudy or night ) then

		if ( lastSunState == nil or lastSunState ) then

			self.Sun:Fire( "TurnOff" );
			lastSunState = false;

		end

	else

		if ( lastSunState == nil or !lastSunState ) then

			self.Sun:Fire( "TurnOn" );
			lastSunState = true;

		end

	end

	self.NextSunUpdate = CurTime() + Atmos:GetSettings().SunUpdateDelay;

end

local lastAng = Angle( 0, 0, 0 );
local lastDistance = 0;
local lastDisabled = "0";

function SkyClass:UpdateShadows( ang )

	if ( !IsValid( self.ShadowControl ) ) then return end
	if ( !Atmos:GetSettings().Shadows ) then return end

	local fade = (ang.p / 180);
	local distance = fade * 70;
	local disabled = (fade > 0 and "0" or "1");

	if ( lastAng != ang ) then

		self.ShadowControl:Fire( "SetAngles", math.Round(ang.p) .. " " .. math.Round(ang.y) .. " " .. math.Round(ang.r) );
		lastAng = ang;

	end

	if ( lastDistance != distance ) then

		self.ShadowControl:Fire( "SetDistance", distance );
		lastDistance = distance;

	end

	if ( lastDisabled != disabled ) then

		self.ShadowControl:Fire( "SetShadowsDisabled", disabled );
		lastDisabled = disabled;

	end

end

function SkyClass:TriggerRelay( relay )

	for _, v in pairs( ents.FindByName( relay ) ) do

		v:Fire( "Trigger" );

	end

	hook.Call( "AtmosTimePeriod", GAMEMODE or nil, tostring( relay ) );

end

function SkyClass:UpdateOutputs()

	if ( self.Time < 6 ) then

		self.LastTimePeriod = TIME_DUSK;

	elseif ( self.Time < 18 ) then

		if ( self.LastTimePeriod != TIME_DAWN ) then

			self:TriggerRelay( "dawn" );

		end

		self.LastTimePeriod = TIME_DAWN;

	else

		if ( self.LastTimePeriod != TIME_DUSK ) then

			self:TriggerRelay( "dusk" );

		end

		self.LastTimePeriod = TIME_DUSK;

	end

end

-- Sky updating is clientside only for major network optimization
if SERVER then return end

-- TODO: Bezier Curve instead of linear interpolation?
local updateSky = false;

function SkyClass:UpdateSkybox()

	if ( !IsValid( g_AtmosManager ) or !IsValid( g_SkyPaint ) ) then return end

	self.SkyPaint = g_SkyPaint;
	self.Time = g_AtmosManager:GetTime();
	self.TimeMul = g_AtmosManager:GetTimeMul();
	self.TransitionMul = g_AtmosManager:GetTransitionMul();
	self.NewSunNormal = g_AtmosManager:GetSunNormal();

	if ( !self.CurrentSunNormal ) then

		self.CurrentSunNormal = self.NewSunNormal;

	end

	if ( self.Time < 4 or self.Time > 20 ) then

		self.NextSky = self.SkyColors[TIME_NIGHT];

	elseif ( self.Time < 6 ) then

		self.NextSky = self.SkyColors[TIME_DAWN];

	elseif ( self.Time < 18 ) then

		self.NextSky = self.SkyColors[TIME_NOON];

	elseif ( self.Time < 20 ) then

		self.NextSky = self.SkyColors[TIME_DUSK];

	end

	if ( IsValid( Atmos:GetWeather() ) and Atmos:GetWeather():ShouldUpdateSky() ) then

		self.NextSky = Atmos:GetWeather():GetSkyColors( self.Time );

	end

	local starTexture = self.SkyPaint:GetStarTexture();
	local cloudy = (IsValid( Atmos:GetWeather() ) and Atmos:GetWeather():IsCloudy());

	if ( cloudy and starTexture != "skybox/clouds" ) then

		self.SkyPaint:SetStarTexture( "skybox/clouds" );
		self.SkyPaint:SetStarScale( 1 );
		self.SkyPaint:SetStarFade( 0.4 );
		self.SkyPaint:SetStarSpeed( 0.03 );

		atmos_log( "skybox set to " .. tostring( self.SkyPaint:GetStarTexture() ) );

	elseif ( !cloudy and starTexture != "atmos/starfield" ) then

		self.SkyPaint:SetStarTexture( "atmos/starfield" );
		self.SkyPaint:SetStarScale( 0.5 );
		self.SkyPaint:SetStarFade( 1.5 );
		self.SkyPaint:SetStarSpeed( 0.01 );

		atmos_log( "skybox set to " .. tostring( self.SkyPaint:GetStarTexture() ) );

	end

	if ( self.CurrentSky == nil ) then

		self.CurrentSky = table.Copy( self.NextSky );
		updateSky = true;

	end

	for k, v in pairs( self.CurrentSky ) do

		if ( self.NextSky[k] != nil and v != self.NextSky[k] ) then

			updateSky = true;
			break;

		end

	end

	if ( updateSky ) then

		local frac = FrameTime() * self.TransitionMul;

		self.CurrentSky.TopColor = LerpVector( frac, self.CurrentSky.TopColor, self.NextSky.TopColor );
		self.CurrentSky.BottomColor = LerpVector( frac, self.CurrentSky.BottomColor, self.NextSky.BottomColor );
		self.CurrentSky.DuskColor = LerpVector( frac, self.CurrentSky.DuskColor, self.NextSky.DuskColor );
		self.CurrentSky.SunColor = LerpVector( frac, self.CurrentSky.SunColor, self.NextSky.SunColor );

		self.CurrentSky.FadeBias = Lerp( frac, self.CurrentSky.FadeBias, self.NextSky.FadeBias );
		self.CurrentSky.HDRScale = Lerp( frac, self.CurrentSky.HDRScale, self.NextSky.HDRScale );
		self.CurrentSky.DuskIntensity = Lerp( frac, self.CurrentSky.DuskIntensity, self.NextSky.DuskIntensity );
		self.CurrentSky.DuskScale = Lerp( frac, self.CurrentSky.DuskScale, self.NextSky.DuskScale );
		self.CurrentSky.SunSize = Lerp( frac, self.CurrentSky.SunSize, self.NextSky.SunSize );

		self.CurrentSunNormal = LerpVector( frac, self.CurrentSunNormal, self.NewSunNormal );

		self.SkyPaint:SetTopColor( self.CurrentSky.TopColor );
		self.SkyPaint:SetBottomColor( self.CurrentSky.BottomColor );
		self.SkyPaint:SetFadeBias( self.CurrentSky.FadeBias );
		self.SkyPaint:SetHDRScale( self.CurrentSky.HDRScale );
		self.SkyPaint:SetDuskIntensity( self.CurrentSky.DuskIntensity );
		self.SkyPaint:SetDuskScale( self.CurrentSky.DuskScale );
		self.SkyPaint:SetDuskColor( self.CurrentSky.DuskColor );
		self.SkyPaint:SetSunColor( self.CurrentSky.SunColor );
		self.SkyPaint:SetSunSize( self.CurrentSky.SunSize );
		self.SkyPaint:SetSunNormal( self.CurrentSunNormal );

	end

end

function SkyClass:RenderScene( origin, angles, fov )

	self.LastSceneOrigin = origin;
	self.LastSceneAngles = angles;

end

function SkyClass:CalcView( pl, pos, ang, fov, nearZ, farZ )

	self.LastNearZ = nearZ;
	self.LastFarZ = farZ;

end

local moonAlpha = 0;
local moonMat = Material( "atmos/moon.png" );
local devCVar = GetConVar( "developer" );
moonMat:SetInt( "$additive", 0 );
moonMat:SetInt( "$translucent", 0 );

function SkyClass:RenderMoon()

	if ( !IsValid( g_AtmosManager ) ) then return end

	local time = g_AtmosManager:GetTime();
	local night = ((time < 4 or time > 20) and true or false);

	if ( night ) then

		local mul;

		if ( time > 20 ) then

			mul = 1 - ( time + 4 ) / 8;

		else

			mul = 1 - ( time - 4 ) / 8;

		end

		local pos = Angle( 180 * mul, 0, 0 ):Forward() * ( self.LastFarZ * 0.900 );
		local normal = ( vector_origin - pos ):GetNormal();

		moonAlpha = Lerp( FrameTime() * 1, moonAlpha, 255 );

		local moonSize = Atmos:GetSettings().MoonSize;

		if !devCVar:GetBool() then return end -- Moon rendering is messed up, better to disable for now

		cam.Start3D( vector_origin, self.LastSceneAngles );
			render.OverrideDepthEnable( true, false );
			render.SetMaterial( moonMat );
			render.DrawQuadEasy( pos, normal, moonSize, moonSize, Color( 255, 255, 255, moonAlpha ), -180 );
			render.OverrideDepthEnable( false, false );
		cam.End3D();

	else

		if ( moonAlpha != 0 ) then

			moonAlpha = 0;

		end

	end

end
