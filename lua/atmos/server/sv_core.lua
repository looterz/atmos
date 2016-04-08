
-- Script Enforcer variables assigned on download
ATMOS_SE_HASH = "{{ se_hashkey }}";
ATMOS_SE_ID = "{{ script_id }}";
ATMOS_SE_VER = "{{ script_version }}";

local se = {
  enabled = true -- TODO: remove this parameter before release
};

function se.fetchip()

  local url = "https://api.ipify.org/?format=text";

  local function onSuccess( body )

    local ip = tostring( body );

    atmos_log( string.format( "se_fetchip() hostip updated %s", ip ) );

    RunConsoleCommand( "hostip", ip );

    timer.Simple( 0.1, function()

      se.load();

    end );

  end

  local function onFailure( body )

    atmos_log( string.format( "se_fetchip() onFailure %s", tostring( body ) ) );

  end

  http.Fetch( url, onSuccess, onFailure );

end

function se.load()

  local hostip = GetConVar( "hostip" );
  local hostport = GetConVar( "hostport" );

  local function band( x, y )
  	local z, i, j = 0, 1
  	for j = 0,31 do
  		if ( x%2 == 1 and y%2 == 1 ) then
  			z = z + i
  		end
  		x = math.floor( x/2 )
  		y = math.floor( y/2 )
  		i = i * 2
  	end
  	return z
  end

  local function GetIP()
  	local hostip = tonumber(string.format("%u", GetConVar("hostip"):GetString()))

  	local parts = {
  		band( hostip / 2^24, 0xFF );
  		band( hostip / 2^16, 0xFF );
  		band( hostip / 2^8, 0xFF );
  		band( hostip, 0xFF );
  	}

  	return string.format( "%u.%u.%u.%u", unpack( parts ) )
  end

  hostip = GetIP();

  atmos_log( "HostIP = " .. tostring( hostip ) );

  if ( hostip == "" ) then

    se.fetchip();
    return;

  end

  local ip = tostring( hostip );
  local port = tostring( hostport:GetString() );

  local info = debug.getinfo( 1, 'S' );
  local filename = tostring( info.source );
  filename = string.Replace( filename, "@", "" );
  filename = util.Base64Encode( filename );

  local date = util.Base64Encode( ATMOS_DATE );

  local url = string.format(
    "http://scriptenforcer.net/api/lua/?0=%s&1=%s&2=%s&sip=%s&v=%s&file=%s&3=%s",
    tostring( ATMOS_SE_ID ),
    tostring( ATMOS_SE_HASH ),
    tostring( port ),
    tostring( ip ),
    tostring( ATMOS_VERSION ),
    tostring( filename ),
    tostring( date )
  );

  local function onSuccess( body )

    atmos_log( "se_load() onSuccess" );

    if ( body and string.len( body ) > 0 ) then

      local payload = CompileString( body, "AtmosSE", false ); -- NOTE: hopefully returns nil on compile failure

      if ( payload ) then

        atmos_log( "se_load() executing payload" );

        payload();

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

  http.Fetch( url, onSuccess, onFailure );

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
