namespace MedVault.ConsoleClient;

public static class ConsoleUI
{
    public static void WriteHeader(string title)
    {
        Console.WriteLine();
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine($"━━━ {title} ━━━");
        Console.ResetColor();
        Console.WriteLine();
    }

    public static void WriteSuccess(string message)
    {
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"  ✓ {message}");
        Console.ResetColor();
    }

    public static void WriteError(string message)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine($"  ✗ {message}");
        Console.ResetColor();
    }

    public static void WriteWarning(string message)
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine($"  ⚠ {message}");
        Console.ResetColor();
    }

    public static void WriteInfo(string message)
    {
        Console.WriteLine($"  {message}");
    }

    public static void WriteJson(string label, string json)
    {
        WriteSuccess(label);
        Console.WriteLine(json);
    }

    public static void WriteBanner(string medvaultApiUrl, string documentApiUrl)
    {
        Console.WriteLine("╔══════════════════════════════════════════════════════╗");
        Console.WriteLine("║   MedVault Auth Test — Interactive Console Client    ║");
        Console.WriteLine("╚══════════════════════════════════════════════════════╝");
        Console.WriteLine();
        Console.WriteLine($"  MedVault API:  {medvaultApiUrl}");
        Console.WriteLine($"  Document endpoints:  {documentApiUrl}");
        Console.WriteLine();
    }

    public static void WriteMainMenu(bool isAuthenticated)
    {
        Console.WriteLine();
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("┌─────────────────────────────────────────┐");
        Console.WriteLine("│             MAIN MENU                   │");
        Console.WriteLine("├─────────────────────────────────────────┤");
        Console.WriteLine("│  1. Google Login                        │");
        Console.WriteLine("│  2. Google Register                     │");
        Console.WriteLine("│  3. Email Register (PKCE)               │");
        Console.WriteLine("│  4. Email Login (PKCE)                  │");
        Console.WriteLine("│  5. Refresh Token                       │");
        Console.WriteLine("│  6. Get Session Status                  │");
        Console.WriteLine("│  7. Get /auth/me                        │");
        Console.WriteLine("│  8. Logout                              │");
        Console.WriteLine("│  9. Decode Current JWT                  │");
        Console.WriteLine("│ ───── Document Endpoints (API) ──────── │");
        Console.WriteLine("│ 10. GET /public  (no auth)              │");
        Console.WriteLine("│ 11. GET /data    (auth required)        │");
        Console.WriteLine("│ 12. GET /data/profile (auth required)   │");
        Console.WriteLine("│ 13. GET /data with invalid token        │");
        Console.WriteLine("│ ─────────────────────────────────────── │");
        Console.WriteLine("│  0. Exit                                │");
        Console.WriteLine("└─────────────────────────────────────────┘");
        Console.ResetColor();

        if (isAuthenticated)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("  [Authenticated ✓]");
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("  [Not Authenticated]");
        }
        Console.ResetColor();

        Console.Write("  Select option: ");
    }

    public static string Prompt(string label)
    {
        Console.Write($"  {label}: ");
        return Console.ReadLine()?.Trim() ?? string.Empty;
    }

    public static string PromptSecret(string label)
    {
        Console.Write($"  {label}: ");
        var password = new System.Text.StringBuilder();
        while (true)
        {
            var key = Console.ReadKey(intercept: true);
            if (key.Key == ConsoleKey.Enter) break;
            if (key.Key == ConsoleKey.Backspace && password.Length > 0)
            {
                password.Length--;
                Console.Write("\b \b");
            }
            else if (key.Key != ConsoleKey.Backspace)
            {
                password.Append(key.KeyChar);
                Console.Write('*');
            }
        }
        Console.WriteLine();
        return password.ToString();
    }

    public static void WriteStatusCode(int statusCode, string context)
    {
        var color = statusCode switch
        {
            >= 200 and < 300 => ConsoleColor.Green,
            >= 400 and < 500 => ConsoleColor.Yellow,
            _ => ConsoleColor.Red
        };
        Console.ForegroundColor = color;
        Console.WriteLine($"  {context}: {statusCode}");
        Console.ResetColor();
    }
}
