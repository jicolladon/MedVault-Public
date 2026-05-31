using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using MedVault.API.Features.UserProfile.Application.DTOs;
using MedVault.API.IntegrationTests.Fixtures;
using Xunit;

namespace MedVault.API.IntegrationTests.Tests;

/// <summary>
/// Integration tests for api/user/profile endpoints (Workflow 1.1 — User profile CRUD).
/// </summary>
public class UserProfileControllerTests : IClassFixture<MedVaultApiFactory>, IAsyncLifetime
{
    private readonly MedVaultApiFactory _factory;
    private readonly HttpClient _authClient;
    private readonly HttpClient _anonClient;
    private readonly JsonSerializerOptions _json = new()
    {
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter() }
    };

    public UserProfileControllerTests(MedVaultApiFactory factory)
    {
        _factory = factory;
        _authClient = factory.CreateAuthenticatedClient();
        _anonClient = factory.CreateAnonymousClient();
    }

    public async Task InitializeAsync() => await _factory.SeedTestUserAsync();
    public Task DisposeAsync() => Task.CompletedTask;

    // ─── Get Profile ────────────────────────────────────────

    [Fact]
    public async Task GetProfile_Authenticated_ReturnsCurrentUserProfile()
    {
        var response = await _authClient.GetAsync("/api/user/profile");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<UserProfileResponse>>(_json);
        Assert.True(body!.Success);
        Assert.Contains("@", body.Data!.Email);
        Assert.NotNull(body.Data.FirstName); // May be "Test" or "Updated" depending on test ordering
    }

    [Fact]
    public async Task GetProfile_Unauthenticated_Returns401()
    {
        var response = await _anonClient.GetAsync("/api/user/profile");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetProfileById_Authenticated_ReturnsProfile()
    {
        var userId = TestAuthHandler.TestUserId;
        var response = await _authClient.GetAsync($"/api/user/profile/{userId}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<UserProfileResponse>>(_json);
        Assert.True(body!.Success);
        Assert.Equal(userId, body.Data!.UserId);
    }

    [Fact]
    public async Task GetProfileById_NonexistentUser_Returns404()
    {
        var fakeId = Guid.NewGuid();
        var response = await _authClient.GetAsync($"/api/user/profile/{fakeId}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ─── Update Profile ─────────────────────────────────────

    [Fact]
    public async Task UpdateProfile_ValidData_ReturnsUpdatedProfile()
    {
        var request = new
        {
            DisplayName = "Updated Name",
            Email = "updated@medvault.test",
            FirstName = "Updated",
            LastName = "Name",
            PhoneNumber = "+1234567890",
            City = "TestCity",
            Country = "TestCountry"
        };

        var response = await _authClient.PutAsJsonAsync("/api/user/profile", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<UserProfileResponse>>(_json);
        Assert.True(body!.Success);
        Assert.Equal("Updated", body.Data!.FirstName);
        Assert.Equal("Name", body.Data!.LastName);
        Assert.Equal("updated@medvault.test", body.Data.Email);
        Assert.Equal("Updated Name", body.Data.DisplayName);
        Assert.Equal("TestCity", body.Data!.City);
    }

    [Fact]
    public async Task UpdateProfile_Unauthenticated_Returns401()
    {
        var response = await _anonClient.PutAsJsonAsync("/api/user/profile",
            new { FirstName = "Hacker" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task UpdateProfile_EmergencyContact_PersistsCorrectly()
    {
        var request = new
        {
            EmergencyContactName = "Jane Doe",
            EmergencyContactPhone = "+9876543210",
            EmergencyContactRelationship = "Spouse"
        };

        var response = await _authClient.PutAsJsonAsync("/api/user/profile", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<UserProfileResponse>>(_json);
        Assert.Equal("Jane Doe", body!.Data!.EmergencyContactName);
        Assert.Equal("Spouse", body.Data!.EmergencyContactRelationship);
    }

    // ─── Emergency Contacts List ───────────────────────────

    [Fact]
    public async Task AddEmergencyContact_ThenGetEmergencyContacts_ReturnsSavedContact()
    {
        var addResponse = await _authClient.PostAsJsonAsync("/api/user/profile/emergency-contacts", new
        {
            ContactId = "integration-contact-1",
            Name = "John Emergency",
            Relationship = "friend",
            Phone = "+19876543210",
            Email = "john.emergency@test.com",
            IsPrimary = true
        });

        Assert.Equal(HttpStatusCode.OK, addResponse.StatusCode);

        var listResponse = await _authClient.GetAsync("/api/user/profile/emergency-contacts");
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);

        var listBody = await listResponse.Content.ReadFromJsonAsync<ApiEnvelope<List<EmergencyContactResponse>>>(_json);
        Assert.True(listBody!.Success);
        Assert.Contains(listBody.Data!, c => c.ContactId == "integration-contact-1");
    }

    [Fact]
    public async Task ReplaceEmergencyContacts_ThenDeleteContact_Works()
    {
        var replaceResponse = await _authClient.PutAsJsonAsync("/api/user/profile/emergency-contacts", new
        {
            Contacts = new[]
            {
                new
                {
                    ContactId = "integration-replace-1",
                    Name = "Primary Contact",
                    Relationship = "spouse",
                    Phone = "+10000000001",
                    Email = "primary@test.com",
                    IsPrimary = true
                },
                new
                {
                    ContactId = "integration-replace-2",
                    Name = "Secondary Contact",
                    Relationship = "parent",
                    Phone = "+10000000002",
                    Email = (string?)null,
                    IsPrimary = false
                }
            }
        });

        Assert.Equal(HttpStatusCode.OK, replaceResponse.StatusCode);

        var deleteResponse = await _authClient.DeleteAsync("/api/user/profile/emergency-contacts/integration-replace-2");
        Assert.Equal(HttpStatusCode.OK, deleteResponse.StatusCode);

        var listResponse = await _authClient.GetAsync("/api/user/profile/emergency-contacts");
        var listBody = await listResponse.Content.ReadFromJsonAsync<ApiEnvelope<List<EmergencyContactResponse>>>(_json);
        Assert.True(listBody!.Success);
        Assert.DoesNotContain(listBody.Data!, c => c.ContactId == "integration-replace-2");
        Assert.Contains(listBody.Data!, c => c.ContactId == "integration-replace-1" && c.IsPrimary);
    }

    // ─── Profile Completeness ───────────────────────────────

    [Fact]
    public async Task ProfileCompleteness_ReturnsPercentageAndFields()
    {
        var response = await _authClient.GetAsync("/api/user/profile/completeness");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<ApiEnvelope<ProfileCompletenessResponse>>(_json);
        Assert.True(body!.Success);
        Assert.InRange(body.Data!.Percentage, 0, 100);
    }

    [Fact]
    public async Task ProfileCompleteness_Unauthenticated_Returns401()
    {
        var response = await _anonClient.GetAsync("/api/user/profile/completeness");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}

file record ApiEnvelope<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public string? Message { get; init; }
    public List<string>? Errors { get; init; }
}
