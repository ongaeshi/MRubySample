# 距離ベースの簡易当たり判定 (円形判定)
def circle_intersect?(x1, y1, r1, x2, y2, r2)
  dx = x1 - x2
  dy = y1 - y2
  dist_sq = dx * dx + dy * dy
  dist_sq < (r1 + r2) * (r1 + r2)
end

class Player
  attr_accessor :x, :y, :r, :speed, :color, :cooldown

  def initialize
    @x = 400
    @y = 500
    @r = 15
    @speed = 6.0
    @color = Raylib::GREEN
    @cooldown = 0
  end

  def update(bullets)
    if Raylib.is_key_down(Raylib::KEY_LEFT)
      @x -= @speed
    end
    if Raylib.is_key_down(Raylib::KEY_RIGHT)
      @x += @speed
    end
    if Raylib.is_key_down(Raylib::KEY_UP)
      @y -= @speed
    end
    if Raylib.is_key_down(Raylib::KEY_DOWN)
      @y += @speed
    end

    @x = @r if @x < @r
    @x = 800 - @r if @x > 800 - @r
    @y = @r if @y < @r
    @y = 600 - @r if @y > 600 - @r

    if @cooldown > 0
      @cooldown -= 1
    end

    if (Raylib.is_key_down(Raylib::KEY_SPACE) || Raylib.is_key_down(Raylib::KEY_Z)) && @cooldown == 0
      bullets << Bullet.new(@x, @y - @r)
      @cooldown = 8 # 弾の発射間隔（フレーム数）
    end
  end

  def draw
    # 上向きの三角形として描画
    v1x = @x
    v1y = @y - @r
    v2x = @x - @r
    v2y = @y + @r
    v3x = @x + @r
    v3y = @y + @r
    Raylib.draw_triangle(v1x, v1y, v2x, v2y, v3x, v3y, @color)
  end
end

class Bullet
  attr_accessor :x, :y, :r, :speed, :color, :active

  def initialize(x, y)
    @x = x
    @y = y
    @r = 4
    @speed = 12.0
    @color = Raylib::YELLOW
    @active = true
  end

  def update
    @y -= @speed
    if @y < 0
      @active = false
    end
  end

  def draw
    Raylib.draw_circle(@x.to_i, @y.to_i, @r.to_i, @color)
  end
end

class Enemy
  attr_accessor :x, :y, :r, :speed_x, :speed_y, :type, :color, :active, :hp, :score

  def initialize
    @x = rand(700) + 50
    @y = -30
    types = [:square, :circle, :triangle]
    @type = types[rand(types.size)]
    @active = true
    
    case @type
    when :square
      @r = 20
      @speed_x = 0.0
      @speed_y = 2.0
      @color = Raylib::ORANGE
      @hp = 2
      @score = 20
    when :circle
      @r = 15
      @speed_x = (rand - 0.5) * 4.0
      @speed_y = 3.0
      @color = Raylib::CYAN
      @hp = 1
      @score = 10
    when :triangle
      @r = 18
      @speed_x = (rand - 0.5) * 2.0
      @speed_y = 4.0
      @color = Raylib::PURPLE
      @hp = 1
      @score = 15
    end
  end

  def update
    @x += @speed_x
    @y += @speed_y
    
    # 画面外で反射 (左右)
    if @x < @r || @x > 800 - @r
      @speed_x *= -1
    end

    if @y > 600 + @r
      @active = false
    end
  end

  def draw
    case @type
    when :square
      Raylib.draw_rectangle((@x - @r).to_i, (@y - @r).to_i, (@r * 2).to_i, (@r * 2).to_i, @color)
    when :circle
      Raylib.draw_circle(@x.to_i, @y.to_i, @r.to_i, @color)
    when :triangle
      # 下向きの三角形として描画
      v1x = @x
      v1y = @y + @r
      v2x = @x + @r
      v2y = @y - @r
      v3x = @x - @r
      v3y = @y - @r
      Raylib.draw_triangle(v1x, v1y, v2x, v2y, v3x, v3y, @color)
    end
  end
end

def main
  Raylib.init_window(800, 600, "Shooter - MRubySample")
  Raylib.set_target_fps(60)

  player = Player.new
  bullets = []
  enemies = []
  score = 0
  spawn_timer = 0
  
  state = :playing # :playing, :gameover

  while !Raylib.window_should_close()
    if state == :playing
      player.update(bullets)
      
      bullets.each { |b| b.update }
      
      new_bullets = []
      bullets.each { |b| new_bullets << b if b.active }
      bullets = new_bullets
      
      # 敵のスポーン
      spawn_timer += 1
      # スポーン頻度を計算（最小10フレーム間隔まで早くなる）
      spawn_interval = 40 - (score / 50)
      spawn_interval = 10 if spawn_interval < 10
      
      if spawn_timer > spawn_interval
        enemies << Enemy.new
        spawn_timer = 0
      end
      
      enemies.each { |e| e.update }

      new_enemies = []
      enemies.each { |e| new_enemies << e if e.active }
      enemies = new_enemies
      
      # 衝突判定
      enemies.each do |e|
        next unless e.active
        
        # プレイヤーと敵
        if circle_intersect?(player.x, player.y, player.r, e.x, e.y, e.r)
          state = :gameover
          break
        end
        
        # 弾と敵
        bullets.each do |b|
          next unless b.active
          if circle_intersect?(b.x, b.y, b.r, e.x, e.y, e.r)
            b.active = false
            e.hp -= 1
            if e.hp <= 0
              e.active = false
              score += e.score
            end
          end
        end
      end

    else
      # リザルト画面でEnterキーを押すとリスタート
      if Raylib.is_key_pressed(Raylib::KEY_ENTER)
        player = Player.new
        bullets = []
        enemies = []
        score = 0
        spawn_timer = 0
        state = :playing
      end
    end

    # --- 描画処理 ---
    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::BLACK)

    if state == :playing
      player.draw
      bullets.each { |b| b.draw }
      enemies.each { |e| e.draw }
      Raylib.draw_text("SCORE: #{score}", 10, 10, 20, Raylib::LIGHTGRAY)
    elsif state == :gameover
      Raylib.draw_text("GAME OVER", 280, 250, 40, Raylib::RED)
      Raylib.draw_text("SCORE: #{score}", 330, 310, 20, Raylib::LIGHTGRAY)
      Raylib.draw_text("Press ENTER to Restart", 280, 350, 20, Raylib::DARKGRAY)
    end

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
