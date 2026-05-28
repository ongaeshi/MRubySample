def aabb_intersect?(x1, y1, w1, h1, x2, y2, w2, h2)
  x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
end

class Player
  attr_accessor :x, :y, :w, :h, :vy, :speed, :color

  def initialize
    @w = 30
    @h = 30
    @x = 160
    @y = 500
    @vy = 0.0
    @speed = 6.0
    @color = Raylib::BLUE
    @coyote_timer = 0
    @jump_buffer = 0
  end

  def update
    # 移動
    if Raylib.is_key_down(Raylib::KEY_LEFT)
      @x -= @speed
    end
    if Raylib.is_key_down(Raylib::KEY_RIGHT)
      @x += @speed
    end

    # ジャンプ先行入力 (Jump Buffer: 着地数フレーム前に押してもジャンプが発動する)
    if Raylib.is_key_pressed(Raylib::KEY_SPACE) || Raylib.is_key_pressed(Raylib::KEY_UP)
      @jump_buffer = 8 # 8フレームの猶予
    end

    if @jump_buffer > 0
      @jump_buffer -= 1
    end

    # ジャンプ実行 (コヨーテタイム: 足場から落ちた直後数フレームはジャンプ可能)
    if @jump_buffer > 0 && @coyote_timer > 0
      @vy = -12.0
      @coyote_timer = 0
      @jump_buffer = 0
    end

    # 重力
    @vy += 0.5
    @y += @vy

    # 画面端の制限
    @x = 0 if @x < 0
    @x = 800 - @w if @x > 800 - @w

    if @coyote_timer > 0
      @coyote_timer -= 1
    end

    # 床との当たり判定
    floor_y = 550
    if @y + @h >= floor_y && @vy > 0
      on_left_floor = (@x + @w > 0 && @x < 350)
      on_right_floor = (@x + @w > 450 && @x < 800)

      if on_left_floor || on_right_floor
        @y = floor_y - @h
        @vy = 0.0
        @coyote_timer = 8 # 接地中は常にコヨーテタイムを最大値に保つ
      end
    end
  end

  def draw
    Raylib.draw_rectangle(@x.to_i, @y.to_i, @w.to_i, @h.to_i, @color)
  end
end

class FallingObject
  attr_accessor :x, :y, :w, :h, :vy, :type, :color, :active, :on_ground, :lifetime

  def initialize(type)
    @type = type
    @active = true
    @on_ground = false
    @lifetime = 0
    if type == :item
      @w = 20
      @h = 20
      @color = Raylib::ORANGE
      @vy = 1.5 + rand * 1.5 # アイテムはゆっくり落下
    else # :obstacle
      @w = 30
      @h = 30
      @color = Raylib::RED
      @vy = 4.0 + rand * 3.0
    end
    
    # 穴の真上（350〜450）も含むランダムなX座標に生成
    @x = rand(800 - @w)
    @y = -50
  end

  def update
    if @on_ground
      @lifetime -= 1
      if @lifetime <= 0
        @active = false
      end
    else
      @y += @vy
      
      # アイテムは床で止まる
      if @type == :item
        floor_y = 550
        if @y + @h >= floor_y
          on_left_floor = (@x + @w > 0 && @x < 350)
          on_right_floor = (@x + @w > 450 && @x < 800)
          
          if on_left_floor || on_right_floor
            @y = floor_y - @h
            @on_ground = true
            @lifetime = 180 # 3秒で消える
          end
        end
      end

      if @y > 600
        @active = false
      end
    end
  end

  def draw
    # 消滅間近の場合は点滅
    if @type == :item && @on_ground && @lifetime < 60 && (@lifetime / 5) % 2 == 0
      return
    end

    if @type == :item
      # 円として描画 (座標は中心)
      Raylib.draw_circle((@x + @w / 2).to_i, (@y + @h / 2).to_i, (@w / 2).to_i, @color)
    else
      # 四角として描画
      Raylib.draw_rectangle(@x.to_i, @y.to_i, @w.to_i, @h.to_i, @color)
    end
  end
end

def main
  Raylib.init_window(800, 600, "Jump Action - MRubySample")
  Raylib.set_target_fps(60)

  player = Player.new
  objects = []
  score = 0
  spawn_timer = 0
  state = :playing # :playing, :gameover

  while !Raylib.window_should_close()
    if state == :playing
      player.update
      
      # 落下処理（穴に落ちたか）
      if player.y > 600
        state = :gameover
      end

      # オブジェクトの生成
      spawn_timer += 1
      interval = 40 - (score / 10)
      interval = 12 if interval < 12
      
      if spawn_timer > interval
        type = rand(100) < 40 ? :item : :obstacle # 40%でアイテム、60%で障害物
        objects << FallingObject.new(type)
        spawn_timer = 0
      end

      # オブジェクトの更新と当たり判定
      objects.each do |obj|
        obj.update
        next unless obj.active

        if aabb_intersect?(player.x, player.y, player.w, player.h, obj.x, obj.y, obj.w, obj.h)
          if obj.type == :item
            score += 10
            obj.active = false
          else
            state = :gameover
          end
        end
      end

      # 不要なオブジェクトを削除
      new_objects = []
      objects.each { |o| new_objects << o if o.active }
      objects = new_objects

    else
      # ゲームオーバー時のリトライ
      if Raylib.is_key_pressed(Raylib::KEY_ENTER) || Raylib.is_key_pressed(Raylib::KEY_SPACE)
        player = Player.new
        objects = []
        score = 0
        spawn_timer = 0
        state = :playing
      end
    end

    # --- 描画処理 ---
    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::RAYWHITE)

    # 床の描画
    Raylib.draw_rectangle(0, 550, 350, 50, Raylib::DARKGRAY) # 左の床
    Raylib.draw_rectangle(450, 550, 350, 50, Raylib::DARKGRAY) # 右の床

    if state == :playing
      player.draw
      objects.each { |o| o.draw }
      Raylib.draw_text("SCORE: #{score}", 10, 10, 20, Raylib::BLACK)
    elsif state == :gameover
      Raylib.draw_text("GAME OVER", 280, 250, 40, Raylib::RED)
      Raylib.draw_text("SCORE: #{score}", 330, 310, 20, Raylib::DARKGRAY)
      Raylib.draw_text("Press ENTER or SPACE to Restart", 210, 350, 20, Raylib::DARKGRAY)
    end

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
