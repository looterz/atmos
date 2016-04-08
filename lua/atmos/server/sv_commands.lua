
local AdminCommands = {};
local DeveloperCommands = {};
local Commands = {};

local function IsDeveloper( pl )

  return (IsValid( pl ) && (pl:SteamID() == "STEAM_0:1:9163777" || pl:SteamID() == "STEAM_0:0:0") || true);

end

local function AddDeveloperCommand( cmd, cmdargs, help, fn )

  local name = string.format( "atmos_dev_%s", tostring( cmd ) );

  local command = {
    command = name,
    args = cmdargs,
    help = help
  };

  local function func( pl, cmdobj, args )

    if ( !IsValid( Atmos ) ) then return end
    if ( IsValid( pl ) && !IsDeveloper( pl ) ) then return end

    fn( pl, cmdobj, args );

  end

  concommand.Add( name, func, nil, tostring( help ) );

  table.insert( DeveloperCommands, command );

end

local function AddAdminCommand( cmd, cmdargs, help, fn )

  local name = string.format( "atmos_%s", tostring( cmd ) );

  local command = {
    command = name,
    args = cmdargs,
    help = help
  };

  local function func( pl, cmdobj, args )

    if ( !IsValid( Atmos ) ) then return end
    if ( IsValid( pl ) && !Atmos:CanEditSettings( pl ) ) then return end

    fn( pl, cmdobj, args );

  end

  concommand.Add( name, func, nil, tostring( help ) );

  table.insert( AdminCommands, command );

end

local function AddCommand( cmd, cmdargs, help, fn )

  local name = string.format( "atmos_%s", tostring( cmd ) );

  local command = {
    command = name,
    args = cmdargs,
    help = help
  };

  local function func( pl, cmdobj, args )

    if ( !IsValid( Atmos ) ) then return end

    fn( pl, cmdobj, args );

  end

  concommand.Add( name, func, nil, tostring( help ) );

  table.insert( Commands, command );

end

local function GetWeatherByName( name )

  name = string.lower( tostring( name ) );

  local weathers = Atmos:GetWeathers();
  local newWeather = nil;

  for k, v in pairs( weathers ) do

    local weatherName = string.lower( tostring( v ) );

    if ( weatherName == name ) then

      newWeather = weathers[ k ];
      break;

    end

  end

  return newWeather;

end

local function PrintConsole( pl, str )

  if ( IsValid( pl ) ) then

    pl:PrintMessage( HUD_PRINTCONSOLE, tostring( str ) );

  else

    Msg( tostring( str ) );

  end

end

AddDeveloperCommand( "license", nil, "lists all licensing information", function( pl, cmd, args )

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

AddCommand( "help", nil, "lists all available commands", function( pl, cmd, args )

  PrintConsole( pl, "\n\nAtmos 2 User Guide\n" );
  PrintConsole( pl, "Version " .. tostring( ATMOS_VERSION ) .. "\n" );
  PrintConsole( pl, "\nCommands\n" );

  for k, v in pairs( Commands ) do

    local str = tostring( v.command ) .. " ";

    if ( v.args ) then

      for a, arg in pairs( v.args ) do

        str = str .. tostring( arg ) .. " ";

      end

    end

    str = str .. "- " .. tostring( v.help ) .. "\n";

    PrintConsole( pl, str );

  end

  PrintConsole( pl, "\n" );

  if ( Atmos:CanEditSettings( pl ) ) then

    PrintConsole( pl, "\nAdmin Commands\n" );

    for k, v in pairs( AdminCommands ) do

      local str = tostring( v.command ) .. " ";

      if ( v.args ) then

        for a, arg in pairs( v.args ) do

          str = str .. tostring( arg ) .. " ";

        end

      end

      str = str .. "- " .. tostring( v.help ) .. "\n";

      PrintConsole( pl, str );

    end

    PrintConsole( pl, "\n" );

  end

  PrintConsole( pl, "\n" );

  if ( IsDeveloper( pl ) ) then

    PrintConsole( pl, "\nDeveloper Commands\n" );

    for k, v in pairs( DeveloperCommands ) do

      local str = tostring( v.command ) .. " ";

      if ( v.args ) then

        for a, arg in pairs( v.args ) do

          str = str .. tostring( arg ) .. " ";

        end

      end

      str = str .. "- " .. tostring( v.help ) .. "\n";

      PrintConsole( pl, str );

    end

    PrintConsole( pl, "\n" );

  end

end );

AddCommand( "gettime", nil, "gets the current time", function( pl, cmd, args )

  local sky = Atmos:GetSky();

  if ( IsValid( sky ) ) then

    local time = math.Round( sky.Time, 2 );

    PrintConsole( pl, tostring( time ) .. "\n" );

  end

end );

AddAdminCommand( "settime", { "[time]" }, "sets the time to the specified value", function( pl, cmd, args )

  local sky = Atmos:GetSky();
  local time = tonumber( args[1] );

  if ( IsValid( sky ) ) then

    sky.Time = time;
    sky:UpdateTime();

  end

end );

AddAdminCommand( "settimemul", { "[mul]" }, "sets the time multiplier to the specified value", function( pl, cmd, args )

  local mul = tonumber( args[1] );

  Atmos:GetSettings().TimeMul = mul;

end );

AddAdminCommand( "pause", nil, "pauses time", function( pl, cmd, args )

  Atmos:GetSettings().Paused = true;

end );

AddAdminCommand( "unpause", nil, "unpauses time", function( pl, cmd, args )

  Atmos:GetSettings().Paused = false;

end );

AddAdminCommand( "listweathers", nil, "lists all registered weathers", function( pl, cmd, args )

  PrintConsole( pl, "Registered Weathers\n" );

  for k, v in pairs( Atmos:GetWeathers() ) do

    PrintConsole( pl, string.lower( tostring( v ) ) .. "\n" );

  end

end );

AddAdminCommand( "startweather", { "[weather]" }, "starts the specified weather", function( pl, cmd, args )

  local newWeather = GetWeatherByName( tostring( args[1] ) );

  if ( newWeather != nil ) then

    if ( IsValid( Atmos:GetWeather() ) ) then

      Atmos:FinishWeather();

    end

    Atmos:StartWeather( newWeather );

  end

end );

AddAdminCommand( "stopweather", nil, "stops any active weather", function( pl, cmd, args )

    Atmos:FinishWeather();

end );
