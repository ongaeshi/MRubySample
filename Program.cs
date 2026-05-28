using System;
using System.IO;
using MRubyCS;
using MRubyCS.Compiler;
using Raylib_cs;

namespace MRubySample
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("=== MRubyCS + Raylib-cs Engine ===");

            using var mrb = MRubyState.Create();
            var compiler = MRubyCompiler.Create(mrb);

            // Raylibモジュールを定義
            var raylibMod = mrb.DefineModule(mrb.Intern("Raylib"u8), opt => {});

            mrb.DefineClassMethod(raylibMod, mrb.Intern("init_window"u8), (state, self) => {
                int w = (int)state.GetArgumentAsIntegerAt(0);
                int h = (int)state.GetArgumentAsIntegerAt(1);
                string title = state.GetArgumentAsStringAt(2).ToString();
                Raylib.InitWindow(w, h, title);
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("set_target_fps"u8), (state, self) => {
                int fps = (int)state.GetArgumentAsIntegerAt(0);
                Raylib.SetTargetFPS(fps);
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("window_should_close"u8), (state, self) => {
                return Raylib.WindowShouldClose() ? MRubyValue.True : MRubyValue.False;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("close_window"u8), (state, self) => {
                Raylib.CloseWindow();
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("begin_drawing"u8), (state, self) => {
                Raylib.BeginDrawing();
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("end_drawing"u8), (state, self) => {
                Raylib.EndDrawing();
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("is_key_down"u8), (state, self) => {
                int key = (int)state.GetArgumentAsIntegerAt(0);
                return Raylib.IsKeyDown((KeyboardKey)key) ? MRubyValue.True : MRubyValue.False;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("is_key_pressed"u8), (state, self) => {
                int key = (int)state.GetArgumentAsIntegerAt(0);
                return Raylib.IsKeyPressed((KeyboardKey)key) ? MRubyValue.True : MRubyValue.False;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("clear_background_raw"u8), (state, self) => {
                byte r = (byte)state.GetArgumentAsIntegerAt(0);
                byte g = (byte)state.GetArgumentAsIntegerAt(1);
                byte b = (byte)state.GetArgumentAsIntegerAt(2);
                byte a = (byte)state.GetArgumentAsIntegerAt(3);
                Raylib.ClearBackground(new Color(r, g, b, a));
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("draw_rectangle_raw"u8), (state, self) => {
                int x = (int)state.GetArgumentAsIntegerAt(0);
                int y = (int)state.GetArgumentAsIntegerAt(1);
                int w = (int)state.GetArgumentAsIntegerAt(2);
                int h = (int)state.GetArgumentAsIntegerAt(3);
                byte r = (byte)state.GetArgumentAsIntegerAt(4);
                byte g = (byte)state.GetArgumentAsIntegerAt(5);
                byte b = (byte)state.GetArgumentAsIntegerAt(6);
                byte a = (byte)state.GetArgumentAsIntegerAt(7);
                Raylib.DrawRectangle(x, y, w, h, new Color(r, g, b, a));
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("draw_rectangle_lines_raw"u8), (state, self) => {
                int x = (int)state.GetArgumentAsIntegerAt(0);
                int y = (int)state.GetArgumentAsIntegerAt(1);
                int w = (int)state.GetArgumentAsIntegerAt(2);
                int h = (int)state.GetArgumentAsIntegerAt(3);
                byte r = (byte)state.GetArgumentAsIntegerAt(4);
                byte g = (byte)state.GetArgumentAsIntegerAt(5);
                byte b = (byte)state.GetArgumentAsIntegerAt(6);
                byte a = (byte)state.GetArgumentAsIntegerAt(7);
                Raylib.DrawRectangleLines(x, y, w, h, new Color(r, g, b, a));
                return MRubyValue.Nil;
            });

            mrb.DefineClassMethod(raylibMod, mrb.Intern("draw_text_raw"u8), (state, self) => {
                string text = state.GetArgumentAsStringAt(0).ToString();
                int x = (int)state.GetArgumentAsIntegerAt(1);
                int y = (int)state.GetArgumentAsIntegerAt(2);
                int size = (int)state.GetArgumentAsIntegerAt(3);
                byte r = (byte)state.GetArgumentAsIntegerAt(4);
                byte g = (byte)state.GetArgumentAsIntegerAt(5);
                byte b = (byte)state.GetArgumentAsIntegerAt(6);
                byte a = (byte)state.GetArgumentAsIntegerAt(7);
                Raylib.DrawText(text, x, y, size, new Color(r, g, b, a));
                return MRubyValue.Nil;
            });

            // ruby側でユーティリティメソッドを定義
            string rbHelpers = @"
module Raylib
  KEY_RIGHT = 262
  KEY_LEFT = 263
  KEY_DOWN = 264
  KEY_UP = 265
  KEY_SPACE = 32
  KEY_Z = 90
  KEY_X = 88
  KEY_ENTER = 257
  
  RAYWHITE = [245, 245, 245, 255]
  BLACK = [0, 0, 0, 255]
  DARKGRAY = [80, 80, 80, 255]
  LIGHTGRAY = [200, 200, 200, 255]
  RED = [230, 41, 55, 255]
  GREEN = [0, 228, 48, 255]
  BLUE = [0, 121, 241, 255]
  ORANGE = [255, 161, 0, 255]
  YELLOW = [253, 249, 0, 255]
  PURPLE = [200, 122, 255, 255]
  CYAN = [0, 255, 255, 255]

  def self.clear_background(color)
    clear_background_raw(color[0], color[1], color[2], color[3])
  end

  def self.draw_rectangle(x, y, w, h, color)
    draw_rectangle_raw(x, y, w, h, color[0], color[1], color[2], color[3])
  end

  def self.draw_rectangle_lines(x, y, w, h, color)
    draw_rectangle_lines_raw(x, y, w, h, color[0], color[1], color[2], color[3])
  end

  def self.draw_text(text, x, y, size, color)
    draw_text_raw(text, x, y, size, color[0], color[1], color[2], color[3])
  end
end
";
            compiler.LoadSourceCode(rbHelpers);

            string scriptPath = "script.rb";
            if (!File.Exists(scriptPath))
            {
                Console.WriteLine("script.rb が見つかりません。");
                return;
            }

            try 
            {
                // script.rb を読み込んで実行（内部でループが回る想定）
                compiler.LoadSourceCode(File.ReadAllBytes(scriptPath));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ruby Script Error: {ex.Message}");
            }
        }
    }
}
