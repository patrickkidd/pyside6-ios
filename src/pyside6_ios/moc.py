import re
import subprocess
from pathlib import Path

from pyside6_ios.config import AppConfig

Q_OBJECT_RE = re.compile(r"^\s*Q_OBJECT\s*$", re.MULTILINE)


def _needs_moc(header_path: Path) -> bool:
    text = header_path.read_text(errors="replace")
    return bool(Q_OBJECT_RE.search(text))


def _find_moc(cfg: AppConfig) -> str:
    # Qt macOS SDK moc (host tool for code generation)
    qt_macos = cfg.qt_ios.parent / "macos"
    moc = qt_macos / "libexec" / "moc"
    if moc.exists():
        return str(moc)
    moc = qt_macos / "bin" / "moc"
    if moc.exists():
        return str(moc)
    raise FileNotFoundError(
        f"moc not found in Qt macOS SDK at {qt_macos}/libexec/ or {qt_macos}/bin/. "
        f"Ensure Qt macOS SDK is installed alongside the iOS SDK."
    )


def run(cfg: AppConfig) -> list[Path]:
    moc_bin = _find_moc(cfg)
    output_dir = cfg.output_dir / "moc"
    output_dir.mkdir(parents=True, exist_ok=True)

    headers = []
    for src in cfg.source_files:
        p = cfg.project_root / src
        if p.suffix in (".h", ".hpp") and p.exists():
            headers.append(p)
        # Also check for companion header of .cpp/.mm files
        for ext in (".h", ".hpp"):
            companion = p.with_suffix(ext)
            if companion.exists():
                headers.append(companion)

    for bmod in cfg.binding_modules:
        for h in bmod.headers:
            hp = cfg.project_root / h
            if hp.exists():
                headers.append(hp)

    # Deduplicate
    headers = list(dict.fromkeys(headers))

    generated = []
    for header in headers:
        if not _needs_moc(header):
            continue

        out_file = output_dir / f"moc_{header.stem}.cpp"
        cmd = [
            moc_bin,
            "-F", str(cfg.qt_ios / "lib"),
            "-I", str(cfg.qt_ios / "include"),
        ]
        for hp in cfg.header_search_paths:
            cmd.extend(["-I", str(cfg.project_root / hp)])
        cmd.extend([str(header), "-o", str(out_file)])
        subprocess.run(cmd, check=True)
        generated.append(out_file)

    return generated
