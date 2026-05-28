class Card
  attr_reader :suit, :rank

  def initialize(suit, rank)
    @suit = suit
    @rank = rank
  end

  def rank_str
    case @rank
    when 1 then "A"
    when 11 then "J"
    when 12 then "Q"
    when 13 then "K"
    else @rank.to_s
    end
  end

  def suit_str
    case @suit
    when :spade then "S"
    when :heart then "H"
    when :diamond then "D"
    when :club then "C"
    end
  end

  def color
    [:heart, :diamond].include?(@suit) ? Raylib::RED : Raylib::BLACK
  end

  def draw(x, y, face_up = true)
    w = 120
    h = 180
    
    # カードの背景
    Raylib.draw_rectangle(x, y, w, h, Raylib::RAYWHITE)
    Raylib.draw_rectangle_lines(x, y, w, h, Raylib::BLACK)
    
    if face_up
      # 表面の描画
      # 左上のランクとスート
      Raylib.draw_text(rank_str, x + 10, y + 10, 30, color)
      Raylib.draw_text(suit_str, x + 10, y + 40, 30, color)
      
      # 右下のランク
      Raylib.draw_text(rank_str, x + w - 30, y + h - 40, 30, color)
      
      # 中央のスート（大きく）
      Raylib.draw_text(suit_str, x + 40, y + 70, 60, color)
    else
      # 裏面の描画
      Raylib.draw_rectangle(x + 5, y + 5, w - 10, h - 10, Raylib::BLUE)
      Raylib.draw_rectangle_lines(x + 5, y + 5, w - 10, h - 10, Raylib::RAYWHITE)
    end
  end
end

class Deck
  def initialize
    @cards = []
    [:spade, :heart, :diamond, :club].each do |suit|
      (1..13).each do |rank|
        @cards << Card.new(suit, rank)
      end
    end
    
    # シャッフル (mruby環境でArray#shuffleがない場合を考慮し自前で実装)
    n = @cards.length
    (0...n).each do |i|
      j = rand(n)
      tmp = @cards[i]
      @cards[i] = @cards[j]
      @cards[j] = tmp
    end
  end
  
  def pop
    @cards.pop
  end
  
  def empty?
    @cards.empty?
  end
  
  def cards_left
    @cards.length
  end
end

def main
  Raylib.init_window(800, 600, "High & Low - MRubySample")
  Raylib.set_target_fps(60)

  state = :title
  score = 0
  deck = nil
  card1 = nil
  card2 = nil
  message = ""

  while !Raylib.window_should_close()
    # --- 更新処理 ---
    if state == :title
      if Raylib.is_key_pressed(Raylib::KEY_SPACE)
        deck = Deck.new
        card1 = deck.pop
        card2 = deck.pop
        score = 0
        state = :playing
      end
    elsif state == :playing
      if Raylib.is_key_pressed(Raylib::KEY_UP)
        if card2.rank >= card1.rank
          score += 1
          message = "Correct! (High or Same)"
        else
          message = "Wrong! It was Low."
        end
        state = :reveal
      elsif Raylib.is_key_pressed(Raylib::KEY_DOWN)
        if card2.rank <= card1.rank
          score += 1
          message = "Correct! (Low or Same)"
        else
          message = "Wrong! It was High."
        end
        state = :reveal
      end
    elsif state == :reveal
      if Raylib.is_key_pressed(Raylib::KEY_SPACE)
        if message.include?("Correct")
          if deck.empty?
            message = "You Win! Deck is empty."
            state = :gameover
          else
            card1 = card2
            card2 = deck.pop
            state = :playing
          end
        else
          state = :gameover
        end
      end
    elsif state == :gameover
      if Raylib.is_key_pressed(Raylib::KEY_ENTER)
        state = :title
      end
    end

    # --- 描画処理 ---
    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::DARKGRAY)

    if state == :title
      Raylib.draw_text("High & Low", 260, 200, 50, Raylib::RAYWHITE)
      Raylib.draw_text("Press SPACE to Start", 280, 300, 25, Raylib::LIGHTGRAY)
    else
      # UI描画
      Raylib.draw_text("Score: #{score}", 20, 20, 30, Raylib::RAYWHITE)
      cards_left_text = deck ? deck.cards_left.to_s : "0"
      Raylib.draw_text("Cards left: #{cards_left_text}", 600, 20, 20, Raylib::LIGHTGRAY)

      # カード描画
      if state == :playing || state == :reveal || state == :gameover
        if card1
          card1.draw(220, 200, true)
        end
        
        if card2
          face_up = (state == :reveal || state == :gameover)
          card2.draw(460, 200, face_up)
        end

        Raylib.draw_text("VS", 380, 270, 40, Raylib::YELLOW)
      end

      # 状態に応じたテキスト描画
      if state == :playing
        Raylib.draw_text("UP Arrow : High (or Same)", 250, 440, 25, Raylib::CYAN)
        Raylib.draw_text("DOWN Arrow: Low (or Same)", 250, 480, 25, Raylib::CYAN)
      elsif state == :reveal
        color = message.include?("Correct") ? Raylib::GREEN : Raylib::RED
        Raylib.draw_text(message, 250, 440, 30, color)
        Raylib.draw_text("Press SPACE to continue", 280, 490, 20, Raylib::LIGHTGRAY)
      elsif state == :gameover
        Raylib.draw_text("GAME OVER", 300, 100, 40, Raylib::RED)
        color = message.include?("You Win") ? Raylib::YELLOW : Raylib::RED
        Raylib.draw_text(message, 250, 440, 30, color)
        Raylib.draw_text("Press ENTER to return to Title", 220, 490, 25, Raylib::LIGHTGRAY)
      end
    end

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
