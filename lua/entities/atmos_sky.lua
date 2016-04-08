
AddCSLuaFile();

ENT.Type = "point";
ENT.DisableDuplicator	= true;

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:Initialize()

	if SERVER then return end

	self.Keys = {
		"TopColor",
		"BottomColor",
		"SunColor",
		"DuskColor",
		"FadeBias",
		"SunSize",
		"SunNormal",
		"DuskScale",
		"DuskIntensity",
		"HDRScale",
		"DrawStars",
		"StarSpeed",
		"StarScale",
		"StarFade",
		"StarTexture"
	};

	self.Values = {};

	for k,v in pairs( self.Keys ) do

		self["Get" .. tostring(v)] = function() return self.Values[tostring(v)] end
		self["Set" .. tostring(v)] = function( ent, value ) self.Values[tostring(v)] = value end

	end

	-- Defaults
	self:SetTopColor( Vector( 0.2, 0.5, 1.0 ) );
	self:SetBottomColor( Vector( 0.8, 1.0, 1.0 ) );
	self:SetFadeBias( 1 );
	self:SetSunNormal( Vector( 0.4, 0.0, 0.01 ) );
	self:SetSunColor( Vector( 0.2, 0.1, 0.0 ) );
	self:SetSunSize( 2.0 );
	self:SetDuskColor( Vector( 1.0, 0.2, 0.0 ) );
	self:SetDuskScale( 1 );
	self:SetDuskIntensity( 1 );
	self:SetHDRScale( 0.66 );

	self:SetDrawStars( true );
	self:SetStarSpeed( 0.01 );
	self:SetStarScale( 0.5 );
	self:SetStarFade( 1.5 );
	self:SetStarTexture( "atmos/starfield" );

	atmos_log( "skybox set to " .. tostring( self:GetStarTexture() ) );

end

function ENT:GetPaintValues()

	local tbl = {
		TopColor = self:GetTopColor(),
		BottomColor = self:GetBottomColor(),
		SunColor = self:GetSunColor(),
		DuskColor = self:GetDuskColor(),
		FadeBias = self:GetFadeBias(),
		SunSize = self:GetSunSize(),
		SunNormal = self:GetSunNormal(),
		DuskScale = self:GetDuskScale(),
		DuskIntensity = self:GetDuskIntensity(),
		HDRScale = self:GetHDRScale()
	};

	return tbl;

end

function ENT:Think()

	if ( g_SkyPaint != self ) then

			g_SkyPaint = self;

	end

end

function ENT:CanEditVariables( ply )

	return false;

end
