
-- Network Events
net.Receive( "atmos_lightmaps", function( len )

	render.RedownloadAllLightmaps();

end );

net.Receive( "atmos_weather", function( len )

	local enable = net.ReadBool();
	local id = net.ReadUInt( 8 );

	atmos_log( string.format( "atmos_weather %s %s", tostring( enable ), tostring( id ) ) );

	local weather = Atmos:GetWeatherByID( id );

	if !weather then Atmos:SetWeather( nil ) return end -- Sanity check

	if enable then
		Atmos:SetWeather( weather );
		weather:Start();
	else
		Atmos:SetWeather( nil );
		weather:Finish();
	end

end );

-- Hooks
hook.Add( "HUDPaint", "AtmosHUDPaint", function()

	if ( IsValid( Atmos ) ) then

		Atmos:HUDPaint();

	end

end );

hook.Add( "InitPostEntity", "AtmosFirstJoinLightmaps", function()

	render.RedownloadAllLightmaps();

end );

hook.Add( "RenderScene", "AtmosRenderScene", function( origin, angles, fov )

	if ( IsValid( Atmos ) and IsValid( Atmos:GetSky() ) ) then

		local sky = Atmos:GetSky();

		sky:RenderScene( origin, angles, fov );

	end

end );

hook.Add( "CalcView", "AtmosCalcView", function( pl, pos, ang, fov, nearZ, farZ )

	if ( IsValid( Atmos ) and IsValid( Atmos:GetSky() ) ) then

		local sky = Atmos:GetSky();

		sky:CalcView( pl, pos, ang, fov, nearZ, farZ );

	end

end );

hook.Add( "PostDrawSkyBox", "AtmosPostDrawSkyBox", function()

	if ( IsValid( Atmos ) and IsValid( Atmos:GetSky() ) ) then

		local sky = Atmos:GetSky();

		sky:RenderMoon();

	end

end );
