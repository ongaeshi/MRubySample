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
            Console.WriteLine("=== MRubyCS + Raylib-cs モック ===");

            using var mrb = MRubyState.Create();
            var compiler = MRubyCompiler.Create(mrb);

            string scriptPath = "script.rb";
            if (!File.Exists(scriptPath))
            {
                Console.WriteLine("script.rb が見つかりません。");
                return;
            }

            // Rubyスクリプトの初期化
            compiler.LoadSourceCode(File.ReadAllBytes(scriptPath));

            // Raylibの初期化
            Raylib.InitWindow(800, 600, "MRubyCS + Raylib-cs Engine");
            Raylib.SetTargetFPS(60);

            while (!Raylib.WindowShouldClose())
            {
                // 入力取得
                bool up = Raylib.IsKeyDown(KeyboardKey.Up);
                bool down = Raylib.IsKeyDown(KeyboardKey.Down);
                bool left = Raylib.IsKeyDown(KeyboardKey.Left);
                bool right = Raylib.IsKeyDown(KeyboardKey.Right);

                // Ruby側を更新
                // 簡単のために文字列として式を生成して評価します
                string rbCode = $"update_player({up.ToString().ToLower()}, {down.ToString().ToLower()}, {left.ToString().ToLower()}, {right.ToString().ToLower()})";
                compiler.LoadSourceCode(rbCode);

                // Ruby側から座標を取得
                float px = (float)mrb.AsFloat(compiler.LoadSourceCode("get_player_x"u8));
                float py = (float)mrb.AsFloat(compiler.LoadSourceCode("get_player_y"u8));

                // 描画
                Raylib.BeginDrawing();
                Raylib.ClearBackground(Color.RayWhite);

                // Ruby側で計算された座標(px, py)を使って四角形を描画
                Raylib.DrawRectangle((int)px, (int)py, 50, 50, Color.Blue);
                Raylib.DrawText("Move with Arrow Keys. Logic is in Ruby!", 10, 10, 20, Color.DarkGray);

                Raylib.EndDrawing();
            }

            Raylib.CloseWindow();
        }
    }
}
