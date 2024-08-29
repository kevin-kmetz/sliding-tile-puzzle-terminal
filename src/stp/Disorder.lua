if not TileGrid then TileGrid = require 'stp/TileGrid' end

local moveMap = {'up', 'down', 'left', 'right'}
local oppositesMap = {up = 'down', down = 'up', left = 'right', right = 'left'}

local disorder
local calculateNumberOfSlides

-- @tileGrid: The TileGrid to disorder.
-- @numberOfSlides: The number of swaps between the blank tile and a random adjacent tile.
-- @noImmediateUndos: During the course or random disordering, sequential steps will never
--                    undo the previous step.
-- @ignoreIllegal: If a potential move is illegal, do not count it is a legitimate move, and
--                 thus do not increment until a valid move is generated.
-- @disorderThreshold: TBI - A measure of the 'disorderer-ness' that must be reached until
--                     disordering halts.
--
disorder = function (tileGrid, numberOfSlides, noImmediateUndos, ignoreIllegal, disorderThreshold)
    if type(tileGrid) == 'nil' then tileGrid = TileGrid.new() end
    if type(numberOfSlides) == 'nil' then numberOfSlides = calculateNumberOfSlides(tileGrid) end
    if type(noImmediateUndos) == 'nil' then noImmediateUndos = true end
    if type(ignoreIllegal) == 'nil' then ignoreIllegal = true end

    local push = function (value, tbl) tbl[#tbl + 1] = value end

    local currentMove = nil
    local previousMove = nil
    local slidesPerformed = 0
    while slidesPerformed < numberOfSlides do
        repeat
            currentMove = moveMap[math.random(4)]
            local isUndoingMove = currentMove == oppositesMap[previousMove]
        until not isUndoingMove or not noImmediateUndos

        local moveOccurred = tileGrid:move(currentMove)

        if moveOccurred or not ignoreIllegal then
            slidesPerformed = slidesPerformed + 1
        end

        if moveOccurred then previousMove = currentMove end
        currentMove = nil
    end

    return tileGrid
end

-- The logic behind the specific number of slides/swaps calculated here is that
-- (rowCount + columnCount - 2) represents that maximum Manhattan distance between the two
-- furthest tiles on the grid, so if this quantity allows enough swaps to occur
-- that each tile could theoretically get to its furthest possible location. Now,
-- that won't happen unless each tile is 'focused on', and many tiles will have
-- maximum distances that are shorter due to combinatoric reasons beyond scop here,
-- but this goes above the actual need maximum amount by a number that is not excessive.
--
calculateNumberOfSlides = function (tileGrid)
    local tileCount = tileGrid.rowCount * tileGrid.columnCount
    local maxManhattanDistance = tileGrid.rowCount + tileGrid.columnCount - 2
    return tileCount * maxManhattanDistance
end

return disorder
