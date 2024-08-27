local TileGrid
local disorder
local InputGetter

if not TileGrid then TileGrid = require 'stp/TileGrid' end
if not disorder then disorder  = require 'stp/Disorder' end
if not InputGetter then InputGetter = require 'stp/InputGetter' end

local run
local initInputGetters
local getPlayGame
local solicitGame

local playGame
local initGame
local gameLoop
local exitGame

initInputGetters = function ()
    getPlayGame = InputGetter.generateInputGetter("Enter 'play' (p) to play a game, or 'quit' (q) to quit.",
                                                  'Choice: ',
                                                  InputGetter.generateInputValidator('string', {'play', 'p', 'quit', 'q'}),
                                                  'Invalid choice - please try again!')
end

run = function ()
    print('Sliding Tile Puzzle Game v1.0 - Terminal version')
    initInputGetters()
    solicitGame()
    print('Thanks for playing! Now exiting the game...')
end

solicitGame = function ()
    while (true) do
        local playChoice = getPlayGame()
        if playChoice == 'play' or playChoice == 'p' then
            playGame()
        else
            break
        end
    end
end

playGame = function ()
    local game = initGame()
    gameLoop()
    exitGame()
end

initGame = function ()
    print('What are the dimensions of the puzzle you would like to solve?')
end

gameLoop = function ()
end

exitGame = function ()
    print('Concluding a single game...')
end

run()
