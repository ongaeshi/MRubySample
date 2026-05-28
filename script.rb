# script.rb
class Player
  attr_reader :x, :y

  def initialize
    @x = 400.0
    @y = 300.0
    @speed = 5.0
  end

  def update(up, down, left, right)
    @y -= @speed if up
    @y += @speed if down
    @x -= @speed if left
    @x += @speed if right
  end
end

$player = Player.new

# C#側から呼ばれる想定のラッパーメソッド
def update_player(up, down, left, right)
  $player.update(up, down, left, right)
end

def get_player_x
  $player.x
end

def get_player_y
  $player.y
end
