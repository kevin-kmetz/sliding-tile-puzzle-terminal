local TileGrid = {display = function () return nil end}
TileGrid._mt_TileGrid = {__index = TileGrid}

-- displayStyle ::= '_ASCII' | '_BOXCHAR'
function TileGrid.new(numberOfRows, numberOfColumns, displayStyle, toroidalGeometry)
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
function TileGrid:move(movement)
end

function TileGrid:moveUp()
    local x, y = self._blankTileX, self._blankTileY

    if y ~= 1 then
        self:swap(x, y, x, y - 1)
        y = y - 1
        
        self._blankTileY = y
    end
end

return TileGrid