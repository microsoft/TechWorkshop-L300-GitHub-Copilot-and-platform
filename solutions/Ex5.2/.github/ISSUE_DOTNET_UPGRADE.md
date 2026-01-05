# Update .NET from 6.0 to 10 LTS

## Overview
Update the ZavaStorefront application from .NET 6.0 to .NET 10 (current LTS version as of December 2025). .NET 6.0 reaches end of support in November 2024, making this upgrade critical for continued security updates and performance improvements.

## Benefits
- **Extended Support**: .NET 10 LTS is supported until November 2028
- **Performance**: Significant performance improvements in runtime, libraries, and garbage collection
- **Security**: Latest security patches and features
- **Modern Features**: Access to newest C# language features and framework capabilities
- **Compatibility**: Better compatibility with modern Azure services and tools

## Files Requiring Updates

### Application Code
- [ ] `src/ZavaStorefront.csproj` - Update `<TargetFramework>` from `net6.0` to `net10.0`

### Docker Configuration
- [ ] `Dockerfile` - Update base images:
  - Build stage: `mcr.microsoft.com/dotnet/sdk:6.0` → `mcr.microsoft.com/dotnet/sdk:10.0`
  - Runtime stage: `mcr.microsoft.com/dotnet/aspnet:6.0` → `mcr.microsoft.com/dotnet/aspnet:10.0`

### Documentation
- [ ] `README.md` - Update version references from .NET 6.0 to .NET 10
- [ ] `DEPLOYMENT_SUMMARY.md` - Update all .NET 6.0 references to .NET 10
- [ ] `src/README.md` - Update technology stack section

## Testing Checklist
- [ ] Application builds successfully with .NET 10 SDK
- [ ] Docker image builds without errors
- [ ] Application runs locally (test with `dotnet run`)
- [ ] All existing functionality works correctly
- [ ] No breaking changes in dependencies
- [ ] GitHub Actions workflow completes successfully
- [ ] Application deploys to Azure successfully
- [ ] Application runs correctly in Azure App Service

## Implementation Steps

1. **Update Project File**
   ```bash
   # Edit src/ZavaStorefront.csproj
   # Change <TargetFramework>net6.0</TargetFramework> to <TargetFramework>net10.0</TargetFramework>
   ```

2. **Update Dockerfile**
   ```dockerfile
   # Build stage - change FROM line
   FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
   
   # Runtime stage - change FROM line
   FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
   ```

3. **Test Locally**
   ```bash
   cd src
   dotnet restore
   dotnet build
   dotnet run
   # Navigate to https://localhost:7060 to verify
   ```

4. **Build Docker Image**
   ```bash
   docker build -t zavastore:latest -f Dockerfile ./src
   docker run -p 8080:80 zavastore:latest
   # Navigate to http://localhost:8080 to verify
   ```

5. **Update Documentation**
   - Search for ".NET 6" or "net6.0" references in all markdown files
   - Update to ".NET 10" or "net10.0" as appropriate
   - Files to check:
     - `README.md`
     - `DEPLOYMENT_SUMMARY.md`
     - `src/README.md`
     - Documentation files in `docs/` folder

6. **Deploy and Verify**
   - Commit changes to a feature branch
   - Push to GitHub to trigger CI/CD pipeline
   - Verify successful build in GitHub Actions
   - Create PR and merge to main
   - Verify successful deployment to Azure
   - Perform smoke tests on deployed application

## Breaking Changes to Review
- Review the [.NET 10 breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/10.0)
- Check for any deprecated APIs or changed behaviors
- Review NuGet package compatibility
- Test all controller actions
- Verify middleware pipeline works correctly
- Check for any ASP.NET Core breaking changes

## Dependencies
- Ensure development machine has .NET 10 SDK installed:
  ```bash
  dotnet --list-sdks
  # Should show 10.x.x version
  ```
- Verify Azure App Service supports .NET 10 runtime
- Check all NuGet packages for .NET 10 compatibility (none currently in project)

## Potential Issues
- **Azure App Service**: Ensure the Linux App Service plan supports .NET 10
- **Docker Base Images**: Verify the .NET 10 images are available and stable
- **Breaking Changes**: Review ASP.NET Core 10 migration guide for any breaking changes
- **Performance**: Monitor performance metrics post-upgrade

## Acceptance Criteria
- ✅ All code compiles with .NET 10 SDK without warnings
- ✅ Docker image builds successfully
- ✅ Application runs without errors locally
- ✅ All application features work correctly (navigation, pages load)
- ✅ GitHub Actions workflow completes successfully
- ✅ Application deploys to Azure successfully
- ✅ Application runs correctly in Azure App Service
- ✅ All documentation updated
- ✅ No regressions in functionality or performance

## Priority
**HIGH** - .NET 6.0 is out of support as of November 2024; upgrade needed for security patches and performance improvements.

## Labels
`enhancement`, `infrastructure`, `security`, `priority-high`

## References
- [.NET 10 Release Notes](https://github.com/dotnet/core/tree/main/release-notes/10.0)
- [Migrating from .NET 6 to .NET 10](https://learn.microsoft.com/en-us/dotnet/core/porting/)
- [ASP.NET Core 10.0 Migration](https://learn.microsoft.com/en-us/aspnet/core/migration/60-to-70)
- [Azure App Service .NET Support](https://learn.microsoft.com/en-us/azure/app-service/)
- [.NET Support Policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)

## Estimated Effort
**2-4 hours** - Low complexity upgrade with minimal code changes required. Most time will be spent on testing and documentation updates.
