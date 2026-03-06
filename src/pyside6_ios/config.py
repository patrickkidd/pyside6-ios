import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

if sys.version_info >= (3, 11):
    import tomllib
else:
    import tomli as tomllib


@dataclass
class PackageEntry:
    src: str
    exclude: list[str] = field(default_factory=list)
    dest: str = ""  # renamed in bundle; empty = same as src basename


@dataclass
class BindingModule:
    name: str
    headers: list[str]
    typesystem: str


@dataclass
class QmlPlugin:
    classname: str  # Q_IMPORT_PLUGIN name
    libname: str    # -l flag (without lib prefix)
    libdir: str     # directory containing the .a


@dataclass
class AppConfig:
    # [app]
    name: str
    bundle_id: str
    version: str
    entry_point: str
    team_id: str
    deployment_target: str = "16.0"

    # [paths]
    pyside6_ios: Path = field(default_factory=Path)
    qt_ios: Path = field(default_factory=Path)
    output_dir: Path = field(default_factory=lambda: Path("build/ios"))

    # [pyside6]
    pyside6_modules: list[str] = field(default_factory=list)

    # [python]
    packages: list[PackageEntry] = field(default_factory=list)
    vendor_dir: str = ""
    scripts: list[str] = field(default_factory=list)

    # [qml]
    qml_dirs: list[str] = field(default_factory=list)
    qt_modules: list[str] = field(default_factory=list)

    # [resources]
    resource_dirs: list[str] = field(default_factory=list)
    resource_files: list[str] = field(default_factory=list)
    assets: str = ""
    settings_bundle: str = ""

    # [sources]
    main_mm: str = ""
    source_files: list[str] = field(default_factory=list)
    header_search_paths: list[str] = field(default_factory=list)
    static_libs: list[str] = field(default_factory=list)

    # [bindings]
    binding_modules: list[BindingModule] = field(default_factory=list)

    # [info-plist]
    info_plist: str = ""

    # [entitlements]
    entitlements: str = ""

    # [signing]
    signing_style: str = "Automatic"
    xcconfig: str = ""
    xcconfig_debug: str = ""
    xcconfig_release: str = ""

    # [build-scripts]
    pre_scripts: list[str] = field(default_factory=list)

    # [build-settings]
    build_settings: dict[str, str] = field(default_factory=dict)
    build_settings_debug: dict[str, str] = field(default_factory=dict)
    build_settings_release: dict[str, str] = field(default_factory=dict)

    # [defines]
    defines_common: list[str] = field(default_factory=list)
    defines_debug: list[str] = field(default_factory=list)
    defines_release: list[str] = field(default_factory=list)
    defines_alpha: list[str] = field(default_factory=list)
    defines_beta: list[str] = field(default_factory=list)

    # Derived
    project_root: Path = field(default_factory=Path)
    python_version: str = ""
    qml_plugins: list[QmlPlugin] = field(default_factory=list)


def _resolve(base: Path, p: str) -> Path:
    expanded = Path(os.path.expanduser(p))
    if expanded.is_absolute():
        return expanded
    return (base / expanded).resolve()


def _detect_python_version(pyside6_ios_path: Path) -> str:
    patchlevel = (
        pyside6_ios_path
        / "build/python/Python.xcframework/ios-arm64/Python.framework/Headers/patchlevel.h"
    )
    if not patchlevel.exists():
        raise FileNotFoundError(f"Cannot detect Python version: {patchlevel}")
    text = patchlevel.read_text()
    m = re.search(r'#define\s+PY_VERSION\s+"(\d+\.\d+)', text)
    if not m:
        raise ValueError(f"Cannot parse PY_VERSION from {patchlevel}")
    return m.group(1)


def _discover_qml_plugins(qt_ios: Path, qt_modules: list[str]) -> list[QmlPlugin]:
    plugins = []
    seen = set()
    qml_root = qt_ios / "qml"
    for mod in qt_modules:
        mod_dir = qml_root / mod.replace(".", "/")
        if not mod_dir.is_dir():
            continue
        for qmldir_path in mod_dir.rglob("qmldir"):
            classname = None
            plugin_name = None
            for line in qmldir_path.read_text().splitlines():
                if line.startswith("classname "):
                    classname = line.split()[1]
                elif line.startswith("plugin "):
                    plugin_name = line.split()[1]
            if not classname:
                continue
            if classname in seen:
                continue
            seen.add(classname)
            lib_dir = qmldir_path.parent
            # Find the .a file (non-debug)
            libs = [f for f in lib_dir.iterdir()
                    if f.suffix == ".a" and "_debug" not in f.name]
            if not libs:
                continue
            libname = libs[0].stem.removeprefix("lib")
            plugins.append(QmlPlugin(
                classname=classname,
                libname=libname,
                libdir=str(lib_dir),
            ))
    return plugins


