
FogClass = atmos_class();

local TIME_DAWN 	= 6;
local TIME_NOON 	= 12;
local TIME_DUSK 	= 18;
local TIME_NIGHT 	= 24;

function FogClass:__constructor()

	if SERVER then

		self.FogController = ents.FindByClass( "env_fog_controller" )[1];

		if ( !IsValid( self.FogController ) ) then

			self.FogController = ents.Create( "env_fog_controller" ); -- must exist for atmos_fog to function
			self.FogController:Spawn();
			self.FogController:Activate();

		end

		self.Fog = ents.Create( "atmos_fog" );
		self.Fog:Spawn();
		self.Fog:Activate();

	end

	self.FogValues = Atmos:GetSettings().FogValues;

	self.Valid = true;

end

function FogClass:__tostring()

	return "[Atmos Fog Object]";

end

function FogClass:IsValid()

	return self.Valid;

end

function FogClass:Think()

	if ( !IsValid( self ) ) then return end

	if CLIENT then

		self:SetupFog();

	end

end

if SERVER then return end

-- TODO: fog rolls in during morning, rolls out during evening, random density, fogend influenced by map default?
local updateFog = false;

function FogClass:SetupFog()

	if ( !IsValid( self ) or !IsValid( g_AtmosManager ) or !IsValid( g_Fog ) ) then return end

	self.Fog = g_Fog;
	self.Time = g_AtmosManager:GetTime();
	self.TimeMul = g_AtmosManager:GetTimeMul();
	self.TransitionMul = 0.3;

	if ( self.Time < 4 or self.Time > 20 ) then

		self.NextFog = self.FogValues[ TIME_NIGHT ];

	elseif ( self.Time < 6 ) then

		self.NextFog = self.FogValues[ TIME_DAWN ];

	elseif ( self.Time < 18 ) then

		self.NextFog = self.FogValues[ TIME_NOON ];

	elseif ( self.Time < 20 ) then

		self.NextFog = self.FogValues[ TIME_DUSK ];

	end

	if ( IsValid( Atmos:GetWeather() ) and Atmos:GetWeather():ShouldUpdateFog() ) then

		self.NextFog = Atmos:GetWeather():GetFogValues( self.Time );

	end

	if ( self.CurrentFog == nil ) then

		self.CurrentFog = table.Copy( self.NextFog );
		updateFog = true;

	end

	for k, v in pairs( self.CurrentFog ) do

		if ( self.NextFog[k] != nil and v != self.NextFog[k] ) then

			updateFog = true;
			break;

		end

	end

	if ( updateFog ) then

		local frac = FrameTime() * self.TransitionMul;

		self.CurrentFog.FogStart = Lerp( frac, self.CurrentFog.FogStart, self.NextFog.FogStart );
		self.CurrentFog.FogEnd = Lerp( frac, self.CurrentFog.FogEnd, self.NextFog.FogEnd );
		self.CurrentFog.FogDensity = Lerp( frac, self.CurrentFog.FogDensity, self.NextFog.FogDensity );
		self.CurrentFog.FogColor = LerpVector( frac, self.CurrentFog.FogColor, self.NextFog.FogColor );

		self.Fog:SetFogStart( self.CurrentFog.FogStart );
		self.Fog:SetFogEnd( self.CurrentFog.FogEnd );
		self.Fog:SetFogDensity( self.CurrentFog.FogDensity );
		self.Fog:SetFogColor( self.CurrentFog.FogColor );

	end

end
