--[[
    AUTHOR: User:M._I._Wright, with inspiration and some code from Module:ar-verb by User:Benwing
    PUBLIC REPO: https://github.com/supposedly/wiktionary-levantine
--]]

local exports = {}
local default = false

--[[local IPA_MAP = {
    -- ا should be processed specially
    ['َ'] = {[default]={'a'}},
    ['ِ'] = {[default]={'i'}},
    ['ُ'] = {[default]={'u'}},
    ['ّ'] = {[default]={'ː'}},
    ['ئ'] = {[default]={'ʔ'}},
    ['ؤ'] = {[default]={'ʔ'}},
    ['ء'] = {[default]={'ʔ'}},
    ['إ'] = {[default]={'ʔi'}},
    ['آ'] = {[default]={'ʔaː'}},
    ['أ'] = {[default]={'ʔ'}},
    ['ب'] = {[default]={'b'}},
    ['ج'] = {[default]={'ʒ', 'd͡ʒ'}},
    ['د'] = {[default]={'d'}},
    ['ه'] = {[default]={'h'}},
    ['و'] = {[default]={'uː'}, ['#']={'w'}, ['ُ']={'uː'}, ['ِ']={'uː'}, ['َ']={'aw', 'oː'}},
    ['ز'] = {[default]={'z'}},
    ['ح'] = {[default]={'ħ'}},
    ['ط'] = {[default]={'tˤ'}},
    ['ي'] = {[default]={'iː'}, ['#']={'j'}, ['ِ']={'iː'}, ['َ']={'ay', 'e̞ː'}},
    ['ك'] = {[default]={'k'}},
    ['ل'] = {[default]={'l'}},
    ['م'] = {[default]={'m'}},
    ['ن'] = {[default]={'n'}},
    ['س'] = {[default]={'s'}},
    ['ع'] = {[default]={'ʕ'}},
    ['ف'] = {[default]={'f'}},
    ['ص'] = {[default]={'sˤ'}},
    ['ق'] = {[default]={'ʔ', 'q'}},
    ['ر'] = {[default]={'ɾ'}},
    ['ش'] = {[default]={'ʃ'}},
    ['ت'] = {[default]={'t'}},
    ['ث'] = {[default]={'s'}},  -- /θ/ is rare enough not to be worth recording. /t/ should be written ت
    ['خ'] = {[default]={'x'}},
    ['ذ'] = {[default]={'z'}},  -- /ð/ is rare enough not to be worth recording. /d/ should be written د
    ['ض'] = {[default]={'dˤ'}},
    ['ظ'] = {[default]={'zˤ'}},  -- /ðˤ/ is rare enough not to be worth recording
    ['غ'] = {[default]={'ɣ'}},
    ['ة'] = {[default]={'a', 'e̞'}, ['ِ']={'e̞'}, ['َ']={'a'}},  -- probably not worth breaking our whole system to allow pronunciation to be inferred, just make the user specify it
}]]

local IPA_MAP = {
    -- ا should be processed specially
    ['َ'] = {[default]={'a'}},
    ['ِ'] = {[default]={'i'}},
    ['ُ'] = {[default]={'u'}},
    ['ّ'] = {[default]={':'}},
    ['ئ'] = {[default]={'?'}},
    ['ؤ'] = {[default]={'?'}},
    ['ء'] = {[default]={'?'}},
    ['إ'] = {[default]={'?i'}},
    ['آ'] = {[default]={'?a:'}},
    ['أ'] = {[default]={'?'}},
    ['ب'] = {[default]={'b'}},
    ['ج'] = {[default]={'Z', 'dZ'}},
    ['د'] = {[default]={'d'}},
    ['ه'] = {[default]={'h'}},
    ['و'] = {[default]={'u:'}, ['#']={'w'}, ['ُ']={'u:'}, ['ِ']={'u:'}, ['َ']={'aw', 'o:'}},
    ['ز'] = {[default]={'z'}},
    ['ح'] = {[default]={'X\\'}},
    ['ط'] = {[default]={'t_?\\'}},
    ['ي'] = {[default]={'i:'}, ['#']={'j'}, ['ِ']={'i:'}, ['َ']={'ay', 'e_o:'}},
    ['ك'] = {[default]={'k'}},
    ['ل'] = {[default]={'l'}},
    ['م'] = {[default]={'m'}},
    ['ن'] = {[default]={'n'}},
    ['س'] = {[default]={'s'}},
    ['ع'] = {[default]={'?\\'}},
    ['ف'] = {[default]={'f'}},
    ['ص'] = {[default]={'s_?\\'}},
    ['ق'] = {[default]={'?', 'q'}},
    ['ر'] = {[default]={'4'}},
    ['ش'] = {[default]={'S'}},
    ['ت'] = {[default]={'t'}},
    ['ث'] = {[default]={'s'}},  -- /T/ is rare enough not to be worth recording. /t/ should be written ت
    ['خ'] = {[default]={'x'}},
    ['ذ'] = {[default]={'z'}},  -- /D/ is rare enough not to be worth recording. /d/ should be written د
    ['ض'] = {[default]={'d_?\\'}},
    ['ظ'] = {[default]={'z_?\\'}},  -- x/D_?\/ is rare enough not to be worth recording
    ['غ'] = {[default]={'G'}},
    ['ة'] = {[default]={'a', 'e_o'}, ['ِ']={'e_o'}, ['َ']={'a'}},  -- probably not worth breaking our whole system to allow pronunciation to be inferred, just make the user specify it
}


