
-- NOTE: helper for easily logging values to console
function atmos_log( ... )

	if ( !ATMOS_DEBUG ) then return end

	local col = SERVER and Color( 255, 153, 0 ) or Color( 41, 128, 185 );

	MsgC( col, "[atmos] ", unpack( { ... } ), "\n" );

end

-- NOTE: helper for checking if a position is outside of a building
function atmos_outside( pos )

	local trace = { };
	trace.start = pos;
	trace.endpos = trace.start + Vector( 0, 0, 32768 );
	trace.mask = MASK_SOLID;

	local tr = util.TraceLine( trace );

	Atmos.HeightMin = tr.HitPos.z - trace.start.z; -- thanks to SW for this improvement

	if ( tr.StartSolid ) then return false end
	if ( tr.HitSky ) then return true end

	-- recursive, check past nodraw
	--if ( tr.HitNoDraw ) then return atmos_outside( pos + Vector( 0, 0, 128 ) ) end

	return false;

end

-- NOTE: helper for checking if a position contains water
function atmos_water( pos )

	return bit.band( util.PointContents( pos ), CONTENTS_WATER ) == CONTENTS_WATER;

end

-- NOTE: helper for creating classes
function atmos_class()

	local newclass = {};
	local metatable = {};

	newclass.__index = newclass;

	metatable.__call = function( tbl, ... )

		local obj = setmetatable( {}, newclass );

		if ( obj.__constructor ) then
			obj:__constructor( ... );
		end

		return obj;

	end

	setmetatable( newclass, metatable );

	return newclass;

end

-- NOTE: helpers for maintaining floating point precision when storing settings as JSON
function atmos_ntos( tbl )

	--atmos_log( "converting settings numbers to strings..." );

	for k,v in pairs( tbl ) do

		if ( type( v ) == "number" ) then

			tbl[k] = { val = tostring(v), orig = "number" };

		end

	end

	return tbl;

end

function atmos_ston( tbl )

	--atmos_log( "converting settings strings to numbers..." );

	for k,v in pairs( tbl ) do

		if ( type( v ) == "table" ) then

			if ( v.orig and v.orig == "number" ) then

				tbl[k] = tonumber( v.val );

			end

		end

	end

	return tbl;

end

atmos_bezier = {}

function atmos_bezier:curve(xv, yv)
        local reductor = {__index = function(self, ind)
                return setmetatable({tree = self, level = ind}, {__index = function(curves, ind)
                        return function(t)
                                local x1, y1 = curves.tree[curves.level-1][ind](t)
                                local x2, y2 = curves.tree[curves.level-1][ind + 1](t)
                                return x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
                                end
                        end})
                end
        }
        local points = {}
        for i = 1, #xv do
                        points[i] = function(t) return xv[i], yv[i] end
        end
        return setmetatable({points}, reductor)[#points][1]
end
