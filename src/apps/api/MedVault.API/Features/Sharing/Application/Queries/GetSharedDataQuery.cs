using MedVault.API.Common.CQRS;
using MedVault.API.Features.Sharing.Application.DTOs;

namespace MedVault.API.Features.Sharing.Application.Queries;

public sealed record GetSharedDataQuery(
	string Token,
	string? AccessPassword = null,
	string? VerificationCode = null,
	Guid? AccessRequestId = null) : IQuery<SharedDataResponse>;

