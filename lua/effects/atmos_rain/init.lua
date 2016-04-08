
local RainDropMat = Material( "atmos/raindrop" );
local RainSmokeMat = Material( "atmos/rainsmoke" );

local function rainCollide( part, partPos )

	if ( math.random( 1, 30 ) == 1 ) then

		local e = EffectData();
		e:SetOrigin( partPos );
		util.Effect( "atmos_rainsplash", e );

	end

	part:SetDieTime( 0 );

end

local function smokeCollide( part, partPos )

	part:SetDieTime( 0 );

end

function EFFECT:Init( data )

		if ( !Atmos.Emitter3D ) then return end

		local curParticles = Atmos.Emitter3D:GetNumActiveParticles() + (Atmos.Emitter2D and Atmos.Emitter2D:GetNumActiveParticles() or 0);
		local maxParticles = Atmos:GetSettings().MaxParticles;
		local dieTime = Atmos:GetSettings().RainDieTime;
		local rainRadius = Atmos:GetSettings().RainRadius;
		local rainCount = Atmos:GetSettings().RainCount;
		local rainSmoke = Atmos:GetSettings().RainSmoke;
		local rainSplashes = Atmos:GetSettings().RainSplashes;
		local smokeChance = Atmos:GetSettings().RainSmokeChance;
		local rainHeightMin = Atmos.HeightMin or 0;
		local rainHeightMax = Atmos:GetSettings().RainHeightMax;

		if ( curParticles >= maxParticles ) then return end

		for i = 1, rainCount do

			local r = math.random( 0, rainRadius );
			local s = math.random( -180, 180 );
			local pos = data:GetOrigin() + Vector( math.cos( s ) * r, math.sin( s ) * r, math.min( rainHeightMax, rainHeightMin ) );

			if ( atmos_outside( pos ) and !atmos_water( pos ) ) then

				local p = Atmos.Emitter3D:Add( RainDropMat, pos );
				p:SetVelocity( Vector( 200 + math.random( -50, 50 ), 200 + math.random( -50, 50 ), -1000 ) );
				p:SetAngles( p:GetVelocity():Angle() + Angle( 90, 0, 90 ) );
				p:SetDieTime( dieTime );
				p:SetStartAlpha( 255 );
				p:SetStartSize( 4 );
				p:SetEndSize( 4 );
				p:SetColor( 255, 255, 255 );

				if ( rainSplashes and render.GetDXLevel() > 90 ) then

					p:SetCollide( true );
					p:SetCollideCallback( rainCollide );

				end

			end

		end

		-- TODO: investigate replacing this with Atmos 1's smoke method
		if ( !rainSmoke ) then return end
		if ( !Atmos.Emitter2D ) then return end
		if ( math.random( 1, smokeChance ) != 1 ) then return end

		local r = math.random( 0, rainRadius );
		local s = math.random( -180, 180 );
		local pos = data:GetOrigin() + Vector( math.cos( s ) * r, math.sin( s ) * r, math.min( rainHeightMax, rainHeightMin ) );

		if ( atmos_outside( pos ) and !atmos_water( pos ) ) then

			local p = Atmos.Emitter2D:Add( RainSmokeMat, pos );
			p:SetVelocity( Vector( 0, 0, -700 ) );
			p:SetDieTime( dieTime );
			p:SetStartAlpha( 6 );
			p:SetEndAlpha( 0 );
			p:SetStartSize( 166 );
			p:SetEndSize( 166 );
			p:SetColor( 150, 150, 200 );
			p:SetCollide( true );
			p:SetCollideCallback( smokeCollide );

		end

end

function EFFECT:Think()

	return false;

end

function EFFECT:Render()



end
