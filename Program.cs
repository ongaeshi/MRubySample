using System;
using System.IO;
using MRubyCS;
using MRubyCS.Compiler;

namespace MRubySample
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("=== C# ゲームエンジン(単独.exe)モックを起動 ===");

            // mruby VMの作成
            using var mrb = MRubyState.Create();
            var compiler = MRubyCompiler.Create(mrb);

            string scriptPath = "script.rb";
            Console.WriteLine($"[C#] {scriptPath} を読み込みます...");
            
            if (!File.Exists(scriptPath))
            {
                Console.WriteLine("script.rb が見つかりません。");
                return;
            }

            var source = File.ReadAllBytes(scriptPath);

            try
            {
                // Rubyスクリプトの実行（初期化）
                compiler.LoadSourceCode(source);
                Console.WriteLine("[C#] スクリプトのパース・実行が完了しました。");

                // C#からRubyの関数を呼び出す想定
                Console.WriteLine("[C#] Ruby側の関数 'on_update' を呼び出します...");
                
                // もっとも簡単な呼び出し方法は、再度スクリプトとして評価する方法です。
                // 引数なども文字列に埋め込んで呼び出すことができます。
                var result = compiler.LoadSourceCode("on_update(1.5)"u8);

                // 戻り値をC#のプリミティブ(float)として取り出す
                float returnVal = (float)mrb.AsFloat(result);
                Console.WriteLine($"[C#] Rubyからの戻り値: {returnVal}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[C#] 実行エラー: {ex.Message}");
            }
        }
    }
}
