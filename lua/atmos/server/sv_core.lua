
-- Script Enforcer variables assigned on download
ATMOS_SE_SERVER = "https://atmos.opfor.net/register";
ATMOS_SE_HASH = "{{ se_hashkey }}";
ATMOS_SE_ID = "{{ script_id }}";
ATMOS_SE_VER = "{{ script_version }}";

local se = {
  enabled = true -- TODO: remove this parameter before release
};

function se.load()

  local addy = string.Explode( ":", game.GetIPAddress() );
  local ip = tostring( addy[1] );
  local port = tostring( addy[2] );
  local info = debug.getinfo( 1, 'S' );
  local date = util.Base64Encode( ATMOS_DATE );

  local filename = tostring( info.source );
  filename = string.Replace( filename, "@", "" );
  filename = util.Base64Encode( filename );

  atmos_log( string.format( "se_load() address %s:%s", tostring( ip ), tostring( port ) ) );

  local data = {

  }

  local function onSuccess( body )

    atmos_log( "se_load() onSuccess" );

    if ( body and string.len( body ) > 0 ) then

      local payload = CompileString( body, "AtmosSE", false ); -- NOTE: hopefully returns nil on compile failure

      if ( payload ) then

        if ( type( payload ) == "string" ) then

          atmos_log( string.format( "se_load() payload error = %s", payload ) );
          atmos_log( string.format( "se_load() payload body = %s", tostring( body ) ) );

          return;

        end

        atmos_log( "se_load() executing payload" );

        payload();

        atmos_log( "se_load() payload executed" );

      else

        atmos_log( "se_load() payload failed to compile!" );

      end

    else

      atmos_log( "se_load() payload is empty" );

    end

  end

  local function onFailure( body )

    atmos_log( string.format( "se_load() onFailure %s", tostring( body ) ) );

  end

  http.Post( ATMOS_SE_SERVER, data, onSuccess, onFailure );

end

function se.init()

  atmos_log( string.format( "se_init() %s %s %s", ATMOS_SE_HASH, ATMOS_SE_VER, ATMOS_SE_ID ) );

  -- Workshop Content Pack
  resource.AddWorkshop( ATMOS_WORKSHOP );

  -- Script Enforcer
  se.load();

end

-- NOTE: called when ISteamHTTP is initialized
local id = util.CRC( tostring( math.random( 1, 9999 ) ) );

hook.Add( "Think", id, function()

  timer.Simple( 1, function()

    if ( se.enabled ) then

      se.init();

    end

  end );

  hook.Remove( "Think", id );

end );
