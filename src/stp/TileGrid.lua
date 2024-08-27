local TileGrid = {display = function () return nil end,
                  movementMap = {}}
TileGrid._mt_TileGrid = {__index = TileGrid}

local push = function (value, tbl) tbl[#tbl + 1] = value; return #tbl end
local pop = function (tbl)
    if #tbl > 0 then
        local value = tbl[#tbl]
        tbl[#tbl] = nil
        return value
    end
end

-- Wrapping the value of these constants in tables allows the references
-- to be used for comparison instead of the value, which will lead to
-- constant duplication when checking equality (for example, the four '_UP's
-- in the inputMap below would all duplicate the 'up' string if not wrapped.
-- Instead, they all point to the single table. Maybe its not important here
-- because there aren't that many uses of them, but a string itself is no better..
--
_UP, _DOWN, _LEFT, _RIGHT = {move = 'up'}, {move = 'down'}, {move = 'left'}, {move = 'right'}

-- WASD, IJKL, and 'up', 'down', 'left', and 'right' are supported as input strings.
-- This unfortunately leads to conflicts in the use of the 'd' and 'l' chars, which
-- I have defaulted to giving WASD and IJKL precedence over the initialism.
--
TileGrid.movementInputMap = {up = _UP, u = _UP, U = _UP, w = _UP, i = _UP, [_UP] = _UP,
                             down = _DOWN, D = _DOWN, s = _DOWN, k = _DOWN, [_DOWN] = _DOWN,
                             left = _LEFT, L = _LEFT, a = _LEFT, j = _LEFT, [_LEFT] = _LEFT,
                             right = _RIGHT, r = _RIGHT, R = _RIGHT, d = _RIGHT, l = _RIGHT, [_RIGHT] = _RIGHT}

TileGrid.movementLambdasMap = {[_UP]    = {onBoundingEdge = function (tileGrid) return tileGrid._blankTileY == 1 end,
                                           swapNormally =   function (tileGrid) tileGrid:swap(tileGrid._blankTileX, tileGrid._blankTileY - 1) end,
                                           swapToroidally = function (tileGrid) tileGrid:swap(tileGrid._blankTileX, tileGrid.rowCount) end},
                               [_DOWN]  = {onBoundingEdge = function (tileGrid) return tileGrid._blankTileY == tileGrid.rowCount end,
                                           swapNormally =   function (tileGrid) tileGrid:swap(tileGrid._blankTileX, tileGrid._blankTileY + 1) end,
                                           swapToroidally = function (tileGrid) tileGrid:swap(tileGrid._blankTileX, 1) end},
                               [_LEFT]  = {onBoundingEdge = function (tileGrid) return tileGrid._blankTileX == 1 end,
                                           swapNormally =   function (tileGrid) tileGrid:swap(tileGrid._blankTileX - 1, tileGrid._blankTileY) end,
                                           swapToroidally = function (tileGrid) tileGrid:swap(tileGrid.columnCount, tileGrid._blankTileY) end},
                               [_RIGHT] = {onBoundingEdge = function (tileGrid) return tileGrid._blankTileX == tileGrid.columnCount end,
                                           swapNormally =   function (tileGrid) tileGrid:swap(tileGrid._blankTileX + 1, tileGrid._blankTileY) end,
                                           swapToroidally = function (tileGrid) tileGrid:swap(1, tileGrid._blankTileY) end}}

TileGrid.reverseMovementMap = {[_UP] = _DOWN, [_DOWN] = _UP, [_LEFT] = _RIGHT, [_RIGHT] = _LEFT}

-- displayStyle ::= '_ASCII' | '_BOXCHAR'
function TileGrid.new(numberOfRows, numberOfColumns, toroidalGeometry, displayStyle)
    local newTileGrid = {rows =               {},
                         rowCount =           numberOfRows and numberOfRows or 4,
                         columnCount =        numberOfColumns and numberOfColumns or 4,
                         display =            TileGrid.display,
                         _displayStyle =      displayStyle == '_ASCII' and '_ASCII' or '_BOXCHAR',
                         _middleColumnCount = -1,
                         _asHeader =          '_UNINITIALIZED',
                         _asRowSeperator =    '_UNINITIALIZED',
                         _asFooter =          '_UNINITIALIZED',
                         _bcHeader =          '_UNINITIALIZED',
                         _bcRowSeparator =    '_UNINITIALIZED',
                         _bcFooter =          '_UNINITIALIZED',
                         _formatter =         '_UNINITIALIZED',
                         _blankTileX =        -1,
                         _blankTileY =        -1,
                         _toroidalGeometry =  toroidalGeometry or false,
                         _moveHistory =       {}}

    assert(newTileGrid.rowCount > 1 and newTileGrid.columnCount > 1, 'Error - invalid TileGrid instantiation arguments!')

    setmetatable(newTileGrid, TileGrid._mt_TileGrid)

    newTileGrid:_initDisplayStyles()
    newTileGrid:_initTileValues()

    return newTileGrid
end

-- Both the ASCII and BoxChar styles are initialized here, since regardless of
-- which was passed into the constructor as the chosen style, both should be
-- available to the player at all times.
function TileGrid:_initDisplayStyles()
    self.display = self._displayStyle == '_ASCII' and self.displayASCII or (self._displayStyle == '_BOXCHAR' and self.displayBoxChar)

    self._middleColumnCount = self.columnCount > 2 and self.columnCount - 2 or 0
    -- Subtract one because the final tile number isn't displayed, insteading being blank.
    local maxDigits = #(tostring(self:cellCount() - 1))
    self._formatter = '%' .. tostring(maxDigits) .. 's'

    self._asHeader =       '\n' .. (' ' .. ('-'):rep(maxDigits + 2)):rep(self.columnCount)
    self._asRowSeparator = '\n' .. (' ' .. ('-'):rep(maxDigits + 2)):rep(self.columnCount)
    self._asFooter =       '\n' .. (' ' .. ('-'):rep(maxDigits + 2)):rep(self.columnCount) .. '\n'

    local blocks = ('═'):rep(maxDigits + 2)
    self._bcHeader =       '\n╔' .. blocks .. ('╦' .. blocks):rep(self._middleColumnCount) .. '╦' .. blocks .. '╗'
    self._bcRowSeparator = '\n╠' .. blocks .. ('╬' .. blocks):rep(self._middleColumnCount) .. '╬' .. blocks .. '╣'
    self._bcFooter =       '\n╚' .. blocks .. ('╩' .. blocks):rep(self._middleColumnCount) .. '╩' .. blocks .. '╝' .. '\n'

end

function TileGrid:_initTileValues()
    local tileNum = 1
    for r = 1, self.rowCount do
        self.rows[#self.rows + 1] = {}
        for c = 1, self.columnCount do
            self.rows[r][c] = tileNum
            tileNum = tileNum + 1
        end
    end

    self._blankTileX = self.columnCount
    self._blankTileY = self.rowCount

    -- This really isn't ideal, given that all other cells are numbers.
    -- However, it shouldn't foul anything up, as all those numbers are
    -- being 'tostring-ed' at time of display. The 'win-condition'
    -- validation methods can also make use of the 'type' function to
    -- check to see if a win-state is valid, so it really doesn't
    -- complicate things.
    --
    -- The other ways to do this would be to check every cell at time
    -- of display to 'blank-out' the cell, which is costly and slow.
    -- I could also make all cells strings, but then that makes checking
    -- the sequential win-state annoying. I could also keep a second
    -- grid for the printable forms, but yuck - two grids? No thanks.
    --
    self.rows[self._blankTileY][self._blankTileX] = ''
end

function TileGrid:cellCount()
    return self.rowCount * self.columnCount
end

function TileGrid:displayASCII()
    local displayStr = ''

    for _, r in ipairs(self.rows) do
        displayStr = displayStr .. self._asRowSeparator .. '\n'
        for _, c in ipairs(r) do
            displayStr = displayStr .. '| ' .. string.format(self._formatter, c) .. ' '
        end
        displayStr = displayStr .. '|'
    end

    displayStr = displayStr .. self._asFooter

    print(displayStr)
end

function TileGrid:displayBoxChar()
    local displayStr = ''

    displayStr = displayStr .. self._bcHeader

    for i, r in ipairs(self.rows) do
        displayStr = displayStr .. '\n'
        for _, c in ipairs(r) do
            displayStr = displayStr .. '║ ' .. string.format(self._formatter, c) .. ' '
        end
        displayStr = displayStr .. '║'
        if i ~= self.rowCount then displayStr = displayStr .. self._bcRowSeparator end
    end

    displayStr = displayStr .. self._bcFooter

    print(displayStr)
end

-- Consider top-left as the origin, as is the norm in computer graphics.
function TileGrid:swap(otherX, otherY)
    local tempValue = self.rows[otherY][otherX]

    self.rows[otherY][otherX] = self.rows[self._blankTileY][self._blankTileX]
    self.rows[self._blankTileY][self._blankTileX] = tempValue

    self._blankTileX = otherX
    self._blankTileY = otherY
end

-- movementStr ::= 'up' | 'down' | 'left' | 'right'
-- This only refers to the movement of the 'blank' tile (highest numbered).
function TileGrid:move(inputString, dontRecordMove)
    local movement = self.movementInputMap[inputString]
    if not movement then
        print('Error - invalid movement input!')
        return false
    end

    local functionMap = self.movementLambdasMap[movement]

    if not functionMap.onBoundingEdge(self) then
        functionMap.swapNormally(self)
    elseif self._toroidalGeometry then
        functionMap.swapToroidally(self)
    end

    if not dontRecordMove then push(movement, self._moveHistory) end
    return true
end

function TileGrid:undo()
    if #self._moveHistory > 0 then return self:move(self.reverseMovementMap[pop(self._moveHistory)].move, true) end
    return false
end

return TileGrid
