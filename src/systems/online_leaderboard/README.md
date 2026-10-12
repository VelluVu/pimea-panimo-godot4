# Online leaderboard system

A shared leaderboard on a free Supabase project: sends a run through a server function
that checks it, and reads the top of the table. Plain `HTTPRequest`, so it also works in a
web export (Supabase allows cross-origin requests).

## Interface (`OnlineLeaderboard`, a `Node`)

| Call | What it does |
|---|---|
| `base_url`, `api_key` | The project URL and its publishable (anon) key |
| `table`, `columns`, `order` | What `fetch_top()` reads, in PostgREST terms (`order = "score.desc,id.asc"`) |
| `submit_function` | The server function `submit()` calls |
| `is_configured()` | False until the URL and key are set |
| `submit(payload)` | POSTs the payload as the function's named arguments; replies in `submitted(result)` |
| `fetch_top(limit)` | Replies in `top_received(rows)` |
| `request_failed(action, message)` | `action` is `ACTION_SUBMIT` or `ACTION_FETCH`; `message` is the server's exception text, empty on a network error |

`NicknameRules` cleans a player name (printable, single spaced, at most 16 characters).

## The server

Never let the key write the table. Enable row level security, allow `select` only, and
insert through a `security definer` function that checks the score before storing it.
This game has two boards: `dev/tools/leaderboard/demo_scores.sql` for the browser demo and
`season_scores.sql` for the full game (hidden until `SEASON_BOARD_LIVE` in the wiring).

## Use it in a new project

1. Copy this folder (keep the `.uid` files) and create the table and function on Supabase.
2. Edit **`online_leaderboard_wiring.gd`**: the URL and key, the table, the payload your
   function takes, when the list is on, and the wording.
3. Add an `OnlineLeaderboardWiring` node as a child of the window that uses it.

## Files

`online_leaderboard.gd` the client, `nickname_rules.gd` the name rules,
`online_leaderboard_wiring.gd` this game's setup.
Tests: `tests/test_online_leaderboard.gd`, `tests/test_nickname_rules.gd`.
