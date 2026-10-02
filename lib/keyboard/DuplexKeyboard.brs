function DuplexKeyboardLayout(mode as String) as Object
    if mode = "symbol"
        return [
            ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
            ["@", "#", "$", "%", "&", "*", "-", "+", "(", ")"]
            ["=", "/", "\", ":", ";", ",", ".", "?", "BK"]
            ["ABC", "LA", "RA", "SP", ".", "_", "OK"]
        ]
    end if
    return [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        ["SH", "z", "x", "c", "v", "b", "n", "m", "BK"]
        ["123", "LA", "RA", "SP", "-", "_", "OK"]
    ]
end function

function DuplexKeyboardMoveCursor(layout as Object, row as Integer, col as Integer, dir as String) as Object
    rowCount = layout.Count()
    rowLen = layout[row].Count()
    if dir = "left"
        return { row: row, col: (col - 1 + rowLen) mod rowLen }
    else if dir = "right"
        return { row: row, col: (col + 1) mod rowLen }
    else if dir = "up"
        nextRow = (row - 1 + rowCount) mod rowCount
        nextCol = col
        if nextCol >= layout[nextRow].Count()
            nextCol = layout[nextRow].Count() - 1
        end if
        return { row: nextRow, col: nextCol }
    end if
    nextRow = (row + 1) mod rowCount
    nextCol = col
    if nextCol >= layout[nextRow].Count()
        nextCol = layout[nextRow].Count() - 1
    end if
    return { row: nextRow, col: nextCol }
end function

function DuplexKeyboardApplyToken(value as String, token as String, shift as Boolean, mode as String) as Object
    if token = "SH"
        return { value: value, shift: not shift, mode: mode, done: false }
    else if token = "123"
        return { value: value, shift: false, mode: "symbol", done: false }
    else if token = "ABC"
        return { value: value, shift: false, mode: "alpha", done: false }
    else if token = "BK"
        if len(value) > 0
            return { value: left(value, len(value) - 1), shift: shift, mode: mode, done: false }
        end if
        return { value: value, shift: shift, mode: mode, done: false }
    else if token = "LA" or token = "RA"
        return { value: value, shift: shift, mode: mode, done: false }
    else if token = "OK"
        return { value: value, shift: shift, mode: mode, done: true }
    else if token = "SP"
        return { value: value + " ", shift: false, mode: mode, done: false }
    end if

    ch = token
    if len(token) = 1 and mode = "alpha" and shift
        ch = uCase(token)
    end if
    return { value: value + ch, shift: false, mode: mode, done: false }
end function

function DuplexKeyboardDisplayToken(token as String, shift as Boolean, mode as String) as String
    if token = "SH" then return "Shift"
    if token = "BK" then return "Del"
    if token = "SP" then return "Space"
    if token = "OK" then return "Done"
    if token = "123" then return "?123"
    if token = "ABC" then return "ABC"
    if token = "LA" then return "<"
    if token = "RA" then return ">"
    if len(token) = 1 and mode = "alpha" and shift
        return uCase(token)
    end if
    return token
end function