local function set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end


local EMPHATICS = set({'ط', 'ص', 'ق', 'ض', 'ظ'})  -- these cause backing of alif
local LOWERING_CONSONANTS = set({'ق', 'ر', 'ح', 'ع', 'خ', 'غ'})  -- these turn alif into /a/
local IMPOSSIBLE_COMBINATIONS = {'qaː', 'ʔαː'}  -- to be pattern-matched


local function get_frame_args(frame)
    return frame:getParent().args
end


local function copy_list(t)
    local new = {}
    for i, v in ipairs(t) do
        new[i] = v
    end
    return new
end


local function clear_table(t)
    local size = #t
    for i = 0, size do t[i] = nil end
    return
end


local function determine_emphasis_level(c, chars, level)
    if c == 'ي' then
        level = 0
        clear_table(chars)
    else
        if EMPHATICS[c] then
            level = 3
            chars[1+#chars] = 'A'  -- α
        end
        if LOWERING_CONSONANTS[c] then
            level = 2
            chars[1+#chars] = 'a'
        end
    end
    return level
end


local function determine_emphasis_environment(word, alif_index)
    local left_level, right_level, chars = 0, 0, {}, {}
    local i = 1
    for v in string.gmatch(word, "([%z\1-\127\194-\244][\128-\191]*)") do
        i = i + 1
        if i == alif_index then
            break
        end
        left_level = determine_emphasis_level(v, chars, left_level)
    end
    i = #word
    for v in string.gmatch(word, "([%z\1-\127\194-\244][\128-\191]*)") do
        i = i - 1
        if i == alif_index then
            break
        end
        right_level = determine_emphasis_level(v, chars, right_level)
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
    local possibilities, prev_char, prev_output = {}, '#', {}
    local index = 0
    for value in string.gmatch(word, "([%z\1-\127\194-\244][\128-\191]*)") do
        index = index + 1
        if IPA_MAP[value] ~= nil then
            local appendee = prev_output
            if IPA_MAP[value][prev_char] ~= nil then
                appendee = {}
                prev_output = IPA_MAP[value][prev_char]
            else
                prev_output = IPA_MAP[value][default]
            end
            if #appendee > 0 then
                possibilities[1 + #possibilities] = appendee
            end
        elseif value == 'ا' then
            possibilities[1 + #possibilities] = prev_output
            if prev_char == '#' then  -- word boundary aka beginning of word
                if verb_form == nil then
                    -- if it's a noun then word-initial hamza-less alif represents /ʔi/
                    prev_output = {'(?i)'}  -- ʔi
                    -- if it's a verb then the same alif represents a word-initial consonant cluster in Levantine
                    -- meaning nothing is to be prepended
                end
            else
                local left_level, right_level, chars = determine_emphasis_environment(word, index)
                local charset, chars = set(chars), {}
                if right_level == 0 and left_level < 2 then
                    charset['e_o'] = true -- e̞
                    charset['{'] = true  -- æ
                end
                for k, _ in pairs(charset) do
                    chars[1 + #chars] = k .. ':'
                end
                prev_output = chars
            end
        end
        prev_char = value
    end
    if #prev_output > 0 then
        possibilities[1 + #possibilities] = prev_output
    end
    -- now go through all possibilities
    local final = copy_list(possibilities[1])
    for i = 2, #possibilities do
        branch(final, possibilities[i])
    end
    for i, v in ipairs(final) do
        -- TODO: INSERT VARIANT STRESS MARKERS RIGHT HERE
        final[i] = '/' .. v .. '/'
    end
    return final
end


function exports.conjuate(frame)
    local args = get_frame_args(frame)
end


return exports
