using SoulsFormats;

namespace GraceLoadouts.Gen;

static class Program
{
    /// Elden Ring's Game folder: GRACELOADOUTS_GAME, else found through Steam's library list.
    /// Its event/msg/script folders must be unpacked (e.g. with UXM Selective Unpack).
    /// (merge sets it to the standalone menu folder instead.)
    public static string GameDir
    {
        get => gameDir ??= Environment.GetEnvironmentVariable("GRACELOADOUTS_GAME") ?? Steam.FindGameDir()
            ?? throw new Exception("Elden Ring not found; set GRACELOADOUTS_GAME to its ...\\ELDEN RING\\Game folder.");
        set => gameDir = value;
    }
    static string gameDir;
    public static string Root => root ??= FindRoot();
    static string root;

    /// Optional base layer (another mod's folder, e.g. Convergence or Seeker's Compass). When set,
    /// every input file the base provides replaces vanilla's, so the output is merged on top of it.
    public static string Base;

    /// An input file: from the base layer if it has one, else vanilla.
    public static string In(params string[] parts)
    {
        if (Base != null)
        {
            string b = Path.Combine(new[] { Base }.Concat(parts).ToArray());
            if (File.Exists(b)) return b;
        }
        return Path.Combine(new[] { GameDir }.Concat(parts).ToArray());
    }

    /// All input files in a folder: vanilla's, with the base layer's versions (and additions) winning.
    public static IEnumerable<string> InFiles(string pattern, params string[] dir)
    {
        var files = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var root in new[] { GameDir, Base })
        {
            if (root == null) continue;
            string d = Path.Combine(new[] { root }.Concat(dir).ToArray());
            if (!Directory.Exists(d)) continue;
            foreach (var f in Directory.GetFiles(d, pattern)) files[Path.GetFileName(f)] = f;
        }
        return files.Values.OrderBy(f => Path.GetFileName(f), StringComparer.OrdinalIgnoreCase);
    }

    static int Main(string[] args)
    {
        string cmd = args.Length > 0 ? args[0] : "build";
        // On players' PCs: the game's own Oodle (patched SoulsFormats), no project folder.
        if (cmd == "merge")
        {
            try { Merge.Run(args.Skip(1).ToArray()); return 0; }
            catch (Exception e) { Console.Error.WriteLine($"merge failed: {e.Message}"); return 1; }
        }

        // Unmodified SoulsFormats needed Oodle 8+ (ER's own oo2core_6 lacks an export it probed), so
        // the build borrows a newer copy: GRACELOADOUTS_OODLE, else any oo2core_8/9 shipped by an installed Steam game.
        if (!Directory.GetFiles(AppContext.BaseDirectory, "oo2core_*_win64.dll").Any(f => !f.Contains("oo2core_6")))
        {
            string src = Environment.GetEnvironmentVariable("GRACELOADOUTS_OODLE") ?? Steam.FindOodle()
                ?? throw new Exception("No oo2core_8/9_win64.dll found; set GRACELOADOUTS_OODLE to one (many Unreal/Steam games ship it).");
            File.Copy(src, Path.Combine(AppContext.BaseDirectory, Path.GetFileName(src)));
        }

        switch (cmd)
        {
            case "build": Builder.Run(args.Skip(1).ToArray()); return 0;
            case "freeflags": FlagScan.ReportFree(args.Skip(1).ToArray()); return 0;
            // Release zips: .NET (Core) always writes forward-slash entries, unlike Windows PowerShell 5.
            case "zip": if (File.Exists(args[2])) File.Delete(args[2]); System.IO.Compression.ZipFile.CreateFromDirectory(args[1], args[2], System.IO.Compression.CompressionLevel.Optimal, false); return 0;
            default: Console.Error.WriteLine($"unknown command {cmd}"); return 1;
        }
    }

    static string FindRoot()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir != null && !File.Exists(Path.Combine(dir.FullName, "DESIGN.md"))) dir = dir.Parent;
        return dir?.FullName ?? throw new Exception("GraceLoadouts root not found");
    }
}
