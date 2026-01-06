from pathlib import Path

ROOT = Path("assets/avatar")
OUT = Path("assets_pubspec_snippet.yaml")

def main():
    if not ROOT.exists():
        raise SystemExit(f"No existe {ROOT.resolve()}")

    dirs = set()
    for p in ROOT.rglob("*.png"):
        dirs.add(p.parent)

    # Orden estable y en formato YAML
    lines = []
    for d in sorted(dirs, key=lambda x: str(x).lower()):
        # pubspec usa paths con "/"
        lines.append(f"    - {d.as_posix()}/")

    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"✔ Generado: {OUT.resolve()} ({len(lines)} directorios)")

if __name__ == "__main__":
    main()
