-- Writes an editable .aseprite source for a generated PNG: one layer, a palette of exactly
-- the colours the art uses (so hand edits stay in the palette), and for a sheet of frames
-- stacked top to bottom, the frames with a tag and their duration.
--
--   Aseprite.exe -b --script-param png=<in.png> --script-param out=<out.aseprite>
--       [--script-param frames=3 --script-param tag=twinkle --script-param ms=667]
--       [--script-param cell=32 --script-param rows=walk_left:4,sit:4]
--       --script dev/tools/sprites/aseprite_source.lua

local params = app.params
local frames = tonumber(params.frames or "1")
local duration = tonumber(params.ms or "100") / 1000.0

local sheet = Image{ fromFile = params.png }
local width = sheet.width
local height = sheet.height // frames

local sprite = Sprite(width, height, ColorMode.RGB)
sprite.filename = params.out
local layer = sprite.layers[1]
layer.name = "art"

-- The palette: every opaque colour the art uses, in the order first met.
local seen = {}
local colors = {}
for pixel in sheet:pixels() do
  local value = pixel()
  if app.pixelColor.rgbaA(value) > 0 and not seen[value] then
    seen[value] = true
    table.insert(colors, Color(value))
  end
end
local palette = Palette(#colors + 1)
palette:setColor(0, Color{ r = 0, g = 0, b = 0, a = 0 })
for i, color in ipairs(colors) do
  palette:setColor(i, color)
end
sprite:setPalette(palette)

-- A grid sheet (cell=32 rows=walk_left:4,sit:4,...): one row per animation, left to right,
-- each row one tag. Otherwise the frames are stacked top to bottom.
if params.cell then
  local cell = tonumber(params.cell)
  sprite.width = cell
  sprite.height = cell
  local index = 0
  local row = 0
  local spans = {}
  for name, count in string.gmatch(params.rows, "([%w_]+):(%d+)") do
    table.insert(spans, { name = name, first = index + 1, last = index + tonumber(count) })
    for column = 0, tonumber(count) - 1 do
      index = index + 1
      if index > 1 then
        sprite:newEmptyFrame(index)
      end
      local image = Image(cell, cell, ColorMode.RGB)
      image:drawImage(sheet, Point(-column * cell, -row * cell))
      sprite:newCel(layer, index, image, Point(0, 0))
      sprite.frames[index].duration = duration
    end
    row = row + 1
  end
  -- Tags after all frames: a frame added after a tag's end would stretch it.
  for _, span in ipairs(spans) do
    local tag = sprite:newTag(span.first, span.last)
    tag.name = span.name
  end
  sprite:saveAs(params.out)
  return
end

for index = 1, frames do
  if index > 1 then
    sprite:newEmptyFrame(index)
  end
  local image = Image(width, height, ColorMode.RGB)
  image:drawImage(sheet, Point(0, -(index - 1) * height))
  sprite:newCel(layer, index, image, Point(0, 0))
  sprite.frames[index].duration = duration
end
if frames > 1 and params.tag then
  local tag = sprite:newTag(1, frames)
  tag.name = params.tag
end

sprite:saveAs(params.out)
