
-- Network Events
net.Receive( "atmos_settings", function( len )

	local settings = net.ReadTable();

	for k, v in pairs( settings ) do

		if ( Atmos:GetSettings()[k] == nil || Atmos:GetSettings()[k] != settings[k] ) then

			Atmos:GetSettings()[k] = settings[k];

		end

	end

	atmos_log( "received settings from server" );

end );

net.Receive( "atmos_cvars", function( len )

	local vars = net.ReadTable();

	for _, v in pairs( vars ) do

		CreateClientConVar( v.name, v.default, true, false, v.help );

		if ( v.callback ) then

			cvars.AddChangeCallback( v.name, v.callback, v.name .. "_callback" );

		end

	end

end );

-- Panels
local function LogoPanel()

	local logo = vgui.Create( "DImageButton" );
	logo:SetImage( "atmos/logo.png" );
	logo:SetSize( 128, 128 );
	logo.DoClick = function()

		local snd = Sound( "items/suitchargeno1.wav" );
		surface.PlaySound( snd );

		gui.OpenURL( ATMOS_LINK );

	end

	return logo;

end

local function InfoPanel( CPanel )

	CPanel:AddPanel( LogoPanel() );
	CPanel:AddControl( "label", { text = string.format( "Version %s", tostring( ATMOS_VERSION ) ) } );

end

local function ServerPanel( CPanel )

	CPanel:AddPanel( LogoPanel() );



end

local function ClientPanel( CPanel )

	CPanel:AddPanel( LogoPanel() );

end

-- Hooks
hook.Add( "PopulateToolMenu", "PopulateAtmosMenus", function()

	spawnmenu.AddToolMenuOption( "Options", "Atmos", "AtmosInfo", "Atmos Info", "", "", InfoPanel );
	spawnmenu.AddToolMenuOption( "Options", "Atmos", "AtmosServer", "Server Settings", "", "", ServerPanel );
	spawnmenu.AddToolMenuOption( "Options", "Atmos", "AtmosClient", "Client Settings", "", "", ClientPanel );

end );

hook.Add( "AddToolMenuCategories", "CreateAtmosCategories", function()

	spawnmenu.AddToolCategory( "Options", "Atmos", "Atmos 2" );

end );
