-- Draws the 48x48 close-up faces of the special event callers: one .aseprite (body, face, hair
-- and props on their own layers) and one .png each. Light from the upper left.
--
--   Aseprite.exe -b --script-param out=<absolute path to assets/textures/event_portraits>
--       --script dev/tools/portraits/make_event_portraits.lua
--
-- A row is a run-length string from x = 0: "3.2OS" is three empty, two outline, one skin; '.'
-- leaves what is below. Rows of a part are keyed by y. Edit a row and rerun, or paint the
-- .aseprite by hand and do not rerun for that one.

local HEX = {
  O = "262b44", K = "181425", Q = "3a4466", q = "5a6988", g = "8b9bb4", G = "c0cbdc", W = "ffffff",
  S = "e8b796", M = "e4a672", D = "b86f50", R = "e43b44", r = "a22633", B = "733e39", b = "3e2731",
  Y = "feae34", f = "f77622", Z = "fee761", c = "ead4aa", V = "63c74d", v = "3e8948", x = "265c42",
  C = "0099db", u = "124e89", P = "b55088", I = "68386c", p = "f6757a", o = "2ce8f5",
}

-- { first row, last row, left outline, right outline }
local JAW = { { 2, 2, 14, 33 }, { 3, 3, 11, 36 }, { 4, 4, 9, 38 }, { 5, 5, 8, 39 }, { 6, 6, 7, 40 }, { 7, 31, 6, 41 },
  { 32, 33, 7, 40 }, { 34, 35, 8, 39 }, { 36, 37, 9, 38 }, { 38, 39, 10, 37 }, { 40, 41, 12, 35 }, { 42, 43, 14, 33 }, { 44, 45, 17, 30 } }
local SQUARE_JAW = { { 2, 2, 14, 33 }, { 3, 3, 11, 36 }, { 4, 4, 9, 38 }, { 5, 5, 8, 39 }, { 6, 6, 7, 40 },
  { 7, 37, 6, 41 }, { 38, 40, 7, 40 }, { 41, 42, 8, 39 }, { 43, 43, 10, 37 }, { 44, 45, 12, 35 } }
local SOFT_JAW = { { 2, 2, 14, 33 }, { 3, 3, 11, 36 }, { 4, 4, 9, 38 }, { 5, 5, 8, 39 }, { 6, 6, 7, 40 }, { 7, 29, 6, 41 },
  { 30, 31, 7, 40 }, { 32, 33, 8, 39 }, { 34, 35, 10, 37 }, { 36, 37, 12, 35 }, { 38, 39, 14, 33 }, { 40, 41, 17, 30 }, { 42, 43, 20, 27 } }
local ROUND_JAW = { { 2, 2, 14, 33 }, { 3, 3, 11, 36 }, { 4, 4, 9, 38 }, { 5, 5, 8, 39 }, { 6, 6, 7, 40 },
  { 7, 38, 6, 41 }, { 39, 41, 7, 40 }, { 42, 43, 9, 38 }, { 44, 45, 13, 34 } }

local EARS = {
  [22] = { "4.2O", "42.2O" }, [23] = { "3.O3M", "41.3DO" }, [24] = { "3.O3M", "41.3DO" }, [25] = { "3.OMDM", "41.DbDO" },
  [26] = { "3.OMDM", "41.DbDO" }, [27] = { "3.O3M", "41.3DO" }, [28] = { "3.O3M", "41.3DO" }, [29] = { "4.O2M", "41.2DO" }, [30] = { "5.2O", "41.2O" },
}

local EYES = {
  stern = { [20] = "15.8O4.8O", [21] = "15.O2W2iKWO4.OW2iK2WO", [22] = "15.O2W2iKWO4.OW2iK2WO", [23] = "16.6M6.6D" },
  round = { [19] = "16.6O6.6O", [20] = "15.O6WO4.O6WO", [21] = "15.O2W2iKWO4.OW2iK2WO", [22] = "15.O2W2iKWO4.OW2iK2WO", [23] = "16.6O6.6O" },
  narrow = { [21] = "15.8O4.8O", [22] = "16.W2iK2W6.2W2iKW", [23] = "15.8O4.8O" },
  happy = { [20] = "17.4O8.4O", [21] = "16.O4.O6.O4.O", [22] = "15.O6.O4.O6.O" },
  lashes = { [18] = "14.2O20.2O", [19] = "14.8O6.8O", [20] = "15.O6WO4.O6WO", [21] = "15.O2W2iKWO4.OW2iK2WO", [22] = "15.O2W2iKWO4.OW2iK2WO", [23] = "16.6O6.6O" },
}

