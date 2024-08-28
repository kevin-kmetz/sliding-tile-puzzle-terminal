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

local push = function (val, tbl) tbl[#tbl + 1] = val; return #tbl end

local legalMovementInputs = (function ()
    local legalInputs = {}
    for k, _ in pairs(TileGrid.movementInputMap) do push(k, legalInputs) end
    return legalInputs
end)()

initInputGetters = function ()
    local msgInvalidChoice = 'Invalid choice - please try again!'

    getPlayGame = InputGetter.generateInputGetter("\nEnter 'play' (p) to play a game, or 'quit' (q) to quit.",
                                                  'Choice: ',
                                                  InputGetter.generateInputValidator('string', {'play', 'p', 'quit', 'q'}),
                                                  msgInvalidChoice)

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
                                                        msgInvalidChoice)

    local msgMovement = "\nIn which direction should a tile be slid?"
    msgMovement = msgMovement .. "\nType a single character from 'WASD' or 'IJKL' corresponding to a direction,"
    msgMovement = msgMovement .. "\nand then press enter."
    getMovementInput = InputGetter.generateInputGetter(msgMovement, 'Movement direction: ',
                                                       InputGetter.generateInputValidator('string', legalMovementInputs),
                                                       msgInvalidChoice)

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
    local puzzle = initGame()
    gameLoop(puzzle)
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

    return TileGrid.new(height, width, isToroidal)
end

-- f: (TileGrid) -> ()
gameLoop = function (puzzle)
    disorder(puzzle)
    puzzle:display()

    while (not puzzle:isInWinState()) do
        local moveInput = getMovementInput()
        local moveWasPossible = puzzle:move(moveInput)
        puzzle:display()
        if not moveWasPossible then print ("Movement '" .. moveInput .. "' is not valid. Try another!") end
    end

    print('Congratulations - you solved the puzzle! Hooray!')
end

exitGame = function ()
    print('Concluding a single game...')
end

run()
