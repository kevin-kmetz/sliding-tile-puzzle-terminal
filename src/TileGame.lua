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

    getPuzzleWidth = InputGetter.generateInputGetter('Enter the desired width of the puzzle, in number of tiles.',
                                                      'Width: ',
                                                      InputGetter.generateInputValidator('number', nil,
                                                          function (num) return math.type(num) == 'integer' and num > 1 end),
                                                      'Invalid width - please try again!')

    getPuzzleHeight = InputGetter.generateInputGetter('Enter the desired height of the puzzle, in number of tiles.',
                                                      'Height: ',
                                                      InputGetter.generateInputValidator('number', nil,
                                                          function (num) return math.type(num) == 'integer' and num > 1 end),
                                                      'Invalid height - please try again!')

    getToroidalStatus = InputGetter.generateInputGetter("Should the puzzle be toroidal? Please enter 'yes' or 'no' (y/n).",
                                                        'Toroidal puzzle: ',
                                                        InputGetter.generateInputValidator('string', {'yes', 'no', 'y', 'n'}),
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
    local width = getPuzzleWidth()
    local height = getPuzzleHeight()
    local isToroidal = getToroidalStatus()

    if isToroidal == 'yes' or isToroidal == 'y' then
        isToroidal = true
    else
        isToroidal = false
    end

    return TileGrid.new(width, height, isToroidal)
end

gameLoop = function ()
end

exitGame = function ()
    print('Concluding a single game...')
end

run()
