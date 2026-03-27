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

This is a fork of [TinyWall](https://github.com/pylorak/tinywall) by Károly Pados. Upstream development is largely inactive, so this fork picks up where it left off with the following goals:

- **Modernize the build system**: Ported from .NET Framework 4.8 to .NET 9, removing the dependency on Visual Studio, COM tooling, and the WiX installer. The project now builds with just `dotnet build` and the .NET 9 SDK.
- **Add new features**: Introduced a regex auto-unblock system that lets you define patterns to automatically unblock matching executables with per-pattern enable/disable control.
- **Clean up the codebase**: Replaced COM interop with dynamic COM, replaced `ManagedInstallerClass` with direct P/Invoke service management, fixed all nullable reference type warnings, and removed obsolete attributes.

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
