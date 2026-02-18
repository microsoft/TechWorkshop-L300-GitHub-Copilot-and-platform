# GitHub Copilot Instructions

## .NET Commands

When running any dotnet commands in the terminal locally on macOS, always prefix them with the PATH export:

```bash
export PATH="$HOME/.dotnet:$PATH" && dotnet <command>
```

This ensures the dotnet SDK is available in the PATH before executing any dotnet commands.

### Examples:
- `export PATH="$HOME/.dotnet:$PATH" && dotnet --list-sdks`
- `export PATH="$HOME/.dotnet:$PATH" && dotnet build`
- `export PATH="$HOME/.dotnet:$PATH" && dotnet run`
- `export PATH="$HOME/.dotnet:$PATH" && dotnet test`
