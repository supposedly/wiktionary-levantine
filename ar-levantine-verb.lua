--[[
    AUTHOR: User:M. I. Wright, with inspiration and some code from Module:ar-verb by User:Benwing
    LICENSE: MIT
    PUBLIC REPO: https://github.com/supposedly/wiktionary-levantine
--]]

local infer_radicals = require('Module:ar-verb').infer_radicals

local exports = {}
local title = mw.title.getCurrentTitle().fullText

local function get_frame_args(frame)
    return frame:getParent().args
end

function exports.IPA(frame)
    local args = get_frame_args(frame)
end

function exports.conj(frame)
    local args = get_frame_args(frame)
end

return exports
