
local RainSplashMat = Material( "atmos/rainsplash" );

function EFFECT:Init( data )

	if ( !Atmos.Emitter2D ) then return end

	local p = Atmos.Emitter2D:Add( RainSplashMat, data:GetOrigin() );
	p:SetDieTime( 0.5 );
	p:SetStartAlpha( 15 );
	p:SetEndAlpha( 0 );
	p:SetStartSize( 2 );
	p:SetEndSize( 2 );
	p:SetColor( 255, 255, 255 );

end

function EFFECT:Think()

	return false;

end

function EFFECT:Render()



end
