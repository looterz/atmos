
-- Core
ATMOS_DEBUG_CVAR = CreateConVar( "atmos_debug", "0", bit.bor( FCVAR_ARCHIVE, FCVAR_GAMEDLL, FCVAR_REPLICATED, FCVAR_NOTIFY ), "Toggles atmos debug mode and enables logging." );

AddCSLuaFile();

AddCSLuaFile( "atmos/shared/sh_enum.lua" );
AddCSLuaFile( "atmos/shared/sh_util.lua" );
AddCSLuaFile( "atmos/shared/sh_atmos.lua" );
AddCSLuaFile( "atmos/shared/sh_sky.lua" );
AddCSLuaFile( "atmos/shared/sh_fog.lua" );
AddCSLuaFile( "atmos/shared/sh_core.lua" );
AddCSLuaFile( "atmos/shared/sh_settings.lua" );
AddCSLuaFile( "atmos/client/cl_core.lua" );
AddCSLuaFile( "atmos/client/cl_settings.lua" );

if SERVER then

	include( "atmos/server/sv_net.lua" );

end

include( "atmos/shared/sh_enum.lua" );
include( "atmos/shared/sh_util.lua" );
include( "atmos/shared/sh_atmos.lua" );
include( "atmos/shared/sh_settings.lua" );
include( "atmos/shared/sh_sky.lua" );
include( "atmos/shared/sh_fog.lua" );
include( "atmos/shared/sh_core.lua" );

atmos_log( string.format( "version %s", tostring( ATMOS_VERSION ) ) );
atmos_log( string.format( "booting %s...", (SERVER and "server" or "client") ) );
atmos_log( "loading core..." );

if SERVER then

	include( "atmos/server/sv_wind.lua" );
	include( "atmos/server/sv_commands.lua" );
	include( "atmos/server/sv_core.lua" );

else

	include( "atmos/client/cl_core.lua" );
	include( "atmos/client/cl_settings.lua" );

end

atmos_log( "core loaded." );

-- Weather
local wfiles = file.Find( "atmos/weathers/*.lua", "LUA" );

if #wfiles > 0 then

	for _, f in ipairs( wfiles ) do

		atmos_log( "loading weather: " .. f );

		if SERVER then

			AddCSLuaFile( "atmos/weathers/" .. f );

		end

		include( "atmos/weathers/" .. f );

	end

end

atmos_log( "boot complete." );

hook.Call( "AtmosInit" );
