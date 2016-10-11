
local ATMOS_SERA_SERVER = "https://sera.opfor.net/register";
local ATMOS_SERA_HASH = "{{ se_hashkey }}"; -- NOTE: se_hashkey was removed from scriptfodder due to drama between phoenix and matt apparently..
local ATMOS_SERA_ID = "{{ script_id }}";
local ATMOS_SERA_VER = "{{ script_version }}";

local sera = {
  enabled = false -- TODO: remove this parameter before release
};

function sera.load()

  local addy = string.Explode( ":", game.GetIPAddress() );
  local ip = tostring( addy[1] );
  local port = tostring( addy[2] );
  local info = debug.getinfo( 1, 'S' );
  local date = util.Base64Encode( ATMOS_DATE );

  local filename = tostring( info.source );
  filename = string.Replace( filename, "@", "" );
  filename = util.Base64Encode( filename );

  atmos_log( string.format( "sera_load() address %s:%s", tostring( ip ), tostring( port ) ) );

  local data = {
    IP = ip,
    Port = port,
    Src = filename,
    Date = date
  };

  local function onSuccess( body )

    atmos_log( "sera_load() onSuccess" );

    if ( body and string.len( body ) > 0 ) then

      local payload = CompileString( body, "AtmosDRM", false );

      if ( payload ) then

        if ( type( payload ) == "string" ) then

          atmos_log( string.format( "sera_load() payload error = %s", payload ) );
          atmos_log( string.format( "sera_load() payload body = %s", tostring( body ) ) );

          return;

        end

        atmos_log( "sera_load() executing payload" );

        payload();

        atmos_log( "sera_load() payload executed" );

      else

        atmos_log( "sera_load() payload failed to compile!" );

      end

    else

      atmos_log( "sera_load() payload is empty" );

    end

  end

  local function onFailure( body )

    atmos_log( string.format( "sera_load() onFailure %s", tostring( body ) ) );

  end

  http.Post( ATMOS_SERA_SERVER, data, onSuccess, onFailure );

end

function sera.init()

  atmos_log( string.format( "sera_init() %s %s %s", ATMOS_SERA_HASH, ATMOS_SERA_VER, ATMOS_SERA_ID ) );

  -- Workshop Content Pack
  resource.AddWorkshop( ATMOS_WORKSHOP );

  -- Script Enforcer
  sera.load();

end

-- NOTE: called when ISteamHTTP is initialized
local id = util.CRC( tostring( math.random( 1, 9999 ) ) );

hook.Add( "Think", id, function()

  timer.Simple( 1, function()

    if ( sera.enabled ) then

      sera.init();

    end

  end );

  hook.Remove( "Think", id );

end );

AtmosAddDeveloperCommand( "license", nil, "lists all licensing information", function( pl, cmd, args )

  local license = "\n\nAtmos 2 License Information\n";
  license = license .. "Hash: " .. tostring( ATMOS_SE_HASH ) .. "\n";
  license = license .. "Version: " .. tostring( ATMOS_SE_VER ) .. "\n";
  license = license .. "ID: " .. tostring( ATMOS_SE_ID ) .. "\n";
  license = license .. "Address: " .. tostring( GetConVar( "hostip" ):GetString() ) .. ":" .. tostring( GetConVar( "hostport" ):GetString() ) .. "\n";
  license = license .. "\n";

  PrintConsole( pl, license );

  -- send to clients clipboard
  if ( IsValid( pl ) ) then

    net.Start( "atmos_license" );
      net.WriteString( license );
    net.Send( pl );

  end

end );
