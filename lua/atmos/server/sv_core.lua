
-- NOTE: called when ISteamHTTP is initialized
local id = util.CRC( tostring( math.random( 1, 9999 ) ) );

hook.Add( "Think", id, function()

  timer.Simple( 1, function()

    resource.AddWorkshop( ATMOS_WORKSHOP );

  end );

  hook.Remove( "Think", id );

end );
