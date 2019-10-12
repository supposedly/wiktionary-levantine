--[[
    AUTHOR: User:M._I._Wright, with inspiration and some code from Module:ar-verb by User:Benwing
    PUBLIC REPO: https://github.com/supposedly/wiktionary-levantine
--]]

local exports = {}
local default = false
local ipa

do 
    local IPA_SYMBOLS = {
        gem = 'ː',
        tie='͡',
        ph='ˤ',
        _o='̞',
        alpha='α',
        e_o='e̞',
        ae='æ',
        hamza='ʔ',
        ayn='ʕ',
        heth='ħ',
        j='ʒ',
        r='ɾ',
        sh='ʃ',
        gh='ɣ',
    }

    local X_SAMPA_SYMBOLS = {
        gem = ':',
        tie='',
        ph='_?\\',
        _o = '_o',
        alpha='A',
        e_o='e_o',
        ae='{',
        hamza='?',
        ayn='?\\',
        heth='X\\',
        j='Z',
        r='4',
        sh='S',
        gh='G',
    }

    ipa = X_SAMPA_SYMBOLS  -- change as needed
end

local IPA_MAP = {
    -- ا should be processed specially
    ['َ'] = {[default]={'a'}, ['ِ']={'i', 'a'}, ['ُ']={'u', 'a'}},
    ['ِ'] = {[default]={'i'}, ['ُ']={'u', 'i'}, ['َ']={'a', 'i'}},
    ['ُ'] = {[default]={'u'}, ['ِ']={'i', 'u'}, ['َ']={'a', 'u'}},
    ['ّ'] = {[default]={ipa.gem}},
    ['ئ'] = {[default]={ipa.hamza}},
    ['ؤ'] = {[default]={ipa.hamza}},
    ['ء'] = {[default]={ipa.hamza}},
    ['إ'] = {[default]={ipa.hamza .. 'i'}},
    ['آ'] = {[default]={ipa.hamza .. ipa.ae .. ipa.gem}},
    ['أ'] = {[default]={ipa.hamza}},
    ['ب'] = {[default]={'b'}},
    ['ج'] = {[default]={ipa.j, 'd' .. ipa.tie .. ipa.j}},
    ['د'] = {[default]={'d'}},
    ['ه'] = {[default]={'h'}},
    ['و'] = {[default]={'w'}, ['#']={'w'}, ['ُ']={'u' .. ipa.gem}, ['ِ']={'u' .. ipa.gem}, ['َ']={'aw', 'o' .. ipa.gem}},
    ['ز'] = {[default]={'z'}},
    ['ح'] = {[default]={ipa.heth}},
    ['ط'] = {[default]={'t' .. ipa.ph}},
    ['ي'] = {[default]={'j'}, ['#']={'j'}, ['ِ']={'i' .. ipa.gem}, ['َ']={'aj', ipa.e_o .. ipa.gem}},
    ['ك'] = {[default]={'k'}},
    ['ل'] = {[default]={'l'}},
    ['م'] = {[default]={'m'}},
    ['ن'] = {[default]={'n'}},
    ['س'] = {[default]={'s'}},
    ['ع'] = {[default]={ipa.ayn}},
    ['ف'] = {[default]={'f'}},
    ['ص'] = {[default]={'s' .. ipa.gem}},
    ['ق'] = {[default]={ipa.hamza, 'q'}},
    ['ر'] = {[default]={ipa.r}},
    ['ش'] = {[default]={ipa.sh}},
    ['ت'] = {[default]={'t'}},
    ['ث'] = {[default]={'s'}},  -- /θ/ is rare/marked enough not to be worth recording. /t/ should be written ت
    ['خ'] = {[default]={'x'}},
    ['ذ'] = {[default]={'z'}},  -- /ð/ is rare/marked enough not to be worth recording. /d/ should be written د
    ['ض'] = {[default]={'d' .. ipa.ph}},
    ['ظ'] = {[default]={'z' .. ipa.ph}},  -- /ðˤ/ is rare/marked enough not to be worth recording
    ['غ'] = {[default]={ipa.gh}},
    ['ة'] = {[default]={'a', ipa.e_o}, ['ِ']={ipa.e_o}, ['َ']={'a'}},  -- probably not worth breaking our whole system to allow pronunciation to be inferred, just make the user specify it
}


