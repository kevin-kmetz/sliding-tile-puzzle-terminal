local InputGetter = {}

local isIn = function (element, list)
    for _, e in pairs(list) do
        if element == e then return true end
    end

    return false
end

InputGetter.generateInputGetter = function (solicitMessage, inputPrompt,
                                validationLambda, validationErrorMessage)

    return function ()
        local input
        local inputIsValid = false

        repeat
            if solicitMessage then
                print(solicitMessage)
            end
            io.write(inputPrompt)

            input = io.read()
            print()

            inputIsValid, input = validationLambda(input)
            if not inputIsValid then print(validationErrorMessage) end
        until inputIsValid

        return input
    end

end

InputGetter.generateInputValidator = function (requiredType, validList, extraCriteriaLambda)
    return function (input)
        local inputIsValid = true
        if requiredType and (requiredType == 'number' or requiredType == 'integer' or requiredType == 'float') then input = tonumber(input) end
        if input == nil then inputIsValid, input = false, nil end

        if input and type(input) ~= requiredType then inputIsValid, input = false, nil end
        if validList and not isIn(input, validList) then inputIsValid, input = false, nil end
        if extraCriteriaLambda and not extraCriteriaLambda(input) then inputIsValid, input = false, nil end

        return inputIsValid, input
    end
end

return InputGetter
