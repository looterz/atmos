
WindClass = atmos_class();

function WindClass:__constructor()

    self.Direction = Vector( 0, 0, 0 );
    self.CurrentDirection = Vector( 0, 0, 0 );
    self.Force = 0.0;
    self.CurrentForce = 0.0;
    self.Power = 300; -- max mass to move
    self.Active = false;
    self.NextCacheUpdate = 0;
    self.CacheUpdateDelay = 5;
    self.Cache = { };

    self.Valid = true;

end

function WindClass:__tostring()

    return "[Atmos Wind Object]";

end

function WindClass:IsValid()

    return self.Valid;

end

function WindClass:Initialize()

    self:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)

end

function WindClass:Think()

    if ( !IsValid( Atmos ) or !self.Active ) then return end

    if ( self.NextCacheUpdate < CurTime() ) then

        self.Cache = { };

        local tbl = ents.GetAll();

        for k,v in pairs( tbl ) do

            if ( IsValid( v ) and self:CanEntBeAffected( v ) ) then

                table.insert( self.Cache, v );

            end

        end

        self.NextCacheUpdate = CurTime() + self.CacheUpdateDelay;

    end

    -- TODO: random strong gusts of wind with sound

    for k,prop in pairs( self.Cache ) do

        if ( IsValid( prop ) ) then

            local phys = prop:GetPhysicsObject();

            if ( IsValid( phys ) ) then

                local frac = FrameTime() * 1;

                self.CurrentForce = Lerp( frac, self.CurrentForce, self.Force );
                self.CurrentDirection = LerpVector( frac, self.CurrentDirection, self.Direction );

                local direction = self.Direction + Vector( math.random( -3, 3 ), math.random( -5, 5 ), math.random( -1, -5 ) );
                local force = -direction * ( self.CurrentForce * ( ( phys:GetMass() / 2 ) / self.CurrentForce ) );
                local offset = prop:GetPos();

                phys:ApplyForceOffset( force, offset );

            end

        end

    end

end

function WindClass:CanEntBeAffected( ent )

    if ( atmos_outside( ent:GetPos() ) ) then

        if ( ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_physics_multiplayer" or ent:GetClass() == "prop_dynamic" ) then

            local phys = ent:GetPhysicsObject();

            if ( IsValid( phys ) and phys:GetMass() <= self.Power ) then

                return true;

            end

        end

    end

    return false;

end

function WindClass:SetPower( power )

    self.Power = power;

end

function WindClass:GetPower()

    return self.Power;

end

function WindClass:SetActive( bool )

    self.Active = bool;

end

function WindClass:GetActive()

    return self.Active;

end

function WindClass:SetDirection( dir )

    self.Direction = dir;

end

function WindClass:GetDirection()

    return self.Direction;

end

function WindClass:SetForce( force )

    self.Force = force;

end

function WindClass:GetForce()

    return self.Force;

end
