from pathlib import Path

from pyside6_ios.config import AppConfig


class IdGen:
    def __init__(self):
        self._counter = 0

    def next(self) -> str:
        self._counter += 1
        return f"{self._counter:024X}"


def _escape(s: str) -> str:
    if not s or " " in s or "/" in s or "." in s or "-" in s or "+" in s or "=" in s:
        return f'"{s}"'
    return s


def _list(items: list[str], indent: str = "\t\t\t\t") -> str:
    return "\n".join(f"{indent}{_escape(i)}," for i in items)


def generate(cfg: AppConfig, moc_files: list[Path] = None, binding_libs: list[Path] = None) -> str:
    if moc_files is None:
        moc_files = []
    if binding_libs is None:
        binding_libs = []

    ids = IdGen()
    build_files = []     # (build_id, file_ref_id, name, settings)
    file_refs = []       # (ref_id, name, path, file_type, source_tree)
    source_ids = []      # build_file ids for Sources phase
    framework_ids = []   # build_file ids for Frameworks phase
    embed_ids = []       # build_file ids for Embed Frameworks phase
    copy_qml_ids = []    # build_file ids for Copy QML Files phase
    resource_ids = []    # build_file ids for Resources phase

    # Helpers
    p6ios = cfg.pyside6_ios
    rel_p6ios = f"../../{cfg.pyside6_ios.name}" if cfg.output_dir.is_relative_to(cfg.project_root) else str(cfg.pyside6_ios)

    def _rel_to_project(p: Path) -> str:
        try:
            return str(p.relative_to(cfg.output_dir))
        except ValueError:
            return str(p)

    def add_source(name: str, path: str, file_type: str, source_tree: str = '"<group>"'):
        ref_id = ids.next()
        build_id = ids.next()
        file_refs.append((ref_id, name, path, file_type, source_tree))
        build_files.append((build_id, ref_id, name, None))
        source_ids.append(build_id)
        return ref_id

    def add_framework(name: str, path: str, file_type: str, source_tree: str = '"<group>"',
                      embed: bool = False):
        ref_id = ids.next()
        build_id = ids.next()
        file_refs.append((ref_id, name, path, file_type, source_tree))
        build_files.append((build_id, ref_id, name, None))
        framework_ids.append(build_id)
        if embed:
            embed_build_id = ids.next()
            build_files.append((embed_build_id, ref_id, name,
                               "ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, )"))
            embed_ids.append(embed_build_id)
        return ref_id

    def add_qml_resource(name: str, path: str, file_type: str, source_tree: str = '"<group>"'):
        ref_id = ids.next()
        build_id = ids.next()
        file_refs.append((ref_id, name, path, file_type, source_tree))
        build_files.append((build_id, ref_id, name, None))
        copy_qml_ids.append(build_id)
        return ref_id

    def add_resource(name: str, path: str, file_type: str, source_tree: str = '"<group>"'):
        ref_id = ids.next()
        build_id = ids.next()
        file_refs.append((ref_id, name, path, file_type, source_tree))
        build_files.append((build_id, ref_id, name, None))
        resource_ids.append(build_id)
        return ref_id

    # -- main.mm (always in output dir)
    main_mm_ref = add_source("main.mm", "main.mm", "sourcecode.cpp.objcpp")

    # -- Additional source files
    extra_source_refs = []
    for src in cfg.source_files:
        name = Path(src).name
        # Path relative to output dir
        src_path = str(cfg.project_root / src)
        ref = add_source(name, src_path, _filetype(name))
        extra_source_refs.append(ref)

    # -- moc outputs
    moc_refs = []
    for mf in moc_files:
        name = mf.name
        ref = add_source(name, str(mf), "sourcecode.cpp.cpp")
        moc_refs.append(ref)

    # -- QtRuntime.framework
    qtruntime_path = _rel_to_project(p6ios / "build/QtRuntime.framework")
    qtruntime_ref = add_framework("QtRuntime.framework", qtruntime_path,
                                  "wrapper.framework", embed=True)

    # -- Python.framework
    python_path = _rel_to_project(
        p6ios / "build/python/Python.xcframework/ios-arm64/Python.framework"
    )
    python_ref = add_framework("Python.framework", python_path,
                                "wrapper.framework", embed=True)

    # -- System frameworks
    uikit_ref = add_framework("UIKit.framework",
                               "System/Library/Frameworks/UIKit.framework",
                               "wrapper.framework", source_tree="SDKROOT")
    foundation_ref = add_framework("Foundation.framework",
                                    "System/Library/Frameworks/Foundation.framework",
                                    "wrapper.framework", source_tree="SDKROOT")

    # -- PySide6 static libs
    static_dir = _rel_to_project(p6ios / "build/pyside6-ios-static")
    pyside_lib_refs = []
    for mod in cfg.pyside6_modules:
        name = f"libPySide6_{mod}.a"
        ref = add_framework(name, f"{static_dir}/{name}", "archive.ar")
        pyside_lib_refs.append(ref)

    # Core pyside/shiboken libs
    for lib_name, lib_dir in [
        ("libshiboken6.a", "libshiboken-ios"),
        ("libpyside6.a", "libpyside-ios"),
        ("libpysideqml.a", "libpysideqml-ios"),
    ]:
        path = _rel_to_project(p6ios / f"build/{lib_dir}/{lib_name}")
        add_framework(lib_name, path, "archive.ar")

    # Shiboken module wrapper
    shib_wrapper = _rel_to_project(p6ios / "build/shiboken-ios/shiboken_module_wrapper.o")
    ref_id = ids.next()
    build_id = ids.next()
    file_refs.append((ref_id, "shiboken_module_wrapper.o", shib_wrapper,
                      "compiled.mach-o.objfile", '"<group>"'))
    build_files.append((build_id, ref_id, "shiboken_module_wrapper.o", None))
    framework_ids.append(build_id)

    # -- Custom binding libs
    for lib in binding_libs:
        name = lib.name
        ref = add_framework(name, str(lib), "archive.ar")

    # -- Custom static libs from config
    for lib_path in cfg.static_libs:
        p = cfg.project_root / lib_path
        ref = add_framework(p.name, str(p), "archive.ar")

    # -- Assets catalog
    if cfg.assets:
        assets_name = Path(cfg.assets).name
        add_resource(assets_name, assets_name, "folder.assetcatalog")

    # -- Info.plist ref (not in a build phase, just a file ref)
    info_plist_ref = ids.next()
    file_refs.append((info_plist_ref, "Info.plist", "Info.plist",
                      "text.plist.xml", '"<group>"'))

    # -- Product ref
    product_ref = ids.next()
    product_name = cfg.name.replace(" ", "")
    file_refs.append((product_ref, f"{product_name}.app", f"{product_name}.app",
                      "wrapper.application", "BUILT_PRODUCTS_DIR"))

    # -- Groups
    main_group = ids.next()
    frameworks_group = ids.next()
    products_group = ids.next()

    all_fw_refs = ([qtruntime_ref, python_ref] + pyside_lib_refs +
                   [uikit_ref, foundation_ref])

    # -- Build phases
    sources_phase = ids.next()
    frameworks_phase = ids.next()
    embed_phase = ids.next()
    copy_qml_phase = ids.next()
    resources_phase = ids.next()

    # Shell script phases
    shell_phases = []

    # Copy QML Modules
    qml_modules_phase = ids.next()
    qml_copy_script = _gen_qml_modules_script(cfg)
    shell_phases.append((qml_modules_phase, "Copy QML Modules", qml_copy_script))

    # Copy Python Stdlib
    stdlib_phase = ids.next()
    stdlib_script = _gen_stdlib_script(cfg)
    shell_phases.append((stdlib_phase, "Copy Python Stdlib", stdlib_script))

    # Copy Python Packages
    packages_phase = ids.next()
    packages_script = _gen_packages_script(cfg)
    shell_phases.append((packages_phase, "Copy Python Packages", packages_script))

    # Copy Resources
    if cfg.resource_dirs or cfg.resource_files or cfg.settings_bundle:
        copy_resources_phase = ids.next()
        resources_script = _gen_resources_script(cfg)
        shell_phases.append((copy_resources_phase, "Copy Resources", resources_script))

    # -- Target
    target_id = ids.next()

    # -- Configurations
    proj_debug_id = ids.next()
    proj_release_id = ids.next()
    proj_config_list = ids.next()
    tgt_debug_id = ids.next()
    tgt_release_id = ids.next()
    tgt_config_list = ids.next()

    # -- Project
    project_id = ids.next()

    # Build the .pbxproj string
    lines = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "",
    ]

    # PBXBuildFile
    lines.append("/* Begin PBXBuildFile section */")
    for bf_id, ref_id, name, settings in build_files:
        if settings:
            lines.append(f"\t\t{bf_id} /* {name} */ = {{isa = PBXBuildFile; fileRef = {ref_id}; settings = {{{settings}; }}; }};")
        else:
            lines.append(f"\t\t{bf_id} /* {name} */ = {{isa = PBXBuildFile; fileRef = {ref_id}; }};")
    lines.append("/* End PBXBuildFile section */")
    lines.append("")

    # PBXCopyFilesBuildPhase
    lines.append("/* Begin PBXCopyFilesBuildPhase section */")
    # Embed Frameworks
    lines.append(f"\t\t{embed_phase} /* Embed Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXCopyFilesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append('\t\t\tdstPath = "";')
    lines.append("\t\t\tdstSubfolderSpec = 10;")
    lines.append("\t\t\tfiles = (")
    for eid in embed_ids:
        lines.append(f"\t\t\t\t{eid},")
    lines.append("\t\t\t);")
    lines.append('\t\t\tname = "Embed Frameworks";')
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    # Copy QML Files
    if copy_qml_ids:
        lines.append(f"\t\t{copy_qml_phase} /* Copy QML Files */ = {{")
        lines.append("\t\t\tisa = PBXCopyFilesBuildPhase;")
        lines.append("\t\t\tbuildActionMask = 2147483647;")
        lines.append('\t\t\tdstPath = "";')
        lines.append("\t\t\tdstSubfolderSpec = 1;")
        lines.append("\t\t\tfiles = (")
        for cid in copy_qml_ids:
            lines.append(f"\t\t\t\t{cid},")
        lines.append("\t\t\t);")
        lines.append('\t\t\tname = "Copy QML Files";')
        lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        lines.append("\t\t};")
    lines.append("/* End PBXCopyFilesBuildPhase section */")
    lines.append("")

    # PBXResourcesBuildPhase
    if resource_ids:
        lines.append("/* Begin PBXResourcesBuildPhase section */")
        lines.append(f"\t\t{resources_phase} /* Resources */ = {{")
        lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
        lines.append("\t\t\tbuildActionMask = 2147483647;")
        lines.append("\t\t\tfiles = (")
        for rid in resource_ids:
            lines.append(f"\t\t\t\t{rid},")
        lines.append("\t\t\t);")
        lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        lines.append("\t\t};")
        lines.append("/* End PBXResourcesBuildPhase section */")
        lines.append("")

    # PBXShellScriptBuildPhase
    lines.append("/* Begin PBXShellScriptBuildPhase section */")
    for sp_id, sp_name, sp_script in shell_phases:
        escaped_script = sp_script.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        lines.append(f'\t\t{sp_id} /* {sp_name} */ = {{')
        lines.append("\t\t\tisa = PBXShellScriptBuildPhase;")
        lines.append("\t\t\tbuildActionMask = 2147483647;")
        lines.append("\t\t\tfiles = (")
        lines.append("\t\t\t);")
        lines.append("\t\t\tinputPaths = (")
        lines.append("\t\t\t);")
        lines.append(f'\t\t\tname = "{sp_name}";')
        lines.append("\t\t\toutputPaths = (")
        lines.append("\t\t\t);")
        lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        lines.append("\t\t\tshellPath = /bin/bash;")
        lines.append(f'\t\t\tshellScript = "{escaped_script}";')
        lines.append("\t\t};")
    lines.append("/* End PBXShellScriptBuildPhase section */")
    lines.append("")

    # PBXFileReference
    lines.append("/* Begin PBXFileReference section */")
    for ref_id, name, path, ft, src_tree in file_refs:
        if src_tree == "BUILT_PRODUCTS_DIR":
            lines.append(f'\t\t{ref_id} /* {name} */ = {{isa = PBXFileReference; explicitFileType = {ft}; includeInIndex = 0; path = {_escape(name)}; sourceTree = BUILT_PRODUCTS_DIR; }};')
        elif src_tree == "SDKROOT":
            lines.append(f'\t\t{ref_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; name = {_escape(name)}; path = {_escape(path)}; sourceTree = SDKROOT; }};')
        else:
            lines.append(f'\t\t{ref_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; name = {_escape(name)}; path = {_escape(path)}; sourceTree = {src_tree}; }};')
    lines.append("/* End PBXFileReference section */")
    lines.append("")

    # PBXFrameworksBuildPhase
    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for fid in framework_ids:
        lines.append(f"\t\t\t\t{fid},")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")

    # PBXGroup
    lines.append("/* Begin PBXGroup section */")
    # Main group
    lines.append(f"\t\t{main_group} = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{main_mm_ref} /* main.mm */,")
    lines.append(f"\t\t\t\t{info_plist_ref} /* Info.plist */,")
    lines.append(f"\t\t\t\t{frameworks_group} /* Frameworks */,")
    lines.append(f"\t\t\t\t{products_group} /* Products */,")
    lines.append("\t\t\t);")
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append("\t\t};")
    # Frameworks group
    lines.append(f"\t\t{frameworks_group} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for ref_id, name, _, _, _ in file_refs:
        if name.endswith((".framework", ".a", ".o")) and ref_id != product_ref:
            lines.append(f"\t\t\t\t{ref_id} /* {name} */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Frameworks;")
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append("\t\t};")
    # Products group
    lines.append(f"\t\t{products_group} /* Products */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{product_ref} /* {product_name}.app */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Products;")
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append("\t\t};")
    lines.append("/* End PBXGroup section */")
    lines.append("")

    # PBXNativeTarget
    all_phases = [sources_phase, frameworks_phase, embed_phase]
    if resource_ids:
        all_phases.append(resources_phase)
    if copy_qml_ids:
        all_phases.append(copy_qml_phase)
    all_phases.extend(sp_id for sp_id, _, _ in shell_phases)

    lines.append("/* Begin PBXNativeTarget section */")
    lines.append(f"\t\t{target_id} /* {product_name} */ = {{")
    lines.append("\t\t\tisa = PBXNativeTarget;")
    lines.append(f"\t\t\tbuildConfigurationList = {tgt_config_list};")
    lines.append("\t\t\tbuildPhases = (")
    for pid in all_phases:
        lines.append(f"\t\t\t\t{pid},")
    lines.append("\t\t\t);")
    lines.append("\t\t\tbuildRules = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdependencies = (")
    lines.append("\t\t\t);")
    lines.append(f"\t\t\tname = {_escape(product_name)};")
    lines.append(f"\t\t\tproductName = {_escape(product_name)};")
    lines.append(f"\t\t\tproductReference = {product_ref};")
    lines.append('\t\t\tproductType = "com.apple.product-type.application";')
    lines.append("\t\t};")
    lines.append("/* End PBXNativeTarget section */")
    lines.append("")

    # PBXProject
    lines.append("/* Begin PBXProject section */")
    lines.append(f"\t\t{project_id} /* Project object */ = {{")
    lines.append("\t\t\tisa = PBXProject;")
    lines.append("\t\t\tattributes = {")
    lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    lines.append("\t\t\t\tLastUpgradeCheck = 1500;")
    lines.append("\t\t\t\tTargetAttributes = {")
    lines.append(f"\t\t\t\t\t{target_id} = {{")
    lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    lines.append("\t\t\t\t\t};")
    lines.append("\t\t\t\t};")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tbuildConfigurationList = {proj_config_list};")
    lines.append(f'\t\t\tcompatibilityVersion = "Xcode 14.0";')
    lines.append("\t\t\tdevelopmentRegion = en;")
    lines.append("\t\t\thasScannedForEncodings = 0;")
    lines.append("\t\t\tknownRegions = (")
    lines.append("\t\t\t\ten,")
    lines.append("\t\t\t\tBase,")
    lines.append("\t\t\t);")
    lines.append(f"\t\t\tmainGroup = {main_group};")
    lines.append(f"\t\t\tproductRefGroup = {products_group};")
    lines.append('\t\t\tprojectDirPath = "";')
    lines.append('\t\t\tprojectRoot = "";')
    lines.append("\t\t\ttargets = (")
    lines.append(f"\t\t\t\t{target_id},")
    lines.append("\t\t\t);")
    lines.append("\t\t};")
    lines.append("/* End PBXProject section */")
    lines.append("")

    # PBXSourcesBuildPhase
    lines.append("/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{sources_phase} /* Sources */ = {{")
    lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for sid in source_ids:
        lines.append(f"\t\t\t\t{sid},")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")

    # XCBuildConfiguration
    lines.append("/* Begin XCBuildConfiguration section */")
    # Project-level configs
    for conf_id, conf_name in [(proj_debug_id, "Debug"), (proj_release_id, "Release")]:
        lines.append(f"\t\t{conf_id} /* {conf_name} */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
        lines.append('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "c++17";')
        lines.append("\t\t\t\tCLANG_ENABLE_ARC = YES;")
        lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
        lines.append("\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = NO;")
        lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {cfg.deployment_target};")
        lines.append("\t\t\t\tSDKROOT = iphoneos;")
        lines.append('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
        # Shared build settings
        for k, v in cfg.build_settings.items():
            lines.append(f"\t\t\t\t{k} = {_escape(v)};")
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tname = {conf_name};")
        lines.append("\t\t};")

    # Target-level configs
    fw_search = _build_fw_search_paths(cfg)
    hdr_search = _build_header_search_paths(cfg)
    lib_search = _build_lib_search_paths(cfg, binding_libs)
    other_cxx = _build_other_cxx_flags(cfg)

    for conf_id, conf_name, extra_settings in [
        (tgt_debug_id, "Debug", cfg.build_settings_debug),
        (tgt_release_id, "Release", cfg.build_settings_release),
    ]:
        lines.append(f"\t\t{conf_id} /* {conf_name} */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        lines.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
        lines.append(f"\t\t\t\tCODE_SIGN_STYLE = {cfg.signing_style};")
        if cfg.team_id:
            lines.append(f"\t\t\t\tDEVELOPMENT_TEAM = {cfg.team_id};")
        if cfg.entitlements:
            ent_name = Path(cfg.entitlements).name
            lines.append(f"\t\t\t\tCODE_SIGN_ENTITLEMENTS = {_escape(ent_name)};")
        lines.append("\t\t\t\tFRAMEWORK_SEARCH_PATHS = (")
        lines.append('\t\t\t\t\t"$(inherited)",')
        for p in fw_search:
            lines.append(f"\t\t\t\t\t{_escape(p)},")
        lines.append("\t\t\t\t);")
        lines.append("\t\t\t\tHEADER_SEARCH_PATHS = (")
        lines.append('\t\t\t\t\t"$(inherited)",')
        for p in hdr_search:
            lines.append(f"\t\t\t\t\t{_escape(p)},")
        lines.append("\t\t\t\t);")
        lines.append("\t\t\t\tLIBRARY_SEARCH_PATHS = (")
        lines.append('\t\t\t\t\t"$(inherited)",')
        for p in lib_search:
            lines.append(f"\t\t\t\t\t{_escape(p)},")
        lines.append("\t\t\t\t);")
        lines.append("\t\t\t\tOTHER_CPLUSPLUSFLAGS = (")
        lines.append('\t\t\t\t\t"$(inherited)",')
        for f in other_cxx:
            lines.append(f"\t\t\t\t\t{_escape(f)},")
        lines.append("\t\t\t\t);")
        if cfg.qml_plugins:
            lines.append("\t\t\t\tOTHER_LDFLAGS = (")
            lines.append('\t\t\t\t\t"$(inherited)",')
            for plugin in cfg.qml_plugins:
                lines.append(f'\t\t\t\t\t"-l{plugin.libname}",')
            lines.append("\t\t\t\t);")
        lines.append("\t\t\t\tINFOPLIST_FILE = Info.plist;")
        lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
        lines.append('\t\t\t\t\t"$(inherited)",')
        lines.append('\t\t\t\t\t"@executable_path/Frameworks",')
        lines.append("\t\t\t\t);")
        lines.append(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {_escape(cfg.bundle_id)};")
        lines.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
        lines.append("\t\t\t\tSWIFT_VERSION = 5.0;")
        for k, v in extra_settings.items():
            lines.append(f"\t\t\t\t{k} = {_escape(v)};")
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tname = {conf_name};")
        lines.append("\t\t};")
    lines.append("/* End XCBuildConfiguration section */")
    lines.append("")

    # XCConfigurationList
    lines.append("/* Begin XCConfigurationList section */")
    lines.append(f"\t\t{proj_config_list} = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{proj_debug_id},")
    lines.append(f"\t\t\t\t{proj_release_id},")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")
    lines.append(f"\t\t{tgt_config_list} = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{tgt_debug_id},")
    lines.append(f"\t\t\t\t{tgt_release_id},")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")
    lines.append("/* End XCConfigurationList section */")
    lines.append("")

    lines.append("\t};")
    lines.append(f"\trootObject = {project_id};")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def _filetype(name: str) -> str:
    ext = Path(name).suffix.lower()
    return {
        ".mm": "sourcecode.cpp.objcpp",
        ".cpp": "sourcecode.cpp.cpp",
        ".c": "sourcecode.c.c",
        ".m": "sourcecode.c.objc",
        ".h": "sourcecode.c.h",
        ".hpp": "sourcecode.cpp.h",
        ".qml": "text",
        ".plist": "text.plist.xml",
    }.get(ext, "text")


def _build_fw_search_paths(cfg: AppConfig) -> list[str]:
    p6 = cfg.pyside6_ios
    return [
        _proj_path(cfg, p6 / 'build'),
        _proj_path(cfg, p6 / 'build/python/Python.xcframework/ios-arm64'),
    ]


def _build_header_search_paths(cfg: AppConfig) -> list[str]:
    paths = [
        f"{cfg.qt_ios}/include",
        _proj_path(cfg, cfg.pyside6_ios / 'build/python/Python.xcframework/ios-arm64/include' / ('python' + cfg.python_version)),
    ]
    for hp in cfg.header_search_paths:
        paths.append(str(cfg.project_root / hp))
    return paths


def _build_lib_search_paths(cfg: AppConfig, binding_libs: list[Path] = None) -> list[str]:
    p6 = cfg.pyside6_ios
    paths = [
        _proj_path(cfg, p6 / 'build/pyside6-ios-static'),
        _proj_path(cfg, p6 / 'build/shiboken-ios'),
        _proj_path(cfg, p6 / 'build/libpysideqml-ios'),
        _proj_path(cfg, p6 / 'build/libshiboken-ios'),
        _proj_path(cfg, p6 / 'build/libpyside-ios'),
    ]
    seen = set()
    for plugin in cfg.qml_plugins:
        if plugin.libdir not in seen:
            seen.add(plugin.libdir)
            paths.append(plugin.libdir)
    for lib in (binding_libs or []):
        lib_dir = str(lib.parent)
        if lib_dir not in seen:
            seen.add(lib_dir)
            paths.append(lib_dir)
    return paths


def _build_other_cxx_flags(cfg: AppConfig) -> list[str]:
    return [
        "-iframework",
        f"{cfg.qt_ios}/lib",
    ]


def _proj_rel(cfg: AppConfig, target: Path) -> str:
    target = target.resolve() if target.exists() else target
    out = cfg.output_dir.resolve() if cfg.output_dir.exists() else cfg.output_dir
    try:
        return str(target.relative_to(out))
    except ValueError:
        return str(target)


def _proj_path(cfg: AppConfig, target: Path) -> str:
    rel = _proj_rel(cfg, target)
    if rel.startswith("/"):
        return rel
    return f"$(PROJECT_DIR)/{rel}"


def _gen_qml_modules_script(cfg: AppConfig) -> str:
    lines = [
        f'QT_IOS="{cfg.qt_ios}"',
        'APP="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"',
        'mkdir -p "$APP/qml"',
    ]
    for mod in cfg.qt_modules:
        lines.append(f'if [ -d "$QT_IOS/qml/{mod}" ]; then')
        lines.append(f'    cp -R "$QT_IOS/qml/{mod}" "$APP/qml/"')
        lines.append("fi")

    # Copy app QML dirs
    for qml_dir in cfg.qml_dirs:
        src = cfg.project_root / qml_dir
        lines.append(f'cp -R "{src}/"* "$APP/qml/" 2>/dev/null || true')

    return "\n".join(lines)


def _gen_stdlib_script(cfg: AppConfig) -> str:
    p6 = cfg.pyside6_ios
    pv = cfg.python_version
    xcfw = p6 / "build/python/Python.xcframework"
    return "\n".join([
        f'PYXCFW="{xcfw}"',
        'APP="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"',
        f'mkdir -p "$APP/lib/python{pv}"',
        f'rsync -a "$PYXCFW/lib/python{pv}/" "$APP/lib/python{pv}/"',
        f'if [ -d "$PYXCFW/ios-arm64/lib-arm64/python{pv}/lib-dynload" ]; then',
        f'    mkdir -p "$APP/lib/python{pv}/lib-dynload"',
        f'    cp -R "$PYXCFW/ios-arm64/lib-arm64/python{pv}/lib-dynload/"*.so "$APP/lib/python{pv}/lib-dynload/"',
        f'    for so in "$APP/lib/python{pv}/lib-dynload/"*.so; do',
        '        /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none "$so"',
        "    done",
        "fi",
    ])


def _gen_packages_script(cfg: AppConfig) -> str:
    lines = ['APP="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"']

    # App packages
    for pkg in cfg.packages:
        src = cfg.project_root / pkg.src
        dest_name = pkg.dest if pkg.dest else Path(pkg.src).name
        lines.append(f'mkdir -p "$APP/packages/{dest_name}"')
        exclude_args = " ".join(f'--exclude="{e}"' for e in pkg.exclude)
        lines.append(f'rsync -a {exclude_args} "{src}/" "$APP/packages/{dest_name}/"')

    # Vendor dir
    if cfg.vendor_dir:
        vendor_src = cfg.project_root / cfg.vendor_dir
        lines.append(f'mkdir -p "$APP/vendor"')
        lines.append(f'rsync -a "{vendor_src}/" "$APP/vendor/"')

    # Scripts
    if cfg.scripts:
        lines.append('mkdir -p "$APP/scripts"')
        for script in cfg.scripts:
            src = cfg.project_root / script
            lines.append(f'cp "{src}" "$APP/scripts/"')

    # PySide6/shiboken6 package stubs
    p6 = cfg.pyside6_ios
    stubs = p6 / "test/test_pyside6/packages"
    lines.append(f'if [ -d "{stubs}/PySide6" ]; then')
    lines.append(f'    mkdir -p "$APP/packages/PySide6"')
    lines.append(f'    cp -R "{stubs}/PySide6/"*.py "$APP/packages/PySide6/"')
    lines.append("fi")
    lines.append(f'if [ -d "{stubs}/shiboken6" ]; then')
    lines.append(f'    mkdir -p "$APP/packages/shiboken6"')
    lines.append(f'    cp -R "{stubs}/shiboken6/"*.py "$APP/packages/shiboken6/"')
    lines.append("fi")

    return "\n".join(lines)


def _gen_resources_script(cfg: AppConfig) -> str:
    lines = ['APP="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"']

    for d in cfg.resource_dirs:
        src = cfg.project_root / d
        dest_name = Path(d).name
        lines.append(f'mkdir -p "$APP/app_resources/{dest_name}"')
        lines.append(f'cp -R "{src}/"* "$APP/app_resources/{dest_name}/"')

    for pattern in cfg.resource_files:
        src = cfg.project_root / pattern
        lines.append(f'mkdir -p "$APP/app_resources"')
        lines.append(f'cp -R {src} "$APP/app_resources/" 2>/dev/null || true')

    if cfg.settings_bundle:
        lines.append('cp -R "$PROJECT_DIR/Settings.bundle" "$APP/"')
        lines.append('/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" '
                      '--timestamp=none "$APP/Settings.bundle"')

    return "\n".join(lines)
