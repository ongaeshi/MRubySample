def aabb_intersect?(x1, y1, w1, h1, x2, y2, w2, h2)
  x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
end

class Floor
  attr_reader :x, :y, :w, :h
  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end

  def draw
    Raylib.draw_rectangle(@x.to_i, @y.to_i, @w.to_i, @h.to_i, Raylib::DARKGRAY)
  end
end

def generate_floors
  floors = []
  num_floors = rand(3..5)
  
  width_per_floor = 800 / num_floors
  
  # 最初の床の基準高さ
  y_prev = 500
  
  num_floors.times do |i|
    # 隙間が広すぎるとクリア不可能になるため幅を調整
    max_w = width_per_floor - 10
    min_w = width_per_floor - 60
    min_w = 80 if min_w < 80
    w = rand(min_w..max_w)
    
    x = i * width_per_floor + (width_per_floor - w) / 2
    
    # 前の床から上下に最大80ピクセル程度の差にする
    y = y_prev + rand(-80..80)
    y = 350 if y < 350
    y = 550 if y > 550
    y_prev = y
    
    h = 600 - y
    floors << Floor.new(x, y, w, h)
  end
  floors
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

  def update(floors)
    # 移動
    if Raylib.is_key_down(Raylib::KEY_LEFT)
      @x -= @speed
    end
    if Raylib.is_key_down(Raylib::KEY_RIGHT)
      @x += @speed
    end

    # ジャンプ先行入力 (Jump Buffer)
    if Raylib.is_key_pressed(Raylib::KEY_SPACE) || Raylib.is_key_pressed(Raylib::KEY_UP)
      @jump_buffer = 8
    end

    if @jump_buffer > 0
      @jump_buffer -= 1
    end

    # ジャンプ実行 (コヨーテタイム)
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
    if @vy > 0
      floors.each do |floor|
        # プレイヤーが床の水平範囲内にいるか
        if @x + @w > floor.x && @x < floor.x + floor.w
          # プレイヤーの底面が床の上面を通過しようとしているか判定
          if @y + @h >= floor.y && @y + @h - @vy <= floor.y + 20
            @y = floor.y - @h
            @vy = 0.0
            @coyote_timer = 8
            break
          end
        end
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
      @vy = 1.5 + rand * 1.5
    else # :obstacle
      @w = 30
      @h = 30
      @color = Raylib::RED
      @vy = 4.0 + rand * 3.0
    end
    
    @x = rand(800 - @w)
    @y = -50
  end

  def update(floors)
    if @on_ground
      @lifetime -= 1
      if @lifetime <= 0
        @active = false
      end
    else
      @y += @vy
      
      # アイテムは床で止まる
      if @type == :item && @vy > 0
        floors.each do |floor|
          if @x + @w > floor.x && @x < floor.x + floor.w
            if @y + @h >= floor.y && @y + @h - @vy <= floor.y + 20
              @y = floor.y - @h
              @on_ground = true
              @lifetime = 180
              break
            end
          end
        end
      end

      if @y > 600
        @active = false
      end
    end
  end

  def draw
    if @type == :item && @on_ground && @lifetime < 60 && (@lifetime / 5) % 2 == 0
      return
    end

    if @type == :item
      Raylib.draw_circle((@x + @w / 2).to_i, (@y + @h / 2).to_i, (@w / 2).to_i, @color)
    else
      Raylib.draw_rectangle(@x.to_i, @y.to_i, @w.to_i, @h.to_i, @color)
    end
  end
end

def main
  Raylib.init_window(800, 600, "Random Terrain Jump Action - MRubySample")
  Raylib.set_target_fps(60)

  floors = generate_floors()
  player = Player.new
  # 最初の床の上にプレイヤーを配置
  player.x = floors[0].x + floors[0].w / 2 - player.w / 2
  player.y = floors[0].y - player.h - 50

  objects = []
  score = 0
  spawn_timer = 0
  state = :playing

  while !Raylib.window_should_close()
    if state == :playing
      player.update(floors)
      
      # 落下処理（穴に落ちたか）
      if player.y > 600
        state = :gameover
      end

      # オブジェクトの生成
      spawn_timer += 1
      interval = 40 - (score / 10)
      interval = 12 if interval < 12
      
      if spawn_timer > interval
        type = rand(100) < 40 ? :item : :obstacle
        objects << FallingObject.new(type)
        spawn_timer = 0
      end

      # オブジェクトの更新と当たり判定
      objects.each do |obj|
        obj.update(floors)
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
        # 床を再生成し、プレイヤーの位置をリセット
        floors = generate_floors()
        player = Player.new
        player.x = floors[0].x + floors[0].w / 2 - player.w / 2
        player.y = floors[0].y - player.h - 50
        
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
    floors.each { |f| f.draw }

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