local BROWS = {
  stern = { [16] = "13.5e12.5e", [17] = "15.7e4.7e", [18] = "18.5e2.5e" },
  thin = { [16] = "15.8e4.8e", [17] = "14.3e16.3e" },
  flat = { [17] = "14.9e3.9e", [18] = "14.9e3.9e" },
  bushy = { [15] = "15.7e5.7e", [16] = "14.9e3.9e", [17] = "13.10e2.10e", [18] = "14.4e12.4e" },
  worried = { [16] = "18.5e2.5e", [17] = "15.5e8.5e", [18] = "13.3e16.3e" },
}

local NOSE = {
  straight = { [24] = "26.2M", [25] = "26.2M", [26] = "26.2D", [27] = "26.2D", [28] = "26.2D", [29] = "22.S3.2D", [30] = "21.2S4.3D", [31] = "21.8D", [32] = "23.4D" },
  small = { [27] = "26.M", [28] = "26.D", [29] = "26.2D", [30] = "22.6D" },
  wide = { [25] = "26.2M", [26] = "25.3M", [27] = "23.2S3M2D", [28] = "20.M4S3M3D", [29] = "18.2M5S3M4D", [30] = "18.2M5S3M4D", [31] = "19.2D2b5D2b2D", [32] = "21.8D" },
  big = { [25] = "23.4M", [26] = "22.5MD", [27] = "21.6M2D", [28] = "20.2S5M3D", [29] = "20.2S5M3D", [30] = "20.7M3D", [31] = "21.8D", [32] = "23.4D" },
  ruddy = { [25] = "23.4p", [26] = "22.5pD", [27] = "21.6p2D", [28] = "20.2S5p3D", [29] = "20.2S5p3D", [30] = "20.7p3D", [31] = "21.8D", [32] = "23.4D" },
  hook = { [22] = "25.3M", [23] = "25.4M", [24] = "26.4D", [25] = "26.4D", [26] = "26.4D", [27] = "26.4D", [28] = "26.3D", [29] = "22.2S3.3D", [30] = "21.2S4.3D", [31] = "21.8D", [32] = "23.4D" },
}

local MOUTH = {
  flat = { [36] = "18.12O", [37] = "20.8D" },
  smile = { [35] = "16.2O12.2O", [36] = "18.12O", [37] = "20.8D" },
  smirk = { [34] = "30.2O", [35] = "28.3O", [36] = "18.11O", [37] = "20.6D" },
  grin = { [34] = "17.14O", [35] = "17.O12WO", [36] = "17.O12WO", [37] = "18.12O", [38] = "20.8D" },
  worried = { [36] = "20.8O", [37] = "18.2O8.2O" },
}

-- The open mouth of the talking frame, painted over the shut one.
local OPEN = { [35] = "19.10O", [36] = "18.O10bO", [37] = "19.O8rO", [38] = "20.8O" }
local TALK = {
  flat = OPEN, smirk = { [34] = "30.2S", [35] = "19.10O.2S", [36] = "18.O10bO", [37] = "19.O8rO", [38] = "20.8O" },
  worried = OPEN,
  smile = { [35] = "16.2S.10O.2S", [36] = "18.O10bO", [37] = "19.O8rO", [38] = "20.8O" },
  grin = { [34] = "17.14O", [35] = "17.O12bO", [36] = "17.O12bO", [37] = "17.O3r6R3rO", [38] = "18.12O" },
}
local RED_LIPS = { [34] = "19.10R", [35] = "18.R10bR", [36] = "18.R10bR", [37] = "19.10r" }

local DARK_GLASSES = {
  [19] = "11.26K",
  [20] = "7.35K",
  [21] = "12.2K3Q7K2.2K3Q7K",
  [22] = "12.2K2Q8K2.2K2Q8K",
  [23] = "12.12K2.12K",
  [24] = "13.10K4.10K",
  [25] = "15.6K8.6K",
}
local function frames(letter)
  local rows = {
    [19] = "13.24" .. letter,
    [24] = "13.24" .. letter,
  }
  for y = 20, 23 do rows[y] = "13." .. letter .. "10.2" .. letter .. "10." .. letter end
  return rows
