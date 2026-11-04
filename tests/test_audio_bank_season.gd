@tool
extends McpTestSuite


func suite_name() -> String:
	return "audio_bank_season"


func _bank() -> AudioBank:
	var bank := AudioBank.new()
	bank.music_tracks = [AudioStreamWAV.new(), AudioStreamWAV.new()]
	var carols := SeasonMusic.new()
	carols.season = SeasonRules.Season.CHRISTMAS
	carols.tracks = [AudioStreamWAV.new()]
	bank.season_music = [carols]
	return bank


func test_the_carols_join_the_playlist_at_christmas() -> void:
	assert_eq(_bank().run_playlist(SeasonRules.Season.CHRISTMAS).size(), 3)


func test_out_of_season_the_playlist_is_the_usual_one() -> void:
	assert_eq(_bank().run_playlist(SeasonRules.Season.NONE).size(), 2)
	assert_eq(_bank().run_playlist(SeasonRules.Season.HALLOWEEN).size(), 2)


## The shipped bank's Christmas carols load and join only the Christmas playlist.
func test_the_shipped_bank_plays_its_carols_at_christmas() -> void:
	var bank : AudioBank = load("res://src/resources/audio/audio_bank.tres")
	var extra : int = bank.run_playlist(SeasonRules.Season.CHRISTMAS).size() - bank.music_tracks.size()
	assert_eq(extra, 3)
	for track : AudioStream in bank.run_playlist(SeasonRules.Season.CHRISTMAS):
		assert_true(track != null)
	assert_eq(bank.run_playlist(SeasonRules.Season.NONE).size(), bank.music_tracks.size())
