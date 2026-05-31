namespace MedVault.API.Features.Shared.Domain;

public enum Gender
{
    Male,
    Female,
    Other,
    PreferNotToSay
}

public static class GenderExtensions
{
    public static Gender? ToGender(this string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim() switch
        {
            nameof(Gender.Male) => Gender.Male,
            nameof(Gender.Female) => Gender.Female,
            nameof(Gender.Other) => Gender.Other,
            nameof(Gender.PreferNotToSay) => Gender.PreferNotToSay,
            "Prefer not to say" => Gender.PreferNotToSay,
            "prefer-not-to-say" => Gender.PreferNotToSay,
            _ => Enum.TryParse<Gender>(value, ignoreCase: true, out var gender)
                ? gender
                : null,
        };
    }
}
