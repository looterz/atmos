
local Weather = atmos_class();

function Weather:__constructor()

  self.ID = 2;

end

function Weather:__tostring()

  return "Snow";

end

function Weather:IsValid()

  return self.Valid;

end

function Weather:Initialize()

    self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)

end

function Weather:GetID()

  return self.ID;

end

function Weather:Start()

  self.Valid = true;

  atmos_log( tostring( self ) .. " start" );

end

function Weather:Finish()

  self.Valid = false;

  atmos_log( tostring( self ) .. " finish" );

end

function Weather:Think()

  if CLIENT then

    local pos = LocalPlayer():GetPos();

    -- particles
    local snowEffectData = EffectData();
    snowEffectData:SetOrigin( pos );

    util.Effect( "atmos_snow", snowEffectData );

  end

end

function Weather:ShouldUpdateLighting()

  return false;

end

function Weather:ShouldUpdateSky()

  return false;

end

function Weather:ShouldUpdateFog()

  return false;

end

function Weather:ShouldUpdateWind()

  return false;

end

function Weather:IsCloudy()

  return false;

end

if CLIENT then

  function Weather:HUDPaint()

  end

end

Atmos:RegisterWeather( Weather() );
