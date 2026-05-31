using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var medvaultApi = builder.AddProject<Projects.MedVault_API>("medvault-api");

builder.Build().Run();