end

-- Grey or coloured hair at the temples under a hat, with the hat's shadow on the forehead.
local TEMPLES = {
  [11] = "7.6Gg20D2g5q", [12] = "7.5Gg16M6Dg5q", [13] = "7.4Gg24.g4q",
  [14] = "7.3Gg26.g3q", [15] = "7.3Gg26.g3q", [16] = "7.2Gg28.g2q", [17] = "7.2Gg28.g2q",
  [18] = "7.Gg30.gq", [19] = "7.2g30.2q", [20] = "7.2g30.2q", [21] = "7.2g30.2q", [22] = "7.2g30.2q",
}
local SIDE_PART = {
  [0] = "5.O24n8N4zO", [1] = "5.O24n8N4zO", [2] = "5.O24n8N4zO", [3] = "5.O24n8N4zO", [4] = "5.O24n8N4zO", [5] = "5.O24n8N4zO",
  [6] = "5.O8nz20N7zO", [7] = "5.O8nz20N7zO", [8] = "5.O6n6.16N8zO", [9] = "5.O5n12.11N8zO", [10] = "5.O4n20.5N7zO",
  [11] = "5.O3n26.7zO", [12] = "5.O3n27.6zO", [13] = "5.O2n30.4zO", [14] = "5.O2n30.4zO",
  [15] = "7.2n30.2z", [16] = "7.2n30.2z", [17] = "7.2n30.2z", [18] = "7.2n30.2z",
}
local POMPADOUR = {
  [0] = "8.O14n10N6zO", [1] = "6.O16n12N6zO", [2] = "6.O16n12N6zO", [3] = "6.O16n12N6zO", [4] = "6.O16n12N6zO",
  [5] = "6.O12n14N8zO", [6] = "6.O12n14N8zO", [7] = "6.O12n14N8zO", [8] = "6.O12n14N8zO",
  [9] = "6.O8n6.12N8zO", [10] = "6.O5n14.7N8zO", [11] = "6.O4n20.2N8zO", [12] = "6.O3n24.7zO", [13] = "6.O2n27.5zO", [14] = "6.On28.5zO",
}
for y = 15, 24 do POMPADOUR[y] = "7.2z30.2z" end
local LONG_HAIR = {
  [0] = "3.O18n12N10zO", [1] = "3.O18n12N10zO", [2] = "3.O18n12N10zO", [3] = "3.O18n12N10zO",
  [4] = "2.O18n14N10zO", [5] = "2.O18n14N10zO", [6] = "2.O18n14N10zO", [7] = "2.O18n14N10zO", [8] = "2.O18n14N10zO",
}
for y = 15, 47 do LONG_HAIR[y] = y % 7 < 3 and "2.O3nN2n30.3zN2zO" or "2.O2nN3n30.2zN3zO" end
local BEARD = {
  [26] = "7.3n28.3z", [27] = "7.3n28.3z", [28] = "7.4n26.4z", [29] = "7.5n24.5z", [30] = "7.6n22.6z", [31] = "7.7n20.7z",
  [32] = "7.9n16.9z", [33] = "7.26n8z", [34] = "7.26n8z", [35] = "7.11n12.3n8z", [36] = "7.11n12.3n8z",
  [37] = "7.26n8z", [38] = "7.26n8z", [39] = "7.26n8z", [40] = "7.26n8z", [41] = "7.26n8z",
  [42] = "9.24n8z", [43] = "10.22n7z", [44] = "12.20n6z", [45] = "14.16n6z", [46] = "17.12n4z", [47] = "19.9n3z",
}

-- A copy of `rows` with letters swapped, leaving the run counts alone.
local function tint(rows, map)
  local out = {}
  for y, row in pairs(rows) do out[y] = row:gsub("%a", function(letter) return map[letter] or letter end) end
  return out
end

-- Shoulders behind the jaw, and the collar under the chin; no tie gives a round neck.
local function clothes(lit, shade, collar, tie, tie_shade, top)
  local rows = {}
  for y = top or 40, 44 do rows[y] = "36" .. lit .. "12" .. shade end
  if tie then
    rows[45] = "13" .. lit .. "9" .. collar .. "4" .. tie .. "9" .. collar .. "13" .. shade
    rows[46] = rows[45]
    rows[47] = "14" .. lit .. "8" .. collar .. "4" .. tie_shade .. "8" .. collar .. "14" .. shade
  else
    rows[45] = "13" .. lit .. "22" .. collar .. "13" .. shade
    rows[46] = "14" .. lit .. "20" .. collar .. "14" .. shade
    rows[47] = "15" .. lit .. "18" .. collar .. "15" .. shade
  end
  return rows
