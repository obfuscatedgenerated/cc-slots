local symbols = require "symbols"
symbols = symbols.symbols

local SEED = 314

-- define reel strip to use for all 3 reels
local reel = {
    symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name,
    symbols.lemon.name, symbols.lemon.name, symbols.lemon.name, symbols.lemon.name, symbols.lemon.name, symbols.lemon.name,
    symbols.orange.name, symbols.orange.name, symbols.orange.name, symbols.orange.name, symbols.orange.name,
    symbols.plum.name, symbols.plum.name, symbols.plum.name, symbols.plum.name, symbols.plum.name,
    symbols.grape.name, symbols.grape.name, symbols.grape.name, symbols.grape.name,
    symbols.bar_single.name, symbols.bar_single.name, symbols.bar_single.name, symbols.bar_single.name,
    symbols.bar_double.name, symbols.bar_double.name,
    symbols.bar_triple.name,
    symbols.seven.name, symbols.seven.name,
    symbols.bell.name, symbols.bell.name,
    symbols.jackpot.name
}

-- TODO: add mixed bar, mixed fruit, etc payouts. the RTP is very bad right now!

-- since we step through the reel each tick for the randomisation, we want to split apart the fruits being together (but still write the table in a readable way
-- so shuffle it at require time with a fixed seed for consistency between plays
math.randomseed(SEED)
for i = #reel, 2, -1 do
    local j = math.random(i)
    reel[i], reel[j] = reel[j], reel[i]
end

local function random_reels()
    return { math.random(1, #reel), math.random(1, #reel), math.random(1, #reel) }
end

return {
    reel = reel,
    random_reels = random_reels,
}
