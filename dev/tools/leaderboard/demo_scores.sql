-- The browser demo's shared leaderboard (OnlineLeaderboardWiring in the game).
-- Paste into the Supabase SQL editor and run; running it again is safe.
--
-- Anyone may read the table. Nobody may write it directly: a score goes in only
-- through submit_demo_score(), which recomputes it from its parts the same way as
-- RunScore in the game. When RunScore's formula changes, bump
-- LeaderboardManager.SCORE_VERSION and update expected_version and the formula below.
--
-- To remove a bad name: Table Editor > demo_scores > delete the row.

create table if not exists public.demo_scores (
	id bigint generated always as identity primary key,
	nickname text not null check (char_length(nickname) between 1 and 16),
	score integer not null,
	ending_type text not null check (ending_type in ('demo_over', 'busted', 'bankrupt')),
	-- The demo ends on day 5 (DemoRules.DEMO_LAST_DAY).
	days_survived integer not null check (days_survived between 1 and 5),
	-- Far above what 5 days allow (bots top out near 280 reputation and 4400 points),
	-- so lucky runs always fit and only made-up ones bounce.
	reputation integer not null check (reputation between -1000 and 1000),
	bottles integer not null check (bottles between 0 and 3000),
	worth numeric(10, 1) not null check (worth between 0 and 20000),
	-- Styles brewed this season (RunScore.STYLE_POINTS each); 27 exist.
	styles_brewed integer not null default 0 check (styles_brewed between 0 and 40),
	score_version integer not null,
	created_at timestamptz not null default now()
);

alter table public.demo_scores add column if not exists styles_brewed integer not null default 0
	check (styles_brewed between 0 and 40);

create index if not exists demo_scores_score_idx on public.demo_scores (score desc, id);

alter table public.demo_scores enable row level security;

drop policy if exists "Anyone can read demo scores" on public.demo_scores;
create policy "Anyone can read demo scores" on public.demo_scores
	for select to anon, authenticated using (true);

-- Explicit, so it also works when new tables are not exposed to the API automatically.
grant select on public.demo_scores to anon, authenticated;
revoke insert, update, delete on public.demo_scores from anon, authenticated;


-- The function before score version 6 had no p_styles; drop it so it cannot be called.
drop function if exists public.submit_demo_score(text, text, integer, integer, integer, numeric, integer, integer);

create or replace function public.submit_demo_score(
	p_nickname text,
	p_ending_type text,
	p_days_survived integer,
	p_reputation integer,
	p_bottles integer,
	p_worth numeric,
	p_styles integer,
	p_score integer,
	p_score_version integer
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
	expected_version constant integer := 7;
	-- RunScore: DAY_POINTS, REPUTATION_POINTS, SERVINGS_PER_POINT, WORTH_POINTS_PER_EURO.
	v_counts_reputation boolean := p_ending_type not in ('busted', 'bankrupt');
	v_worth numeric := round(greatest(p_worth, 0), 1);
	expected_score integer;
	v_nickname text := btrim(regexp_replace(coalesce(p_nickname, ''), '\s+', ' ', 'g'));
	new_id bigint;
begin
	if p_score_version is distinct from expected_version then
		raise exception 'version';
	end if;

	-- A flood guard for the whole table, since a browser has no account to limit.
	if (select count(*) from demo_scores where created_at > now() - interval '1 minute') >= 30 then
		raise exception 'busy';
	end if;

	expected_score := p_days_survived * 100 + greatest(p_bottles, 0) / 2
		+ case when v_counts_reputation
			then greatest(p_reputation, 0) * 10 + round(v_worth * 0.5)::integer
			else 0 end;
	if p_styles is null or p_styles < 0 or p_styles > 40 then
		raise exception 'styles';
	end if;
	expected_score := expected_score + p_styles * 100;
	-- The game rounds the unrounded worth, so allow one point either way.
	if abs(expected_score - p_score) > 1 then
		raise exception 'score';
	end if;

	insert into demo_scores (nickname, score, ending_type, days_survived, reputation, bottles, worth, styles_brewed, score_version)
	values (v_nickname, p_score, p_ending_type, p_days_survived, p_reputation, p_bottles, v_worth, p_styles, p_score_version)
	returning id into new_id;

	return json_build_object(
		'id', new_id,
		'rank', (select count(*) from demo_scores where score > p_score) + 1,
		'total', (select count(*) from demo_scores)
	);
end;
$$;

revoke all on function public.submit_demo_score(text, text, integer, integer, integer, numeric, integer, integer, integer) from public;
grant execute on function public.submit_demo_score(text, text, integer, integer, integer, numeric, integer, integer, integer) to anon, authenticated;
