local TileGrid = {}
_mt_TileGrid = {__index = TileGrid}

function TileGrid.new(numberOfRows, numberOfClumns)
    local newTileGrid = {rows = {},
                         rowCount = numberOfRows and true or 4,
                         columnCount = numberOfColumns and true or 4}
    local ntg = newTileGrid

    local tileNum = 1
    for r = 1, ntg.rowCount do
        ntg.rows[#ntg.rows + 1] = {}
        for c = 1, ntg.columnCount do
            ntg.rows[r][c] = tileNum
            tileNum = tileNum + 1
        end
    end

    setmetatable(newTileGrid, _mt_TileGrid)
    return newTileGrid
end

function TileGrid:display()
    local displayStr = ''

    displayStr = displayStr .. string.rep(' ----', self.columnCount) .. '\n'

    for _, r in ipairs(self.rows) do
        for _, c in ipairs(r) do
            displayStr = displayStr .. '| ' .. string.format('%2s', c) .. ' '
        end
        displayStr = displayStr .. '|\n' .. string.rep(' ----', self.columnCount) .. '\n'
    end

    print(displayStr)
end

return TileGrid