--[[
    AUTHOR: User:M._I._Wright, with inspiration and some code from Module:ar-verb by User:Benwing
    PUBLIC REPO: https://github.com/supposedly/wiktionary-levantine
--]]

local infer_radicals = require('Module:ar-verb').infer_radicals
local yesno = require('Module:yesno')

local exports = {}

local IPA_MAP = {
    -- ا should be processed specially
    ['َ'] = {[nil]={'a'}},
    ['ِ'] = {[nil]={'i'}},
    ['ُ'] = {[nil]={'u'}},
    ['ئ'] = {[nil]={'ʔ'}},
    ['ؤ'] = {[nil]={'ʔ'}},
    ['ء'] = {[nil]={'ʔ'}},
    ['إ'] = {[nil]={'ʔi'}},
    ['آ'] = {[nil]={'ʔaː'}},
    ['أ'] = {[nil]={'ʔ'}},
    ['ب'] = {[nil]={'b'}},
    ['ج'] = {[nil]={'ʒ', 'd͡ʒ'}},
    ['د'] = {[nil]={'d'}},
    ['ه'] = {[nil]={'h'}},
    ['و'] = {[nil]={'uː'}, ['#']={'w'}, ['ُ']={'uː'}, ['ِ']={'uː'}, ['َ']={'aw', 'oː'}},
    ['ز'] = {[nil]={'z'}},
    ['ح'] = {[nil]={'ħ'}},
    ['ط'] = {[nil]={'tˤ'}},
    ['ي'] = {[nil]={'iː'}, ['#']={'y'}, ['ِ']={'iː'}, ['َ']={'ay', 'e̞ː'}},
    ['ك'] = {[nil]={'k'}},
    ['ل'] = {[nil]={'l'}},
    ['م'] = {[nil]={'m'}},
    ['ن'] = {[nil]={'n'}},
    ['س'] = {[nil]={'s'}},
    ['ع'] = {[nil]={'ʕ'}},
    ['ف'] = {[nil]={'f'}},
    ['ص'] = {[nil]={'sˤ'}},
    ['ق'] = {[nil]={'ʔ', 'q'}},
    ['ر'] = {[nil]={'ɾ'}},
    ['ش'] = {[nil]={'ʃ'}},
    ['ت'] = {[nil]={'t'}},
    ['ث'] = {[nil]={'s'}},  -- /θ/ is rare enough not to be worth recording. /t/ should be written ت
    ['خ'] = {[nil]={'ð'}},
    ['ذ'] = {[nil]={'z'}},  -- /ð/ is rare enough not to be worth recording. /d/ should be written د
    ['ض'] = {[nil]={'dˤ'}},
    ['ظ'] = {[nil]={'zˤ'}},  -- /ðˤ/ is rare enough not to be worth recording
    ['غ'] = {[nil]={'ɣ'}},
    ['ة'] = {[nil]={'a', 'e̞'}, ['ِ']={'e̞'}, ['َ']={'a'}},  -- probably not worth breaking our whole system to allow pronunciation to be inferred, just make the user specify it
}


local function set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end


local EMPHATICS = set({'ط', 'ص', 'ق', 'ض', 'ظ'})  -- these cause backing of alif
local LOWERING_CONSONANTS = set({'ق', 'ر', 'ح', 'ع', 'خ', 'غ'})  -- these turn alif into /a/
local RAISING_BLOCKING_CONSONANTS = set({'غ', 'ه', 'ق'})  -- these prevent alif from raising, leaving it /æ/
local IMPOSSIBLE_COMBINATIONS = {'qaː', 'ʔαː'}  -- to be pattern-matched


local function get_frame_args(frame)
    return frame:getParent().args
end


local function str_ipairs(s)
    local i, n = 0, #s
    return function()
        i = i + 1
        if i <= n then
            return i, s:sub(i, i)
        end
    end
end


local function clear_table(t)
    local size = #t
    for i = 0, size do t[i] = nil end
    return
end


local function determine_emphasis_level(c, chars)
    local level = 0
    if c == 'ي' then
        level = 0
        clear_table(chars)
    else
        if EMPHATICS[c] then
            level = 3
            chars[1+#chars] = 'α'
        end
        if LOWERING_CONSONANTS[c] then
            level = 2
            chars[1+#chars] = 'a'
        end
        if RAISING_BLOCKING_CONSONANTS[c] then
            level = 1
        end
    end
    return level
end


local function determine_emphasis_environment(word, alif_index)
    local left_level, right_level, chars = 0, 0, {}, {}
    for i = 1, alif_index - 1 do
        left_level = determine_emphasis_level(word:sub(i, i), chars)
    end
    for i = #word, alif_index + 1, -1 do
        right_level = determine_emphasis_level(word:sub(i, i), chars)
    end
    return left_level, right_level, chars
end


local function branch(t, branches)
    local size, n_branches, first_branch = #t, #branches, branches[1]
    if n_branches == 0 then
        return
    end
    for i = 1, size do
        for j = 2, n_branches do
            t[1+#t] = t[i] .. branches[j]
        end
        t[i] = t[i] .. first_branch
    end
end


function exports.IPA(frame)
    local args = get_frame_args(frame)
    local word, verb_form = args[1], args[2]  -- verb form also tells us whether it's a verb or not
    local possibilities, prev_char = {}, '#'
    for index, value in str_ipairs(word) do
        if IPA_MAP[value] ~= nil then
            if IPA_MAP[value][prev_char] ~= nil then
                possibilities[1+#possibilities] = IPA_MAP[value][prev_char]
            else
                possibilities[1+#possibilities] = IPA_MAP[value][nil]
            end
        elseif value == 'ا' then
            if prev_char == '#' then  -- word boundary aka beginning of word
                if verb_form == nil then
                    -- if it's a noun then word-initial hamza-less alif represents /ʔi/
                    possibilities[1+#possibilities] = {'ʔi'}
                    -- if it's a verb then the same alif represents a word-initial consonant cluster in Levantine
                    -- meaning nothing is to be prepended
                end
            else
                local left_level, right_level, chars = determine_emphasis_environment(word, index)
                chars = set(chars)
                if right_level == 0 and left_level < 2 then
                    chars['e̞'] = not RAISING_BLOCKING_CONSONANTS[prev_char]
                    chars['æ'] = true
                end
                for k, v in pairs(chars) do
                    chars[k] = v .. 'ː'
                end
                possibilities[1+#possibilities] = chars
            end
        end
        prev_char = value
    end
    -- now go through all possibilities
    local final = {possibilities[1]}
    for i = 2, #possibilities do
        branch(final, possibilities[i])
    end
    for i, v in ipairs(final) do
        -- TODO: INSERT VARIANT STRESS MARKERS RIGHT HERE
        final[i] = '/' .. v .. '/'
    end
end


function exports.conjuate(frame)
    local args = get_frame_args(frame)
end


return exports
