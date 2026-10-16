# Brewing rework: real colour, real strength, recipe-defined styles

Design agreed with the developer on 2026-10-14. Replaces `beer_styles_reference.txt`
(2026-09-14), which described the old linear-EBC, colour-ladder styles.

## Why

Styles were told apart mostly by narrow invented EBC windows (Dubbel 31-35, Strong Dark
36-40, ...). Real recipes missed them, roast malts could not be modelled, ABV was a fixed
number per style, and some styles shadowed others (Amber took Pale Ale's EBC 20-30).
Styles are now defined the way brewers define them: what the grist is made of, how strong
it is, its colour and bitterness, and its yeast.

## Formulas (20 L keg)

- **Colour (Morey):** MCU = Σ(kg × 2.2046 × °L) / (20 / 3.785), with
  °L = (EBC × 0.508 + 0.76) / 1.3546; SRM = 1.4922 × MCU^0.6859; EBC = SRM × 1.97.
  Ingredient EBCs are real maltster values.
- **Strength:** gravity points = Σ(kg × extract × 384 × efficiency) / 20, efficiency 0.72
  for malts, 1.0 for sugar. ABV = points × yeast attenuation × 0.131. Each batch keeps its
  own ABV (`BrewBatch.abv`); the style's `abv` is only its typical value for the book.
- **Bitterness:** IBU = Σ(alpha × grams × utilisation) / 10, where HopRoles puts each hop
  on one of the style's marks and the mark sets the utilisation (`HopUtilization`, from
  Tinseth's boil-time term 1 − e^(−0.04 t) relative to 60 min): bittering 1.0, flavour
  (15 min) 0.5, aroma (flame-out stand, ~2.5 min) 0.1, dry hop 0. So the same hops give
  each style its own IBU. Wort gravity (Tinseth's bigness factor) is left out.

## Resolver rules

A style matches when all hold:
1. the yeast is the style's yeast;
2. its required malt and required spice are on the table;
3. its base malts make at least `min_base_share` of the malt weight;
4. EBC, IBU and ABV are inside the style's ranges;
5. an aroma hop is present if the style needs one;
6. at least 3 kg of malt.

Order: styles with a required ingredient first, then styles with a base share, then the
rest; file order within a group. Intended overlaps (the first one wins): Strong Dark over
Barleywine (candi syrup), Rauchbier over Märzen (smoked malt), Scotch Ale over Dubbel
(roasted barley), Session Ale over Pale Ale (wheat).

Quality precision now averages EBC, IBU and ABV, each best in the middle of its range.
A brew matching nothing still comes out as kotikalja (failed, −1 reputation) with its
computed ABV, so an alcohol-free yeast gives an alcohol-free failure.

Favourite hop profiles become a list per style (flavour bonus if any late hop matches).
Favourite malts and bittering hops are book information only: the ranges are centred on
the reference recipes, so the right malts already score best.

Each style stores its **reference recipe** (the developer's favourite). It seeds the
default recipe, sets the cost price, and a test checks that it resolves to its own style.

## Ingredients

Malt amounts stay in whole kilograms, except dark roast malts, which come in **100 g
packs** (shown as "0,3 kg").

| Id | Malt | EBC | Extract | Unit | Note |
|---|---|---|---|---|---|
| 100 | Pilsner | 3 | 0.81 | kg | was 2 |
| 101 | Pale ale | 6 | 0.80 | kg | was 4 |
| 102 | Karamelli | 60 | 0.74 | kg | was 20 |
| 103 | Vehnä | 4 | 0.82 | kg | |
| 104 | Münchenin | 20 | 0.78 | kg | was 30 |
| 105 | Ruskea | 150 | 0.70 | kg | was 45 |
| 106 | Keksi | 50 | 0.75 | kg | was 55 |
| 107 | Tumma karamelli | 300 | 0.70 | kg | was 140 |
| 108 | Savu | 6 | 0.78 | kg | |
| 109 | **Vienna-mallas** | 8 | 0.79 | kg | new |
| 110 | **Ruismallas** | 7 | 0.78 | kg | new |
| 111 | **Suklaamallas** | 1000 | 0.65 | 100 g | new |
| 112 | **Paahdettu ohra** | 1400 | 0.60 | 100 g | new |
| 113 | **Carafa** | 1150 | 0.65 | 100 g | new, dehusked black malt |
| 114 | **Tumma kandisiirappi** | 175 | 0.70 (sugar) | kg | new, 100 % fermentable |

| Id | Hop | Alpha | Beta | Profile | New |
|---|---|---|---|---|---|
| 213 | Warrior | 16 | 5 | none (bittering) | yes |
| 214 | Perle | 8 | 4 | Noble | yes |
| 215 | Styrian Golding | 5 | 3 | Earthy | yes |
| 216 | Galaxy | 15 | 7 | Tropical | yes |
| 217 | Nelson Sauvin | 12 | 7 | Tropical (white wine, gooseberry) | yes |

Yeast attenuation: lager 80, ale 75, baking 70, alcohol-free 8 (was 15; 15 % made a 4 kg
brew 0.6 %).

## Styles

Ranges are game ranges, set around the reference recipes and informed by BJCP 2021.
"Base" is the base malt(s) and their minimum share of the malt weight.

| Style | Yeast | Base | Required | EBC | IBU | ABV | Reference recipe → EBC, ABV |
|---|---|---|---|---|---|---|---|
| Kotikalja | baking | – | – | 0-8 | 0-10 | 2.0-4.5 | 3 Pilsner → 4.9, 3.1 %, no hops (IBU from 0: anything below the middle counts as perfect) |
| Bulkkilager | lager | Pilsner 80 % | – | 3-7 | 8-20 | 4.0-5.5 | 4 Pilsner → 6.0, 4.7 % |
| Tumma Lager | lager | Pilsner 50 % | – | 28-55 | 8-34 | 4.0-5.9 | 3 Pilsner + 1 Tumma karamelli → 42.6, 4.5 % |
| Pale Ale | ale | Pale ale 75 % | aroma hop | 6-19 | 12-39 | 4.0-6.2 | 4 Pale ale → 8.5, 4.3 % |
| Amber Ale | ale | Pale ale 60 % | – | 20-35 | 25-39 | 4.5-6.2 | 4 Pale ale + 1 Karamelli + 0.5 Ruskea → 27.6, 5.8 % |
| IPA | ale | Pale ale 70 % | aroma hop | 8-28 | 40-70 | 5.5-7.5 | 5 Pale ale + 1 Münchenin → 13.5, 6.5 % |
| Helles | lager | Pilsner 50 % | – | 8-14 | 14-22 | 4.2-5.6 | 2 Pilsner + 1 Münchenin + 1 Vienna → 10.3, 4.6 % |
| Vienna Lager | lager | Vienna 60 % | – | 8-25 | 18-30 | 4.2-5.9 | 3 Vienna + 1 Münchenin → 12.0, 4.6 % |
| Märzen | lager | Münchenin 50 % | – | 14-33 | 18-28 | 5.2-6.6 | 3 Münchenin + 1 Vienna + 1 Pilsner → 16.4, 5.7 % |
| Baltic Portteri | lager | – | – | 35-70 | 20-40 | 6.2-9.5 | 2 Münchenin + 2 Pilsner + 1 Vienna + 1 Tumma karamelli → 46.9, 6.8 % |
| Doppelbock | lager | – | – | 12-34 | 16-26 | 6.8-10.0 | 3 Münchenin + 2 Pilsner + 1 Vienna + 1 Karamelli → 25.0, 8.0 % |
| Hefeweizen | ale | Vehnä 50 % | – | 4-14 | 8-15 | 4.0-5.8 | 2 Vehnä + 2 Pilsner → 6.4, 4.4 % |
| Witbier | ale | Pilsner 60 % | Vehnä + Korianteri + Pomeranssinkuori | 3-10 | 8-20 | 4.0-5.2 | 3 Pilsner + 1 Vehnä → 6.2, 4.4 % |
| Session Ale | ale | Pale ale 60 % | Vehnä | 4-14 | 8-25 | 3.0-4.6 | 2 Pale ale + 1 Vehnä → 6.5, 3.3 % |
| Saison | ale | Pilsner 60 % | – | 6-19 | 16-35 | 5.3-7.5 | 4 Pilsner + 1 Münchenin → 10.2, 5.5 % |
| Belgian Dubbel | ale | Pils/Pale 70 % | – | 20-50 | 15-25 | 6.3-7.9 | 5 Pale ale + 1 Münchenin + 1 Tumma karamelli → 46.7, 7.4 % |
| Belgian Strong Dark | ale | Pils/Pale/Vienna 60 % | Tumma kandisiirappi | 24-50 | 20-35 | 8.0-11.0 | 6 Pilsner + 1 Münchenin + 1 Karamelli + 1 siirappi → 39.9, 10.0 % |
| Scotch Ale | ale | Pale ale 75 % | Paahdettu ohra | 28-49 | 15-30 | 6.5-9.0 | 6 Pale ale + 1 Karamelli + 0.1 ohra → 36.0, 7.6 % |
| Barleywine | ale | Pale ale 70 % | – | 16-45 | 35-70 | 8.5-12.0 | 7 Pale ale + 1 Münchenin + 1 Karamelli + 1 Keksi → 29.8, 10.7 % |
| Imperial Stout | ale | Pale ale 60 % | – | 60-250 | 45-90 | 8.5-12.0 | 7 Pale ale + 1 Ruskea + 1 Karamelli + 0.5 Suklaa + 0.5 ohra → 122, 10.4 % |
| Alkoholiton IPA | NA ale | Pale ale 70 % | aroma hop | 6-28 | 30-70 | 0-0.5 | 3 Pale ale → 7.0, 0.3 % |
| Alkoholiton Lager | NA lager | Pilsner 70 % | – | 3-10 | 8-22 | 0-0.5 | 3 Pilsner → 4.9, 0.4 % |
| Sahti | baking | – | Ruis + Katajanoksat | 8-43 | 0-15 | 6.5-11.0 | 3 Pilsner + 2 Münchenin + 2 Vienna + 1 Ruis → 17.2, 8.0 % |
| Maitostout | ale | – | Laktoosi | 50-160 | 15-40 | 4.0-6.5 | 3 Pale ale + 1 Karamelli + 1 Suklaa → 99.5, 5.1 % |
| **Rauchbier** (new) | lager | Savu 30 % | Savu | 12-43 | 20-30 | 4.8-6.4 | 2 Savu + 2 Münchenin + 1 Vienna → 14.8, 5.7 % |
| **Roggenbier** (new) | ale | Ruis 50 % | Ruis | 10-37 | 10-20 | 4.2-6.0 | 2 Ruis + 1 Pilsner + 1 Münchenin → 10.9, 4.3 % |
| **Irish Dry Stout** (new) | ale | Pale ale 60 % | Paahdettu ohra | 50-100 | 25-45 | 3.8-5.0 | 4 Pale ale + 0.5 ohra → 75.9, 4.8 % |

Favourite hops (book info; profiles count for the flavour bonus):

| Style | Bittering | Aroma / flavour profiles |
|---|---|---|
| Bulkkilager, Tumma Lager | Magnum or European | Noble |
| Pale Ale | mainly Magnum or Warrior | Citrus, Tropical, Pine (American), Earthy (English) |
| Amber Ale | Magnum, Warrior | Citrus, Tropical, Pine, Earthy |
| IPA | mainly Magnum or Warrior | Citrus, Tropical, Pine (American), Earthy (English) |
| Helles, Vienna, Märzen, Doppelbock, Portteri | Magnum, Saaz | Noble (Hallertau, Tettnanger, Saaz, Perle) |
| Hefeweizen, Witbier | German noble | Noble |
| Session Ale | Magnum, Warrior (a small charge) | Citrus, Tropical, Pine, Earthy |
| Saison | European | Earthy, Noble (Fuggle, Styrian Golding, Saaz, Hallertau) |
| Dubbel, Strong Dark | noble | Noble |
| Scotch Ale | English | Earthy |
| Barleywine | American or English | Citrus, Tropical, Pine, Earthy |
| Imperial Stout | Magnum | Citrus, Pine, Earthy |
| Alkoholiton IPA | mainly Magnum or Warrior | Citrus, Tropical, Pine (American), Earthy (English) |
| Alkoholiton Lager | Magnum, Warrior | Noble |
| Sahti | none | Noble (flavour only) |
| Maitostout | English or Magnum | Earthy |

Open: hop timing, ABV and price balance (bot playtests), the recipe book rework and the
style descriptions (after tuning).

## Build order

1. Engine: Morey colour, grist ABV, base shares, ABV ranges, hop profile lists, reference
   recipes, resolver order, 100 g packs. Tests.
2. Data: new and retuned ingredients, all styles, the three new styles (enum, names,
   achievements, translations). Every reference recipe resolves to itself.
3. UI amounts for 100 g packs; bot playtests for balance.
4. Recipe book rework, then style descriptions.

## Balance pass (2026-10-14)

Measured with the playtest bots, 30-36 runs per batch.

- **Reference recipes** use Magnum for most of the bitterness and 5 g of a favourite
  aroma hop: hops cost 2-5 € a gram, and 20-40 g aroma doses made Witbier cost more than
  it sells for. Every recipe now costs 25-60 % of its price.
- **Ranges are centred on the reference recipes** (same widths): the reference recipe
  scores precision 0.84-1.0. Re-centring needed four separations: Doppelbock EBC up to 29
  and Portteri from 30, Imperial Stout from EBC 45, Portteri from 5.6 % ABV, Saison from
  5.1 % ABV. Only the intended overlaps remain.
- **Exports** pay StylePricing.WHOLESALE_SHARE (25 %) of the list price, not the
  recipe's cost, so changing a recipe cannot move export income.
- **Customers** whose favourites were all behind the mash tun got a reachable second
  choice: Barbaari Baltic Portteri, Munkki Saison.
- **Careless play fails by design** (developer's call): bots that ignore LVV risk (greedy,
  variety, cheap) get busted every run, because good recipes raise reputation and higher
  reputation tiers lower the raid limit. Judge balance by the risk-aware bots (careful,
  gourmet, expert, calm, minmax); all of them survive.
- **First brew of each style every season** (FirstBrewRules), also for styles known from
  earlier seasons: the batch is a novelty ("Uutuus!") that sells +25 % at the counter, the
  brew pays 10 XP per point of the style's reputation_change, the daily goal "Keitä uusi
  tyyli" rewards it, and the season score gives RunScore.STYLE_POINTS (50) per style
  brewed (score version 6, both leaderboard SQL files updated).
