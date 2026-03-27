<br />
<div align="center">
  <h3 align="center">TinyWall (Fork)</h3>

  <p align="center">
    A free, lightweight and non-intrusive firewall
    <br />
    <a href="https://tinywall.pados.hu"><strong>Original Website »</strong></a>
  </p>
</div>

## About this fork

This is a fork of [TinyWall](https://github.com/pylorak/tinywall) by Károly Pados, designed to be **your personal, hackable Windows firewall**.

The idea is simple: clone the repo, open it with an AI coding assistant (Claude Code, GitHub Copilot, etc.), ask for whatever modifications you want, build, and install. That's it. The entire build and install flow requires only the .NET 9 SDK — no Visual Studio, no COM tooling, no WiX installer. Install and uninstall scripts are included in the release folder after building.

TinyWall is a solid, lightweight, non-intrusive firewall with a clean codebase — a great starting point to build whatever features fit your workflow. For example, the feature added in this fork is a regex-based auto-unblocker that matches executable paths. Yours can be anything.

### What changed from upstream

- **Modernized the build system**: Ported from .NET Framework 4.8 to .NET 9. Removed the dependency on Visual Studio, COM tooling, and WiX. Build with just `dotnet build`.
- **Simplified installation**: Install/uninstall scripts ship in the output folder — no separate installer project needed.
- **Cleaned up the codebase**: Replaced COM interop with dynamic COM, replaced `ManagedInstallerClass` with direct P/Invoke service management, fixed all nullable reference type warnings, and removed obsolete attributes.
- **Added regex auto-unblock**: Define patterns to automatically unblock matching executables, with per-pattern enable/disable control.

See [Changelog.txt](Changelog.txt) for full details.

## How to build

### Necessary tools

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)

### To build the application

```
dotnet build TinyWall/TinyWall.csproj -c Release
```

Output: `TinyWall/bin/Release/`

### To update/build the database of known applications

1. Adjust the individual JSON files in the `TinyWall\Database` folder.
1. Start the application with the `/develtool` flag.
1. Use the `Database creator` tab to create one combined database file in JSON format. The output file will be called `profiles.json`.
1. To use the new database in debug builds, copy the output file to the `TinyWall\bin\Debug` folder.

## Contributing

Contributions are welcome. If you have improvements, please fork the repo and create a pull request.

1. Fork the Project
1. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
1. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
1. Push to the Branch (`git push origin feature/AmazingFeature`)
1. Open a Pull Request

## License

- TaskDialog wrapper (code in directory `pylorak.Windows\TaskDialog`) written by KevinGre ([link](https://www.codeproject.com/Articles/17026/TaskDialog-for-WinForms)) and placed under Public Domain.
- All other code in the repository is under the GNU GPLv3 License. See `LICENSE.txt` for more information.

## Acknowledgments

Original project by Károly Pados:

Website: <https://tinywall.pados.hu>

GitHub: <https://github.com/pylorak/tinywall>
