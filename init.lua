local obsi = require "/lib/obsi2"

local symbols = require "symbols"
local load_symbol_images = symbols.load_symbol_images
symbols = symbols.symbols

local reels = require "reels"

local play_sound = require "play_sound"

local reel_pos = reels.random_reels()

local spinning = false
local spin_start_time = 0

local stop_variances = { 0, 0, 0 }

local sounds = {}

function obsi.load()
    load_symbol_images()

    -- load sound effects
    sounds.reel1 = "sounds/reel1.wav"
    sounds.reel2 = "sounds/reel2.wav"
    sounds.reel3 = "sounds/reel3.wav"
    sounds.win = "sounds/win.wav"
    sounds.jackpot = "sounds/jackpot.wav"
end


local function calculate_payout()
    local payout = 0

    local symbol_1 = reels.reel[reel_pos[1]]
    local symbol_2 = reels.reel[reel_pos[2]]
    local symbol_3 = reels.reel[reel_pos[3]]

    if symbol_1 == symbol_2 and symbol_2 == symbol_3 then
        payout = symbols[symbol_1].payout.triple or 0
    elseif symbol_1 == symbol_2 or symbol_2 == symbol_3 or symbol_1 == symbol_3 then
        payout = symbols[symbol_1].payout.double or 0
    end

    return payout
end

local function update_reel(reel_idx, diff)
    if spinning then
        -- each reel stops staggered (1 second per reel and their random variance)
        if diff <= (reel_idx + stop_variances[reel_idx]) then
            -- increment position and wrap around
            reel_pos[reel_idx] = reel_pos[reel_idx] + 1
            if reel_pos[reel_idx] > #reels.reel then
                reel_pos[reel_idx] = 1
            end
        end
    end

    local symbol_name = reels.reel[reel_pos[reel_idx]]
    local symbol = symbols[symbol_name]

    obsi.graphics.draw(symbol.image, ((reel_idx - 1) * symbol.image.width) + 1, 1)
end

local played_sounds = {}
local payout_next_sec = false

function obsi.update()
    -- start the spin if space is pressed
    if not spinning and obsi.keyboard.isScancodeDown(keys.space) then
        -- randomise stop variances for each reel
        for i = 1, 3 do
            stop_variances[i] = math.random(-0.05, 0.3)
        end

        -- start spin
        played_sounds = {}
        spinning = true
        spin_start_time = obsi.timer.getTime()
    end

    local diff = obsi.timer.getTime() - spin_start_time


    -- stop the spin after 3 seconds
    if spinning and diff >= 3 then
        spinning = false

        -- another scuffed way to delay something, no setTimer sighh..
        payout_next_sec = true
    end

    if payout_next_sec and diff >= 4 then
        payout_next_sec = false

        local payout = calculate_payout()
        if payout > 0 then
            if payout == symbols.jackpot.payout.triple then
                play_sound(sounds.jackpot)
            else
                play_sound(sounds.win)
            end
        end
    end

    -- update and draw the reels
    for i = 1, 3 do
        -- if the time for a sound to be played is passed, play the sound and marked it as played
        -- this is a bit scuffedm but its the easiest way to schedule a sound to play at a certain time without repeating it every frame
        if not played_sounds[i] and diff >= (i + stop_variances[i]) then
            play_sound(sounds["reel" .. i])
            played_sounds[i] = true
        end

        update_reel(i, diff)
    end
end

obsi.init()
