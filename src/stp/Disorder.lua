if not TileGrid then TileGrid = require 'stp/TileGrid' end

local moveMap = {'up', 'down', 'left', 'right'}

-- @tileGrid: The TileGrid to disorder.
-- @numberOfSlides: The number of swaps between the blank tile and a random adjacent tile.
-- @noImmediateUndos: During the course or random disordering, sequential steps will never
--                    undo the previous step.
-- @ignoreIllegal: If a potential move is illegal, do not count it is a legitimate move, and
--                 thus do not increment until a valid move is generated.
-- @disorderThreshold: TBI - A measure of the 'disorderer-ness' that must be reached until
--                     disordering halts.
--
local disorder = function (tileGrid, numberOfSlides, noImmediateUndos, ignoreIllegal, disorderThreshold)
    if not numberOfSlides then numberOfSlides = 10000 end
    if not tileGrid then tileGrid = TileGrid.new() end

    local push = function (value, tbl) tbl[#tbl + 1] = value end

    for i = 1, numberOfSlides do
        local currentMove = moveMap[math.random(4)]
        tileGrid:move(currentMove)
    end

    return tileGrid
end

return disorder
