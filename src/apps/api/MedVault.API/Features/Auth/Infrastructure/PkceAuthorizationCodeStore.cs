using Microsoft.Extensions.Caching.Memory;
using MedVault.API.Features.Auth.Application.Interfaces;

namespace MedVault.API.Features.Auth.Infrastructure;

public class PkceAuthorizationCodeStore : IPkceAuthorizationCodeStore
{
    private const string Prefix = "pkce_auth_code:";
    private static readonly TimeSpan CodeTtl = TimeSpan.FromMinutes(5);
    private readonly IMemoryCache _cache;

    public PkceAuthorizationCodeStore(IMemoryCache cache)
    {
        _cache = cache;
    }

    public string CreateCode(PkceAuthorizationCodeRecord record)
    {
        var bytes = Guid.NewGuid().ToByteArray();
        var authorizationCode = Convert.ToBase64String(bytes)
            .Replace("+", "-")
            .Replace("/", "_")
            .TrimEnd('=');

        _cache.Set(Prefix + authorizationCode, record, CodeTtl);
        return authorizationCode;
    }

    public bool TryRedeemCode(string authorizationCode, out PkceAuthorizationCodeRecord? record)
    {
        var key = Prefix + authorizationCode;
        if (_cache.TryGetValue(key, out PkceAuthorizationCodeRecord? cached) && cached is not null)
        {
            _cache.Remove(key);
            record = cached;
            return true;
        }

        record = null;
        return false;
    }
}

