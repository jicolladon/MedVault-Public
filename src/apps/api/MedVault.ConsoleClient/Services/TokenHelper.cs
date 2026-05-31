using System.IdentityModel.Tokens.Jwt;

namespace MedVault.ConsoleClient.Services;

public static class TokenHelper
{
    public static void DisplayDecodedJwt(string jwt)
    {
        var handler = new JwtSecurityTokenHandler();
        if (!handler.CanReadToken(jwt))
        {
            ConsoleUI.WriteWarning("Token is not a valid JWT and cannot be decoded.");
            return;
        }

        var token = handler.ReadJwtToken(jwt);

        Console.WriteLine("  Header:");
        foreach (var header in token.Header)
            Console.WriteLine($"    {header.Key}: {header.Value}");

        Console.WriteLine();
        Console.WriteLine("  Payload:");
        foreach (var claim in token.Claims)
            Console.WriteLine($"    {claim.Type}: {claim.Value}");

        Console.WriteLine();
        Console.WriteLine($"  Valid From: {token.ValidFrom:u}");
        Console.WriteLine($"  Valid To:   {token.ValidTo:u}");
    }

    public static string Truncate(string value, int maxLength = 40)
    {
        return value.Length > maxLength ? value[..maxLength] + "..." : value;
    }
}