local function set(list)
    local s = {}
    for _, l in ipairs(list) do s[l] = true end
    return s
end


local EMPHATICS = set({'ط', 'ص', 'ق', 'ض', 'ظ'})  -- these cause backing of alif
local LOWERING_CONSONANTS = set({'ق', 'ر', 'ح', 'ع', 'خ', 'غ'})  -- these turn alif into /a/
local IMPOSSIBLE_COMBINATIONS
do
    local vowel_string = '[a' .. ipa.ae .. ipa.alpha .. 'eiou]' .. ipa.gem .. '?'
    IMPOSSIBLE_COMBINATIONS = {
        -- to be pattern-matched
        'qa' .. ipa.gem,
        ipa.gem .. ipa.gem,
        vowel_string .. vowel_string
    }
end

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
            chars[1+#chars] = ipa.alpha
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
    -- join each branch to each current element
    for i = 1, size do
        for j = 2, n_branches do
            t[1+#t] = t[i] .. branches[j]
        end
        t[i] = t[i] .. first_branch
    end
    -- prune results with impossible combinations
    for i = #t, 1, -1 do
        local v = t[i]
        for _, pattern in ipairs(IMPOSSIBLE_COMBINATIONS) do
            if v:match(pattern) then
                table.remove(t, i)
            end
        end
    end
end


local function split_unicode(word)
    local t = {}
    for v in word:gmatch("([%z\1-\127\194-\244][\128-\191]*)") do
        t[1 + #t] = v
    end
    return t, #t
end


function exports.IPA(frame)
    local args = get_frame_args(frame)
    local word, verb_form = args[1], args[2]  -- verb form also tells us whether it's a verb or not
    local possibilities, prev_char, prev_output = {}, '#', {}
    local split, end_index = split_unicode(word)
    for index, value in ipairs(split) do
        if IPA_MAP[value] ~= nil then
            local appendee = prev_output
            if IPA_MAP[value][prev_char] ~= nil then
                appendee = {}
                prev_output = IPA_MAP[value][prev_char]
            else
                prev_output = IPA_MAP[value][default]
            end
            possibilities[1 + #possibilities] = appendee
        elseif value == 'ا' then
            possibilities[1 + #possibilities] = prev_output
            if prev_char == '#' then  -- word boundary aka beginning of word
                if verb_form == nil then
                    -- if it's a noun then word-initial hamza-less alif represents /ʔi/
                    prev_output = {'(' .. ipa.hamza .. 'i)'}
                    -- if it's a verb then the same alif represents a word-initial consonant cluster in Levantine
                    -- meaning nothing is to be prepended
                end
            else
                local left_level, right_level, chars = determine_emphasis_environment(word, index)
                local charset = set(chars)
                chars = {}
                if right_level == 0 and left_level < 2 then
                    charset[ipa.e_o] = true
                    charset[ipa.ae] = true
                end
                local gem_or_no_gem = ipa.gem
                if index == end_index then
                    charset[ipa.e_o] = nil
                    gem_or_no_gem = ''
                end
                for k, _ in pairs(charset) do
                    chars[1 + #chars] = k .. gem_or_no_gem
                end
                prev_output = chars
            end
        end
        prev_char = value
    end
    possibilities[1 + #possibilities] = prev_output
    -- now go through all possibilities
    local final = {}
    while #final == 0 do
        -- make sure first element isn't empty to have something to branch out of
        -- if it is then keep going till we find one that's not
        final = copy_list(table.remove(possibilities, 1))
    end
    for _, t in ipairs(possibilities) do
        branch(final, t)
    end
    for i, v in ipairs(final) do
        -- TODO: INSERT VARIANT STRESS MARKERS RIGHT HERE
        final[i] = '/' .. v .. '/'
    end
    return final
end


function exports.conjuate(frame)
    local args = get_frame_args(frame)
    root, pst_form, npst_form, imperative_root = args[1], args[2], args[3], args[4]
end


return exports
