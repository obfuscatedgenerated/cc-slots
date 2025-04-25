local symbols = require "symbols"
symbols = symbols.symbols

-- define reel strip to use for all 3 reels
local reel = {
    symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name,
    symbols.lemon.name, symbols.lemon.name, symbols.lemon.name, symbols.lemon.name, symbols.lemon.name,
    symbols.orange.name, symbols.orange.name, symbols.orange.name, symbols.orange.name,
    symbols.plum.name, symbols.plum.name, symbols.plum.name, symbols.plum.name,
    symbols.grape.name, symbols.grape.name, symbols.grape.name,
    symbols.bar_single.name, symbols.bar_single.name, symbols.bar_single.name, symbols.bar_single.name,
    symbols.bar_double.name, symbols.bar_double.name, symbols.bar_double.name,
    symbols.bar_triple.name, symbols.bar_triple.name,
    symbols.seven.name, symbols.seven.name,
    symbols.bell.name, symbols.bell.name,
    symbols.jackpot.name
}

local function random_reels()
    return { math.random(1, #reel), math.random(1, #reel), math.random(1, #reel) }
end

return {
    reel = reel,
    random_reels = random_reels,
}
