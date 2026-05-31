using MedVault.API.Common.CQRS;
using MedVault.API.Features.Auth.Application.DTOs;

namespace MedVault.API.Features.Auth.Application.Queries;

public record GetSessionStatusQuery(Guid UserId) : IQuery<SessionStatusDto?>;

