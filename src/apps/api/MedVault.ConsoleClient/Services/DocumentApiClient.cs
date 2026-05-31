using System.Net.Http.Headers;
using System.Text.Json;

namespace MedVault.ConsoleClient.Services;

public sealed class DocumentApiClient : IDisposable
{
    private readonly HttpClient _http;
    private readonly JsonSerializerOptions _json;

    public DocumentApiClient(string baseUrl)
    {
        _http = new HttpClient
        {
            BaseAddress = new Uri(baseUrl)
        };
        _json = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            WriteIndented = true
        };
    }

    public void SetBearerToken(string token)
    {
        _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }

    public void ClearBearerToken()
    {
        _http.DefaultRequestHeaders.Authorization = null;
    }

    public async Task<(int StatusCode, string Body)> GetPublicAsync()
    {
        var response = await _http.GetAsync("/public");
        var body = await response.Content.ReadAsStringAsync();
        return ((int)response.StatusCode, FormatJson(body));
    }

    public async Task<(int StatusCode, string Body)> GetDataAsync()
    {
        var response = await _http.GetAsync("/data");
        var body = await response.Content.ReadAsStringAsync();
        return ((int)response.StatusCode, FormatJson(body));
    }

    public async Task<(int StatusCode, string Body)> GetDataProfileAsync()
    {
        var response = await _http.GetAsync("/data/profile");
        var body = await response.Content.ReadAsStringAsync();
        return ((int)response.StatusCode, FormatJson(body));
    }

    public async Task<(int StatusCode, string Body)> GetDataWithInvalidTokenAsync()
    {
        using var badClient = new HttpClient { BaseAddress = _http.BaseAddress };
        badClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "invalid.token.here");
        var response = await badClient.GetAsync("/data");
        var body = await response.Content.ReadAsStringAsync();
        return ((int)response.StatusCode, body);
    }

    private string FormatJson(string raw)
    {
        try
        {
            var element = JsonSerializer.Deserialize<JsonElement>(raw);
            return JsonSerializer.Serialize(element, _json);
        }
        catch
        {
            return raw;
        }
    }

    public void Dispose() => _http.Dispose();
}
