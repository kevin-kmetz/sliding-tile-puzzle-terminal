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
local initLegalInputs
local commandInputsMap
local initGame
local gameLoop
local exitGame

local push = function (val, tbl) tbl[#tbl + 1] = val; return #tbl end

local undoLastMove
local quitPuzzle
local displayHelp
local solvePuzzle
local displayMoveCount
local resetPuzzle

local sleep

initLegalInputs = function ()
    local legalInputs = {}
    commandInputsMap  = {['undo'] = undoLastMove,      ['x'] = undoLastMove,
                         ['quit'] = quitPuzzle,        ['q'] = quitPuzzle,
                         ['help'] = displayHelp,       ['h'] = displayHelp,
                         ['moves'] = displayMoveCount, ['m'] = displayMoveCount,
                         ['reset'] = resetPuzzle,      ['z'] = resetPuzzle,
                         ['solve'] = solvePuzzle}

    for k, _ in pairs(TileGrid.movementInputMap) do
        push(k, legalInputs)
    end

    for k, _ in pairs(commandInputsMap) do
        push(k, legalInputs)
    end

    return legalInputs
end

initInputGetters = function (legalInputs)
    local msgInvalidChoice = 'Invalid choice - please try again!'

    getPlayGame = InputGetter.generateInputGetter("\nEnter 'play' (p) to attempt a puzzle, or 'quit' (q) to quit.",
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

    local msgMovement = "\nIn which direction should a tile be slid?\n" ..
                        "\n>> Type a single character from 'wasd' or 'ijkl'" ..
                        "\n>> and then press <enter>. Alternatively, type" ..
                        "\n>> 'help' for additional options.\n"
    getChoiceInput = InputGetter.generateInputGetter(msgMovement, 'Choice: ',
                                                     InputGetter.generateInputValidator('string', legalInputs),
                                                     msgInvalidChoice)

    getQuitConfirmation = InputGetter.generateInputGetter("Are you sure you want to give up on the current puzzle?" ..
                                                          "\nPlease enter 'yes' or 'no' (y/n).",
                                                          'Quiz puzzle?: ',
                                                          InputGetter.generateInputValidator('string', {'yes', 'no', 'y', 'n'}),
                                                          msgInvalidChoice)

end

run = function ()
    print('\nSliding Tile Puzzle Game v1.0 - Terminal version')
    local legalInputs = initLegalInputs()
    initInputGetters(legalInputs)
    solicitGame()
    print('Thanks for playing! Now exiting the game...\n')
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
    local playerMoveCount = 0

    while (not puzzle:isInWinState()) do
        local choiceInput = getChoiceInput()

        if commandInputsMap[choiceInput] then
            local commandResult, extraData = commandInputsMap[choiceInput](puzzle, playerMoveCount)
            if commandResult == '_QUIT' then return
            elseif commandResult == '_UNDO_SUCCESSFUL' then playerMoveCount = extraData end
            puzzle:display()
        else
            local moveWasPossible = puzzle:move(choiceInput)
            if moveWasPossible then playerMoveCount = playerMoveCount + 1 end
            puzzle:display()
            if not moveWasPossible then print ("\nMovement '" .. choiceInput .. "' is not valid. Try another!") end
        end

   end

    print('\nCongratulations - you solved the puzzle! Hooray!')
end

exitGame = function ()
    print('\nCurrent puzzle concluded.\nWould you like to attempt another puzzle?')
end

undoLastMove = function (tileGrid, playerMoveCount)
    if playerMoveCount > 0 then
        tileGrid:undo()
        return '_UNDO_SUCCESSFUL', playerMoveCount - 1
    else
        print('No player moves exist to undo!\n')
    end
end

quitPuzzle = function ()
    local choice = getQuitConfirmation()

    if choice == 'yes' or choice == 'y' then
        print('Now quitting the current puzzle...')
        return '_QUIT'
    end

    print('Quit aborted. Resuming the puzzle...\n')
end

local helpMsg = [[
  Controls: Type a single character from 'wasd' or from
            'ijkl' and then press <enter> to move a tile
            that is adjacent to the 'empty tile'.
            Also, 'up', 'down', 'left', and 'right' may
            be entered to move as well.

  Additional commands:
            'quit'  or 'q' -> Quit the current puzzle.
            'undo'  or 'x' -> Undo the last move made.
            'help'  or 'h' -> Display this help message.
            'moves' or 'm' -> Display the number of moves made.
            'solve'        -> Reveal the solution to the puzzle.
]]

displayHelp = function ()
    print(helpMsg)
end

solvePuzzle = function ()
end

displayMoveCount = function(_, playerMoveCount)
    print('# of moves made by player: ' .. playerMoveCount .. '\n')
end

resetPuzzle = function()
end

sleep = function (desiredSeconds)
    local elapsedCPUSeconds = os.clock()
    while os.clock() - elapsedCPUSeconds < desiredSeconds do
        -- absolutely nothing
    end
end

run()
