namespace GraceLoadouts.Gen;

/// Rebuilds the menu files on top of another mod's, on a player's PC (the installers run this as
/// GraceLoadouts-merge.exe). Players don't have the game's files unpacked, so instead of vanilla
/// the fallback is the standalone menu shipped in the zip (vanilla plus our lines): every menu file
/// the base mod has is patched from the base's copy, every other one is the standalone copy.
/// Usage: merge --base <mod folder> --standalone <folder> --out <folder> [--game <Game folder>]
static class Merge
{
    public static void Run(string[] args)
    {
        string Arg(string name)
        {
            int i = Array.IndexOf(args, name);
            return i >= 0 && i + 1 < args.Length ? Path.GetFullPath(args[i + 1]) : null;
        }
        string baseDir = Arg("--base") ?? throw new Exception("--base is required");
        string standalone = Arg("--standalone") ?? throw new Exception("--standalone is required");
        string outDir = Arg("--out") ?? throw new Exception("--out is required");
        // The game's own oo2core_6 is the one Oodle every player has.
        string game = Arg("--game") ?? Steam.FindGameDir() ?? throw new Exception("Elden Ring not found; pass --game <...\\ELDEN RING\\Game>.");
        SoulsFormats.Oodle.SearchPaths.Add(game);

        if (!File.Exists(Path.Combine(standalone, "script", "talk", "m00_00_00_00.talkesdbnd.dcx")))
            throw new Exception($"{standalone} is not the standalone menu folder");
        Program.GameDir = standalone;
        Program.Base = baseDir;

        // Start from a fresh copy of the standalone menu, so files the base dropped don't linger.
        if (Directory.Exists(outDir)) Directory.Delete(outDir, true);
        foreach (var f in Directory.GetFiles(standalone, "*", SearchOption.AllDirectories))
        {
            string to = Path.Combine(outDir, Path.GetRelativePath(standalone, f));
            Directory.CreateDirectory(Path.GetDirectoryName(to));
            File.Copy(f, to);
        }

        int patched = 0;
        foreach (var lang in Texts.Languages())
        {
            var talkText = GraceMenu.Texts(new Texts(lang));
            foreach (var bnd in Builder.MenuBnds)
            {
                string from = Path.Combine(baseDir, "msg", lang, bnd);
                if (!File.Exists(from)) continue;
                Directory.CreateDirectory(Path.Combine(outDir, "msg", lang));
                Builder.PatchFmgs(from, Path.Combine(outDir, "msg", lang, bnd), fmg => fmg == "EventTextForTalk" ? talkText : null);
                patched++;
            }
        }
        bool talk = File.Exists(Path.Combine(baseDir, "script", "talk", "m00_00_00_00.talkesdbnd.dcx"));
        if (talk) GraceMenu.Build(outDir);
        Console.WriteLine($"merged onto {baseDir}: {patched} text files{(talk ? " and the grace menu" : "")}");
    }
}
