local TileGrid = {display = function () return nil end,
                  movementMap = {}}
TileGrid._mt_TileGrid = {__index = TileGrid}

-- Wrapping the value of these constants in tables allows the references
-- to be used for comparison instead of the value, which will lead to
-- constant duplication when checking equality (this made more sense earlier
-- in my implementation, when the constants pointed to strings and not functions).
--
-- Also, it allows me to implement the functions/methods they will refer to
-- further down, rather than having to implement them BEFORE the constants themselves.
--
_UP, _DOWN, _LEFT, _RIGHT = {move = {}}, {move = {}}, {move = {}}, {move = {}}

-- WASD, IJKL, and 'up', 'down', 'left', and 'right' are supported as input strings.
-- This unfortunately leads to conflicts in the use of the 'd' and 'l' chars, which
-- I have defaulted to giving WASD and IJKL precedence over the initialism.
--
TileGrid.movementMap = {up = _UP, u = _UP, U = _UP, w = _UP, i = _UP,
                        down = _DOWN, D = _DOWN, s = _DOWN, k = _DOWN,
                        left = _LEFT, L = _LEFT, a = _LEFT, j = _LEFT,
                        right = _RIGHT, r = _RIGHT, R = _RIGHT, d = _RIGHT, l = _RIGHT}

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
                         _toroidalGeometry =  toroidalGeometry and true or false}

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
-- a_col -> a_x, a_row -> a_y, b_col -> b_x, b_row -> b_y.
function TileGrid:swap(a_col, a_row, b_col, b_row)
    local cells = self.rows
    local tmp_val = cells[b_row][b_col]

    cells[b_row][b_col] = cells[a_row][a_col]
    cells[a_row][a_col] = tmp_val
end

-- movement ::= 'up' | 'down' | 'left' | 'right'
-- This only refers to the movement of the 'blank' tile (highest numbered).
function TileGrid:move(movementStr)
    local movement = self.movementMap[movementStr]
    if movement then movement.move(self) end
end

function TileGrid:moveUp()
    local x, y = self._blankTileX, self._blankTileY
    local onTopEdge = y == 1 and true or false

    if not onTopEdge then
        self:swap(x, y, x, y - 1)
        y = y - 1

        self._blankTileY = y
    elseif self._toroidalGeometry then
        self:swap(x, y, x, self.rowCount)
        y = self.rowCount
        self._blankTileY = y
    end
end
_UP.move = TileGrid.moveUp

function TileGrid:moveDown()
    local x, y = self._blankTileX, self._blankTileY
    local onBottomEdge = y == self.rowCount and true or false

    if not onBottomEdge then
        self:swap(x, y, x, y + 1)
        y = y + 1

        self._blankTileY = y
    elseif self._toroidalGeometry then
        self:swap(x, y, x, 1)
        y = 1
        self._blankTileY = 1
    end
end
_DOWN.move = TileGrid.moveDown

function TileGrid:moveLeft()
    local x, y = self._blankTileX, self._blankTileY
    local onLeftEdge = x == 1 and true or false

    if not onLeftEdge then
        self:swap(x, y, x - 1, y)
        x = x - 1

        self._blankTileX = x
    elseif self._toroidalGeometry then
        self:swap(x, y, self.columnCount, y)
        x = self.columnCount
        self._blankTileX = x
    end
end
_LEFT.move = TileGrid.moveLeft

function TileGrid:moveRight()
    local x, y = self._blankTileX, self._blankTileY
    local onRightEdge = x == self.columnCount and true or false

    if not onRightEdge then
        self:swap(x, y, x + 1, y)
        x = x + 1

        self._blankTileX = x
    elseif self._toroidalGeometry then
        self:swap(x, y, 1, y)
        x = 1
        self._blankTileX = x
    end
end
_RIGHT.move = TileGrid.moveRight

return TileGrid