def _validate(cfg: AppConfig):
    if not cfg.pyside6_ios.exists():
        raise FileNotFoundError(f"pyside6-ios path not found: {cfg.pyside6_ios}")
    if not cfg.qt_ios.exists():
        raise FileNotFoundError(f"Qt iOS SDK not found: {cfg.qt_ios}")

    static_dir = cfg.pyside6_ios / "build/pyside6-ios-static"
    for mod in cfg.pyside6_modules:
        lib = static_dir / f"libPySide6_{mod}.a"
        if not lib.exists():
            raise FileNotFoundError(
                f"PySide6 module {mod} not cross-compiled: {lib}"
            )


def load(toml_path: str | Path) -> AppConfig:
    toml_path = Path(toml_path).resolve()
    project_root = toml_path.parent

    with open(toml_path, "rb") as f:
        raw = tomllib.load(f)

    app = raw.get("app", {})
    paths = raw.get("paths", {})
    pyside6 = raw.get("pyside6", {})
    python = raw.get("python", {})
    qml = raw.get("qml", {})
    resources = raw.get("resources", {})
    sources = raw.get("sources", {})
    bindings = raw.get("bindings", {})
    info_plist = raw.get("info-plist", {})
    entitlements_sec = raw.get("entitlements", {})
    signing = raw.get("signing", {})
    signing_ci = signing.get("ci", {})
    build_scripts = raw.get("build-scripts", {})
    build_settings = raw.get("build-settings", {})
    defines = raw.get("defines", {})

    pyside6_ios_path = _resolve(project_root, paths.get("pyside6-ios", ""))
    qt_ios_path = _resolve(project_root, paths.get("qt-ios", ""))

    package_entries = []
    for p in python.get("packages", []):
        package_entries.append(PackageEntry(
            src=p["src"],
            exclude=p.get("exclude", []),
            dest=p.get("as", ""),
        ))

    binding_entries = []
    for b in bindings.get("modules", []):
        binding_entries.append(BindingModule(
            name=b["name"],
            headers=b["headers"],
            typesystem=b["typesystem"],
        ))

    # Extract build-settings, separating debug/release sub-tables
    bs = {k: v for k, v in build_settings.items() if not isinstance(v, dict)}
    bs_debug = build_settings.get("debug", {})
    bs_release = build_settings.get("release", {})

    cfg = AppConfig(
        name=app["name"],
        bundle_id=app["bundle-id"],
        version=app["version"],
        entry_point=app.get("entry-point", ""),
        team_id=app.get("team-id", ""),
        deployment_target=app.get("deployment-target", "16.0"),
        pyside6_ios=pyside6_ios_path,
        qt_ios=qt_ios_path,
        output_dir=_resolve(project_root, paths.get("output-dir", "build/ios")),
        pyside6_modules=pyside6.get("modules", []),
        packages=package_entries,
        vendor_dir=python.get("vendor-dir", ""),
        scripts=python.get("scripts", []),
        qml_dirs=qml.get("dirs", []),
        qt_modules=qml.get("qt-modules", []),
        resource_dirs=resources.get("dirs", []),
        resource_files=resources.get("files", []),
        assets=resources.get("assets", ""),
        settings_bundle=resources.get("settings-bundle", ""),
        main_mm=sources.get("main-mm", ""),
        source_files=sources.get("files", []),
        header_search_paths=sources.get("header-search-paths", []),
        static_libs=sources.get("static-libs", []),
        binding_modules=binding_entries,
        info_plist=info_plist.get("file", ""),
        entitlements=entitlements_sec.get("file", ""),
        signing_style=signing.get("style", "Automatic"),
        xcconfig=signing_ci.get("xcconfig", ""),
        xcconfig_debug=signing_ci.get("xcconfig-debug", ""),
        xcconfig_release=signing_ci.get("xcconfig-release", ""),
        pre_scripts=build_scripts.get("pre", []),
        build_settings=bs,
        build_settings_debug=bs_debug,
        build_settings_release=bs_release,
        defines_common=defines.get("common", []),
        defines_debug=defines.get("debug", []),
        defines_release=defines.get("release", []),
        defines_alpha=defines.get("alpha", []),
        defines_beta=defines.get("beta", []),
        project_root=project_root,
        python_version=_detect_python_version(pyside6_ios_path),
    )

    cfg.qml_plugins = _discover_qml_plugins(qt_ios_path, cfg.qt_modules)

    _validate(cfg)
    return cfg
