extends GutTest
## The base every authored resource extends.

func test_game_data_is_a_resource() -> void:
	assert_true(GameData.new() is Resource)
