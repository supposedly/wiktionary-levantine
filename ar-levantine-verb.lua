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
    ['و'] = {[nil]={'w'}, ['ُ']={'uː'}, ['ِ']={'uː'}, ['َ']={'aw', 'oː'}},
    ['ز'] = {[nil]={'z'}},
    ['ح'] = {[nil]={'ħ'}},
    ['ط'] = {[nil]={'tˤ'}},
    ['ي'] = {[nil]={'y'}, ['ِ']={'iː'}, ['َ']={'ay', 'e̞ː'}},
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
    ['ث'] = {[nil]={'s'}},  -- /θ/ is rare enough not to be worth entertaining. /t/ should be written ت
    ['خ'] = {[nil]={'ð'}},
    ['ذ'] = {[nil]={'z'}},  -- /ð/ is rare enough not to be worth entertaining. /d/ should be written د
    ['ض'] = {[nil]={'dˤ'}},
    ['ظ'] = {[nil]={'zˤ'}},  -- /ðˤ/ is rare enough not to be worth entertaining
    ['غ'] = {[nil]={'ɣ'}},
    ['ة'] = {[nil]={'a', 'e̞'}, ['ِ']={'e̞'}, ['َ']={'a'}},  -- probably not worth breaking this whole system to allow the rest to be inferred
}

-- from SO from Programming in Lua
local function set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

local EMPHATICS = set({'ط', 'ص', 'ق', 'ض', 'ظ'}) -- these cause backing of alif
local LOWERING_CONSONANTS = set({'ر', 'ح', 'ع', 'خ'}) -- these make alif into /a/
local NO_RAISING_CONSONANTS = set({'غ', 'ه'}) -- these prevent alif from raising, leaving it x/æ/


local function get_frame_args(frame)
    return frame:getParent().args
end

local function str_ipairs(s)
    local i, n = 0, #s
    return function()
        i = i + 1
        if i <= n then
            return i, s:sub(i,i)
        end
    end
end

function exports.IPA(frame)
    local args = get_frame_args(frame)
    local word, verb_form = args[1], args[2]
    local possibilities, prev_char = {}, '#'
    for index, value in str_ipairs(word) do
        if IPA_MAP[value] ~= nil then
            if IPA_MAP[value][prev_char] ~= nil then
                possibilities[1+#possibilities] = IPA_MAP[value][prev_char]
            else
                possibilities[1+#possibilities] = IPA_MAP[value][nil]
            end
        elseif value == 'ا' then
            local left_emphasis_level, right_emphasis_level = 0, 0
            for i = 0, index do
                
            end
        end
        prev_char = value
    end
end

function exports.conj(frame)
    local args = get_frame_args(frame)
end

return exports