end
local BOW_TIE = { [45] = "17.6K2.6K", [46] = "17.14K", [47] = "17.6K2.6K" }

-- Irma's perm: round clumps stamped back to front at hand-picked spots, then outlined.
local CLUMP = {
  "...gggg...",
  ".gGGGGgg..",
  "gGGGGGggq.",
  "gGGGGgggq.",
  "gggggggqq.",
  ".gggqqqq..",
  "...qqq....",
}
local CLUMP_SPOTS = { { 2, -4 }, { 11, -5 }, { 20, -4 }, { 29, -5 }, { 37, -4 },
  { -1, 0 }, { 7, 1 }, { 16, 0 }, { 25, 1 }, { 34, 0 }, { 41, 1 },
  { 1, 5 }, { 10, 6 }, { 20, 4 }, { 30, 6 }, { 38, 5 },
  { -1, 10 }, { 6, 9 }, { 33, 9 }, { 39, 10 }, { 0, 14 }, { 39, 14 } }
local CLUMP_SHADE = { G = "g", g = "q", q = "Q" }

local function curls()
  local cells = {}
  for _, spot in ipairs(CLUMP_SPOTS) do
    for row, text in ipairs(CLUMP) do
      for column = 1, #text do
        local letter = text:sub(column, column)
        local x, y = spot[1] + column - 1, spot[2] + row - 1
        if letter ~= "." and y >= 0 and x >= 0 and x < 48 then
          cells[y * 48 + x] = spot[1] >= 26 and CLUMP_SHADE[letter] or letter
        end
      end
    end
  end
  local rows = {}
  for y = 0, 24 do
    local chars = {}
    for x = 0, 47 do
      local here = cells[y * 48 + x]
      local beside = (x > 0 and cells[y * 48 + x - 1]) or (x < 47 and cells[y * 48 + x + 1]) or cells[(y - 1) * 48 + x] or cells[(y + 1) * 48 + x]
      chars[#chars + 1] = here or (beside and "O") or "."
    end
    rows[y] = table.concat(chars)
  end
  return rows
end
local CURLS = curls()

local CALLERS = {
  don = {
    jaw = SQUARE_JAW, first_row = 7, eyes = "stern", brows = "stern", nose = "straight", brow = "g", iris = "Q",
    body = clothes("Q", "K", "W", "R", "r"),
    hair = {
      { [0] = "11.O3g19q2QO", [1] = "11.O3g19q2QO", [2] = "11.O3g19q2QO", [3] = "11.O2g20q2QO",
        [4] = "11.O24KO", [5] = "11.O24KO", [6] = "4.40O",
        [7] = "2.O8g29q5QO", [8] = "1.O8g31q5QO", [9] = "1.O4g35q5QO", [10] = "2.44O" },
      TEMPLES,
    },
    props = { DARK_GLASSES, { [33] = "16.16g", [34] = "17.14q", [35] = "30.7B2Y6B3r", [36] = "18.4O3Y5O7B2Y6B3R", [37] = "30.7b2f6b3r" } },
    -- Gold teeth; the glint under the lip shows only while he talks.
    talk = { [35] = "18.12O", [36] = "18.OYZWY2bYZ2YO", [37] = "18.O4Y2b4fO", [38] = "19.10O", [40] = "24.W", [41] = "23.3W", [42] = "24.W" },
  },
  nosy_neighbour = {
    jaw = JAW, eyes = "round", brows = "thin", nose = "wide", brow = "q", iris = "B",
    body = clothes("P", "I", "c"), hair = { CURLS },
    props = { frames("P"), { [18] = "11.3P22.3P", [31] = "12.M23.D", [32] = "12.M23.D", [33] = "13.M21.D", [36] = "20.8O", [37] = "22.4r" } },
    talk = { [36] = "20.8O", [37] = "20.O6bO", [38] = "21.6O" },
  },
  brand_deal = {
    jaw = SOFT_JAW, eyes = "round", brows = "thin", nose = "small", brow = "B", iris = "Q",
    body = clothes("P", "I", "W", nil, nil, 38),
    hair = { tint(LONG_HAIR, { n = "c", N = "M", z = "D" }),
      { [9] = "2.O22c4.10M6DO", [10] = "2.O18c10.8M6DO", [11] = "2.O14c16.6M6DO", [12] = "2.O11c22.3M6DO", [13] = "2.O9c26.M6DO", [14] = "2.O8c28.6DO" } },
    props = { frames("R"), { [29] = "10.4p21.3p", [30] = "10.4p21.3p", [34] = "19.10R", [35] = "18.12R", [36] = "20.8r" } },
    talk = RED_LIPS,
  },
  journalist = {
    jaw = SOFT_JAW, eyes = "lashes", brows = "thin", nose = "small", brow = "b", iris = "x",
    body = clothes("c", "M", "W", "B", "b", 38),
    hair = { tint(LONG_HAIR, { n = "D", N = "B", z = "b" }),
      { [9] = "2.O18D12B12bO", [10] = "2.O18D12B12bO", [11] = "2.O18D12B12bO", [12] = "2.O18D12B12bO", [13] = "2.O18D12B12bO", [14] = "2.O6D30.6bO" } },
    props = { [29] = "12.3p23.3p", [35] = "19.10r", [36] = "20.8R", [18] = "39.7Y", [19] = "39.6f" },
    talk = RED_LIPS,
  },
  olutkisa = {
    jaw = JAW, first_row = 7, eyes = "narrow", brows = "bushy", nose = "big", brow = "g", iris = "B", mouth = "smile",
    body = clothes("B", "b", "c", "x", "x"),
    hair = {
      { [0] = "6.O8V20v6xO", [1] = "6.O8V20v6xO", [2] = "6.O8V20v6xO", [3] = "6.O8V20v6xO", [4] = "6.O8V20v6xO", [5] = "6.O8V20v6xO",
        [6] = "4.40O", [7] = "3.O8V26v6xO", [8] = "3.O8V26v6xO", [9] = "4.40O" },
      tint(TEMPLES, { G = "G", g = "g", q = "q" }),
    },
    props = { [2] = "21.6Y", [3] = "20.3Y2R3Y", [4] = "20.3Y2R3Y", [5] = "21.6Y", [33] = "15.18g", [34] = "14.20g" },
  },
  dance = {
    jaw = JAW, eyes = "narrow", brows = "flat", nose = "straight", brow = "K", iris = "b", mouth = "smile",
    body = clothes("r", "B", "W"), hair = { tint(POMPADOUR, { n = "q", N = "Q", z = "K" }) }, props = { BOW_TIE },
  },
  electrician = {
    jaw = SQUARE_JAW, first_row = 7, eyes = "stern", brows = "bushy", nose = "big", brow = "b", iris = "b", mouth = "flat",
    body = clothes("q", "Q", "c"),
    hair = {
      { [0] = "6.O4Z26Y4fO", [1] = "6.O4Z26Y4fO", [2] = "6.O4Z26Y4fO", [3] = "6.O4Z26Y4fO", [4] = "6.O4Z26Y4fO", [5] = "6.O4Z26Y4fO",
        [6] = "6.O3Z27Y4fO", [7] = "6.O3Z27Y4fO", [8] = "6.O3Z27Y4fO", [9] = "2.O6Z30Y6fO", [10] = "2.44O" },
      tint(TEMPLES, { G = "B", g = "b", q = "b" }),
    },
    props = { [0] = "21.6Z", [1] = "21.6Z", [2] = "21.6Z", [3] = "21.6Z", [4] = "21.6Z", [33] = "13.22b", [34] = "14.20b" },
  },
  ingredient_loan = {
    jaw = JAW, eyes = "round", brows = "flat", nose = "straight", brow = "f", iris = "x", mouth = "smile", talk = OPEN,
    body = clothes("B", "b", "c"),
    hair = {
      { [0] = "6.O8C20u6QO", [1] = "6.O8C20u6QO", [2] = "6.O8C20u6QO", [3] = "6.O8C20u6QO", [4] = "6.O8C20u6QO", [5] = "6.O8C20u6QO", [6] = "6.O8C20u6QO",
        [7] = "4.O3Cu3Cu3Cu3Cu3Cu3uQ3uQ3uQ3uQ2uO", [8] = "4.O3Cu3Cu3Cu3Cu3Cu3uQ3uQ3uQ3uQ2uO", [9] = "4.O3Cu3Cu3Cu3Cu3Cu3uQ3uQ3uQ3uQ2uO", [10] = "4.40O",
        [11] = "7.34D" },
      tint(BEARD, { n = "f", z = "B" }),
    },
  },
  lvv_bribe = {
    jaw = JAW, eyes = "narrow", brows = "stern", nose = "hook", brow = "Q", iris = "Q", mouth = "smirk",
    body = clothes("q", "Q", "W", "u", "O"), hair = { tint(SIDE_PART, { n = "g", N = "q", z = "Q" }) }, props = { frames("Q") },
  },
  lvv_favour = {
    jaw = ROUND_JAW, eyes = "happy", brows = "flat", nose = "straight", brow = "B", iris = "B", mouth = "grin",
    body = clothes("u", "O", "W", "R", "r"), hair = { tint(SIDE_PART, { n = "f", N = "B", z = "r" }) },
    props = { [35] = "24.2Y", [36] = "24.2Y", [29] = "10.3p25.3p" },
  },
  quality_critic = {
    jaw = JAW, first_row = 8, eyes = "stern", brows = "thin", nose = "hook", brow = "b", iris = "B", mouth = "flat",
    body = clothes("Q", "O", "Y"),
    hair = { { [0] = "9.O4R20r4BO", [1] = "7.O5R22r5BO", [2] = "5.O6R24r6BO", [3] = "4.O8R26r6BO", [4] = "3.O8R26r8BO", [5] = "3.O8R26r8BO", [6] = "3.O8R26r8BO", [7] = "4.O8R24r8BO", [8] = "5.O7R22r8BO", [9] = "6.36O" } },
    props = { [17] = "27.8Y", [18] = "26.Y8.Y", [19] = "25.Y10.Y", [20] = "25.Y10.Y", [21] = "25.Y10.Y", [22] = "25.Y10.Y", [23] = "25.Y10.Y", [24] = "26.Y8.Y", [25] = "27.8Y",
      [33] = "16.5b6.5b", [40] = "20.8b", [41] = "20.8b", [42] = "21.6b", [43] = "22.4b" },
  },
  renovation = {
    jaw = SQUARE_JAW, first_row = 7, eyes = "narrow", brows = "flat", nose = "straight", brow = "b", iris = "b", mouth = "flat",
    body = clothes("f", "R", "q"),
    hair = {
      { [0] = "6.O8R20r6BO", [1] = "6.O8R20r6BO", [2] = "6.O8R20r6BO", [3] = "6.O8R20r6BO", [4] = "6.O8R20r6BO", [5] = "6.O8R20r6BO", [6] = "6.O8R20r6BO",
        [7] = "6.O34BO", [8] = "6.O34BO", [9] = "6.36O" },
      tint(TEMPLES, { G = "B", g = "b", q = "b" }),
    },
    props = { [19] = "41.7Y", [20] = "41.6fq", [44] = "12Z24.12Z" },
  },
  sailor_bet = {
    jaw = JAW, first_row = 7, eyes = "narrow", brows = "bushy", nose = "ruddy", brow = "G", iris = "C", mouth = "flat",
    body = clothes("W", "G", "u"),
    hair = {
      { [0] = "9.O4W20G4gO", [1] = "9.O4W20G4gO", [2] = "9.O4W20G4gO", [3] = "9.O4W20G4gO", [4] = "9.O28KO", [5] = "9.O28KO", [6] = "4.40O",
        [7] = "2.O8Q28K6KO", [8] = "2.O8Q28K6KO", [9] = "2.44O" },
      tint(TEMPLES, { G = "W", g = "G", q = "g" }),
      tint(BEARD, { n = "W", z = "G" }),
    },
    props = { [1] = "22.4Y", [2] = "23.2Y", [3] = "21.6Y", [31] = "38.8b", [32] = "39.6B", [33] = "39.6B", [34] = "39.6B", [35] = "39.6B", [36] = "28.11B6b", [37] = "28.11b6b",
      [44] = "12u24.12u", [47] = "12u24.12u" },
  },
  training_course = {
    jaw = JAW, eyes = "happy", brows = "flat", nose = "small", brow = "f", iris = "C", mouth = "grin",
    body = clothes("C", "u", "W"),
    hair = { { [0] = "10.3Z4.3Z4.3Y4.3Y4.3f", [1] = "9.4Z2.4Z2.4Y2.4Y2.4f", [2] = "8.6Z.6Z.6Y.6Y.6f",
      [3] = "6.O10Z14Y10fO", [4] = "6.O10Z14Y10fO", [5] = "6.O10Z14Y10fO", [6] = "6.O10Z14Y10fO", [7] = "6.O10Z14Y10fO",
      [8] = "6.O8Z18.8fO", [9] = "6.O5Z24.5fO", [10] = "6.O3Z28.3fO" } },
    props = { [22] = "41.5K", [23] = "41.5K", [24] = "41.5K", [25] = "41.5K", [26] = "41.5K", [27] = "42.3K", [28] = "43.2q", [29] = "43.2q", [30] = "43.2q", [31] = "43.2q", [32] = "43.2q",
      [33] = "33.12q", [34] = "30.4K", [35] = "30.4K", [36] = "30.4K" },
  },
  wedding_order = {
    jaw = JAW, eyes = "round", brows = "worried", nose = "straight", brow = "B", iris = "u", mouth = "worried",
    body = clothes("Q", "K", "W"), hair = { tint(SIDE_PART, { n = "M", N = "D", z = "B" }) },
    props = { BOW_TIE, { [12] = "44.2o", [13] = "43.3o", [14] = "43.2oC", [15] = "44.2C", [20] = "1.2o", [21] = "0.3o", [22] = "0.2oC", [23] = "1.2C" } },
  },
  youtuber = {
    jaw = JAW, eyes = "round", brows = "flat", nose = "small", brow = "x", iris = "v", mouth = "grin",
    body = clothes("I", "O", "P"), hair = { tint(POMPADOUR, { n = "V", N = "v", z = "x" }) },
    props = { [32] = "37.11K", [33] = "37.K9QK", [34] = "37.K9QK", [35] = "37.K9QK", [36] = "37.K2R7QK", [37] = "37.K2R7QK", [38] = "37.K9QK", [39] = "37.K9QK", [40] = "37.K9QK",
      [41] = "37.K9QK", [42] = "37.K9QK", [43] = "37.K9QK", [44] = "37.K9QK", [45] = "37.K9QK", [46] = "37.K9QK", [47] = "37.11K" },
  },
  kaljakellunta = {
    jaw = ROUND_JAW, first_row = 7, eyes = "stern", brows = "flat", nose = "ruddy", brow = "b", iris = "b", mouth = "grin",
    body = clothes("f", "R", "Y"),
    hair = {
      { [0] = "8.O4Z22Y4fO", [1] = "8.O4Z22Y4fO", [2] = "8.O4Z22Y4fO", [3] = "8.O4Z22Y4fO", [4] = "8.O4Z22Y4fO", [5] = "8.O4Z22Y4fO", [6] = "5.38O",
        [7] = "2.O8Z28Y6fO", [8] = "1.O8Z30Y6fO", [9] = "1.O6Z32Y6fO", [10] = "2.44O" },
      tint(TEMPLES, { G = "c", g = "M", q = "D" }),
    },
    props = { DARK_GLASSES, { [29] = "9.5p26.4p", [30] = "9.5p26.4p" } },
  },
  old_master = {
    jaw = JAW, eyes = "narrow", brows = "bushy", nose = "ruddy", brow = "g", iris = "b", mouth = "flat",
    body = clothes("x", "O", "B"),
    hair = { { [12] = "3.O3g34.3qO", [13] = "2.O4g34.4qO", [14] = "2.O4g34.4qO", [15] = "2.O4g34.4qO", [16] = "2.O4g34.4qO", [17] = "2.O4g34.4qO", [18] = "2.O4g34.4qO", [19] = "2.O4g34.4qO", [20] = "3.O3g34.3qO", [21] = "4.2O36.2O" },
      tint(BEARD, { n = "g", z = "q" }) },
    props = { [5] = "14.5W", [6] = "13.4W", [7] = "13.2W" },
  },
}

local function expand(row)
  local out, count = {}, ""
  for char in row:gmatch(".") do
    if char:match("%d") then count = count .. char
    elseif char ~= " " then out[#out + 1] = char:rep(tonumber(count) or 1); count = "" end
  end
  return table.concat(out)
end

local function to_color(key)
  local hex = assert(HEX[key], "unknown colour " .. tostring(key))
  return Color{ r = tonumber(hex:sub(1, 2), 16), g = tonumber(hex:sub(3, 4), 16), b = tonumber(hex:sub(5, 6), 16) }
end

local function paint(image, y, row, caller, name, used)
  local text = expand(row)
  assert(#text <= 48, name .. ": row " .. y .. " is " .. #text .. " wide")
  for x = 1, #text do
    local letter = text:sub(x, x)
    if letter ~= "." then
      local key = letter == "e" and caller.brow or letter == "i" and caller.iris or letter
      used[key] = true
      image:drawPixel(x - 1, y, to_color(key))
    end
  end
end

local function paint_rows(image, rows, caller, name, used)
  for y, row in pairs(rows) do
    if type(row) == "table" then
      for _, part in ipairs(row) do paint(image, y, part, caller, name, used) end
    else
      paint(image, y, row, caller, name, used)
    end
  end
end

-- `first_row` hides the top of the skull under a hat with a narrower crown.
local function head_rows(jaw, first_row)
  local span = {}
  for _, band in ipairs(jaw) do
    for y = math.max(band[1], first_row or 0), band[2] do span[y] = { band[3], band[4] } end
  end
  local inside = function(x, y) return span[y] and x > span[y][1] and x < span[y][2] end
  local rows = {}
  for y, s in pairs(span) do
    local chars = {}
    for x = s[1], s[2] do
      local edge = x == s[1] or x == s[2] or not inside(x, y - 1) or not inside(x, y + 1)
      if edge then chars[#chars + 1] = "O"
      elseif x >= s[2] - 4 then chars[#chars + 1] = "D"
      elseif x >= s[2] - 8 then chars[#chars + 1] = "M"
      else chars[#chars + 1] = "S" end
    end
    rows[y] = s[1] .. "." .. table.concat(chars)
  end
  return rows
end

-- A part is one table of rows, or a list of them painted in order.
local function as_list(part)
  if part == nil then return {} end
  return part[1] ~= nil and type(part[1]) == "table" and #part > 0 and part or { part }
end

local function draw(name, caller)
  local sprite = Sprite(48, 48, ColorMode.RGB)
  local used = {}
  local parts = {
    { "body", { caller.body } },
    { "face", { head_rows(caller.jaw, caller.first_row), EARS, BROWS[caller.brows], EYES[caller.eyes], NOSE[caller.nose], caller.mouth and MOUTH[caller.mouth] or {} } },
    { "hair", caller.hair or {} },
    { "props", as_list(caller.props) },
  }
  sprite:newEmptyFrame(2)
  sprite.frames[1].duration = 0.15
  sprite.frames[2].duration = 0.15
  local sheet = Image(96, 48, ColorMode.RGB)
  local bottom = sprite.layers[1]
  for index, part in ipairs(parts) do
    local layer = index == 1 and bottom or sprite:newLayer()
    layer.name = part[1]
    local image = Image(48, 48, ColorMode.RGB)
    for _, rows in ipairs(part[2]) do paint_rows(image, rows, caller, name, used) end
    sprite:newCel(layer, 1, image, Point(0, 0))
    sprite:newCel(layer, 2, image, Point(0, 0))
    sheet:drawImage(image, Point(0, 0))
    sheet:drawImage(image, Point(48, 0))
  end
  -- The open mouth is its own layer, on the talking frame only.
  local mouth = sprite:newLayer()
  mouth.name = "talking mouth"
  local open = Image(48, 48, ColorMode.RGB)
  paint_rows(open, caller.talk or TALK[caller.mouth] or OPEN, caller, name, used)
  sprite:newCel(mouth, 2, open, Point(0, 0))
  sheet:drawImage(open, Point(48, 0))
  local tag = sprite:newTag(1, 2)
  tag.name = "talk"

  local keys = {}
  for key in pairs(used) do keys[#keys + 1] = key end
  table.sort(keys)
  local palette = Palette(#keys + 1)
  palette:setColor(0, Color{ r = 0, g = 0, b = 0, a = 0 })
  for index, key in ipairs(keys) do palette:setColor(index, to_color(key)) end
  sprite:setPalette(palette)

  sprite:saveAs(app.params.out .. "/" .. name .. ".aseprite")
  sheet:saveAs(app.params.out .. "/" .. name .. ".png")
  sprite:close()
  print(name .. ": " .. #keys .. " colours")
end

local names = {}
for name in pairs(CALLERS) do names[#names + 1] = name end
table.sort(names)
for _, name in ipairs(names) do draw(name, CALLERS[name]) end
