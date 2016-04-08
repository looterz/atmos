
local SnowMat = Material( "atmos/snow" );

local function snowCollide( part, partPos )

	part:SetDieTime( 0 );

end

function EFFECT:Init( data )

		if ( !Atmos.Emitter2D ) then return end

		local curParticles = (Atmos.Emitter3D and Atmos.Emitter3D:GetNumActiveParticles() or 0) + Atmos.Emitter2D:GetNumActiveParticles();
		local maxParticles = Atmos:GetSettings().MaxParticles;
		local dieTime = Atmos:GetSettings().SnowDieTime;
		local snowRadius = Atmos:GetSettings().SnowRadius;
		local snowCount = Atmos:GetSettings().SnowCount;
		local snowHeightMin = Atmos.HeightMin or 0;
		local snowHeightMax = Atmos:GetSettings().SnowHeightMax;

		if ( curParticles >= maxParticles ) then return end

		for i = 1, snowCount do

			local r = math.random( 0, snowRadius );
			local s = math.random( -180, 180 );
			local pos = data:GetOrigin() + Vector( math.cos( s ) * r, math.sin( s ) * r, math.min( snowHeightMax, snowHeightMin ) );

			if ( atmos_outside( pos ) and !atmos_water( pos ) ) then

				local p = Atmos.Emitter2D:Add( SnowMat, pos );
				p:SetVelocity( Vector( 20 + math.random( -5, 5 ), 20 + math.random( -5, 5 ), -80 ) );
				p:SetRoll( math.random( -360, 360 ) );
				p:SetDieTime( dieTime );
				p:SetStartAlpha( 200 );
				p:SetStartSize( 1 );
				p:SetEndSize( 1 );
				p:SetColor( 255, 255, 255 );
				p:SetCollide( true );
				p:SetCollideCallback( snowCollide );

			end

		end

end

function EFFECT:Think()

	return false;

end

function EFFECT:Render() end
