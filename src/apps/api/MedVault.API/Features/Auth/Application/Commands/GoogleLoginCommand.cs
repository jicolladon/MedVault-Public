using MedVault.API.Common.CQRS;
using MedVault.API.Features.Auth.Application.DTOs;

namespace MedVault.API.Features.Auth.Application.Commands;

public record GoogleLoginCommand(string IdToken, string? IpAddress, string? UserAgent) : ICommand<GoogleLoginResponse>;

