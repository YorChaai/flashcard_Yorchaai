import os
import sys
import json
import subprocess
import webbrowser
import urllib.request
from pathlib import Path

CONFIG_FILE = Path(__file__).parent / "config.json"

DEFAULT_GRAPHIFY_RULE = """## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- For codebase or architecture questions, when `graphify-out/graph.json` exists, first run `graphify query "<question>"` (CLI) or `query_graph` (MCP). Use `graphify path "<A>" "<B>"` / `shortest_path` for relationships and `graphify explain "<concept>"` / `get_node` for focused concepts. These return a scoped subgraph, usually much smaller than `GRAPH_REPORT.md` or raw grep output.
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
"""

DEFAULT_PONYTAIL_RULE = """# Ponytail: The Lazy Senior Developer

Act like the laziest, most pragmatic senior developer in the room. Your motto: **"The best code is the code you never wrote."**
Avoid overengineering, boilerplate, and unnecessary abstraction. Always prefer the simplest, most direct solution.

---

## The 7-Rung Decision Ladder
Before writing or modifying ANY code, climb this ladder rung by rung:

1. **YAGNI (You Aren't Gonna Need It)**: Does this code strictly need to exist to solve the user's request? If no, skip it.
2. **Reuse**: Does an existing function, helper, or widget already do this? Reuse it. Never reinvent the wheel.
3. **Stdlib**: Can the language standard library solve this directly? Use it instead of custom logic.
4. **Native**: Does the framework provide a built-in mechanism? Use native features.
5. **Existing Dependencies**: Can an already-installed package handle this? Do not add new libraries without explicit permission.
6. **One-Liner**: Can this be expressed cleanly in a single line or short expression? Do that.
7. **Minimum Viable Code**: Write the absolute minimum code required to make it work reliably.

---

## Lazy, Not Negligent
- Never compromise on error handling, security, or boundary validation.
- Preserve existing comments and architecture integrity.
"""

DEFAULT_GRAPHIFYIGNORE = """# Folder side / file cadangan lama yang tidak perlu dibaca
side/
backend/side/
frontend/side/

# Archives & Backups
*.rar
*.zip
*.7z
*.tar.gz
*.bak
_backup_/
backup/

# Raw Data, Excel, SQL dumps (Skip raw data to keep code graph clean & fast)
*.xlsx
*.xls
*.csv
*.tsv
*.sql
*.sqlite
*.db
exports/
Sisa/
temp/
tmp/
data/
datasets/

# Document & image dumps (skip non-code files)
*.pdf
*.docx
*.doc
*.pptx
*.png
*.jpg
*.jpeg
*.svg

# Flutter & Dart Build artifacts
.dart_tool/
build/
android/
ios/
linux/
macos/
windows/
web/
.idea/
.flutter-plugins*

# Python caches & virtual environments
__pycache__/
.pytest_cache/
.ruff_cache/
venv/
.venv/
*.pyc

# Logs & large dumps
*.log
analyze_output*.txt
"""

def load_config():
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"last_project_path": r"D:\2. Organize\1. Projects\flashcard"}

def save_config(cfg):
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(cfg, f, indent=2)
    except Exception as e:
        print(f"[!] Gagal menyimpan config: {e}")

def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")

def run_cmd(cmd, cwd=None):
    print(f"\n[>] Menjalankan: {cmd}")
    if cwd:
        print(f"[>] Direktori : {cwd}\n")
    try:
        subprocess.run(cmd, shell=True, cwd=cwd)
    except Exception as e:
        print(f"[!] Error: {e}")
    input("\nTekan Enter untuk melanjutkan...")

def check_9router_status():
    try:
        req = urllib.request.Request("http://127.0.0.1:20128/dashboard")
        with urllib.request.urlopen(req, timeout=1.5) as response:
            if response.status in (200, 307):
                return "RUNNING (Aktif - Port 20128)"
    except Exception:
        pass
    return "STOPPED (Mati)"

def start_9router():
    print("\n[+] Menyalakan 9Router di latar belakang (tray mode)...")
    try:
        if os.name == "nt":
            subprocess.Popen("9router --tray", shell=True, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP)
        else:
            subprocess.Popen(["9router", "--tray"])
        print("[v] Perintah start 9Router telah dikirim.")
    except Exception as e:
        print(f"[!] Gagal menyalakan 9Router: {e}")
    input("\nTekan Enter untuk melanjutkan...")

def stop_9router():
    print("\n[-] Menghentikan proses 9Router...")
    try:
        if os.name == "nt":
            subprocess.run("taskkill /F /IM node.exe /FI \"WINDOWTITLE eq 9router*\"", shell=True)
            print("[v] Proses dihentikan.")
        else:
            subprocess.run("pkill -f 9router", shell=True)
    except Exception as e:
        print(f"[!] Error: {e}")
    input("\nTekan Enter untuk melanjutkan...")

def setup_new_project(project_path):
    p = Path(project_path).resolve()
    if not p.exists() or not p.is_dir():
        print(f"[!] Folder tidak ditemukan: {p}")
        input("Tekan Enter...")
        return

    print(f"\n[*] Mengatur ekosistem di: {p}")
    rules_dir = p / ".agents" / "rules"
    rules_dir.mkdir(parents=True, exist_ok=True)

    # 0. .graphifyignore
    gf_ignore = p / ".graphifyignore"
    if not gf_ignore.exists():
        with open(gf_ignore, "w", encoding="utf-8") as f:
            f.write(DEFAULT_GRAPHIFYIGNORE)
        print("[v] Berhasil membuat .graphifyignore (mengabaikan file Excel, SQL, dan RAR besar)")
    else:
        print("[i] .graphifyignore sudah ada.")

    # 1. graphify.md
    gf_rule = rules_dir / "graphify.md"
    if not gf_rule.exists():
        with open(gf_rule, "w", encoding="utf-8") as f:
            f.write(DEFAULT_GRAPHIFY_RULE)
        print("[v] Berhasil membuat .agents/rules/graphify.md")
    else:
        print("[i] .agents/rules/graphify.md sudah ada.")

    # 2. ponytail.md
    pt_rule = rules_dir / "ponytail.md"
    if not pt_rule.exists():
        with open(pt_rule, "w", encoding="utf-8") as f:
            f.write(DEFAULT_PONYTAIL_RULE)
        print("[v] Berhasil membuat .agents/rules/ponytail.md")
    else:
        print("[i] .agents/rules/ponytail.md sudah ada.")

    # 3. Jalankan graphify scan
    print("[*] Menjalankan pemindaian arsitektur Graphify awal (Mode Code-Only, 100% Gratis & Cepat)...")
    subprocess.run("graphify . --code-only", shell=True, cwd=str(p))
    print(f"\n[v] Selesai! Project {p.name} kini siap digunakan dengan Graphify & Ponytail.")
    input("\nTekan Enter untuk melanjutkan...")

def main():
    cfg = load_config()
    current_proj = cfg.get("last_project_path", r"D:\2. Organize\1. Projects\flashcard")

    while True:
        clear_screen()
        router_status = check_9router_status()
        has_graph = (Path(current_proj) / "graphify-out" / "graph.json").exists()
        graph_status = "TERSEDIA (graphify-out siap)" if has_graph else "BELUM ADA (perlu scan awal)"

        print("=" * 72)
        print("          AI TOOLS CONTROL CENTER (Graphify, Ponytail, 9Router, Playwright)")
        print("=" * 72)
        print(f" [*] Project Aktif : {current_proj}")
        print(f" [*] Status Graph  : {graph_status}")
        print(f" [*] Status 9Router: {router_status}")
        print("-" * 72)
        print(" [ SETUP & PROJECT ]")
        print("   1. Ganti Folder Project Aktif")
        print("   2. Setup 1-Klik Project Baru (Pasang Graphify & Ponytail Otomatis)")
        print()
        print(" [ GRAPHIFY (Navigasi Kode / Sisi IN) ]")
        print("   11. Update Graph (graphify update .) [Cepat & 0 Token]")
        print("   12. Scan Ulang Penuh (graphify .)")
        print("   13. Tanya / Query Hubungan Kode (graphify query)")
        print("   14. Jelaskan Modul / Class Tertentu (graphify explain)")
        print("   15. Buka Visualisasi Interaktif di Browser (graph.html)")
        print("   16. Buka Laporan Arsitektur (GRAPH_REPORT.md)")
        print()
        print(" [ 9ROUTER (Gateway & RTK Token Saver) ]")
        print("   21. Nyalakan 9Router (Tray Mode / Background)")
        print("   22. Buka 9Router Dashboard di Browser (localhost:20128)")
        print("   23. Matikan 9Router")
        print()
        print(" [ PLAYWRIGHT (Browser Testing & Screenshot) ]")
        print("   31. Rekam Aksi Browser Otomatis (CodeGen)")
        print("   32. Ambil Screenshot Website Otomatis")
        print("   33. Buka Browser Uji Coba Cepat (Playwright Open)")
        print("   34. Jalankan Tes Playwright di Folder Ini (playwright test)")
        print()
        print(" [ PONYTAIL (Anti-Overengineering / Sisi OUT) ]")
        print("   41. Salin / Perbarui Rule Ponytail ke Project Ini")
        print("   42. Baca Panduan 7-Rung Ladder Ponytail")
        print()
        print("   0. Keluar")
        print("=" * 72)

        choice = input("Pilih menu (0-42): ").strip()

        if choice == "0":
            print("\nTerima kasih! Sampai jumpa.")
            sys.exit(0)

        elif choice == "1":
            print("\nMasukkan path folder project baru:")
            print("Contoh: D:\\2. Organize\\1. Projects\\MiniProjectKPI_EWI_Revisi2")
            new_path = input("Path: ").strip().strip('"').strip("'")
            if new_path and Path(new_path).exists():
                current_proj = str(Path(new_path).resolve())
                cfg["last_project_path"] = current_proj
                save_config(cfg)
                print(f"[v] Project aktif diubah ke: {current_proj}")
            else:
                print("[!] Path tidak valid atau folder tidak ditemukan!")
            input("Tekan Enter...")

        elif choice == "2":
            print("\nMasukkan path folder project yang ingin di-setup:")
            target = input("Path: ").strip().strip('"').strip("'")
            if not target:
                target = current_proj
            setup_new_project(target)
            current_proj = str(Path(target).resolve())
            cfg["last_project_path"] = current_proj
            save_config(cfg)

        elif choice == "11":
            run_cmd("graphify update .", cwd=current_proj)

        elif choice == "12":
            run_cmd("graphify . --code-only", cwd=current_proj)

        elif choice == "13":
            q = input("\nMasukkan pertanyaan arsitektur: ").strip()
            if q:
                run_cmd(f'graphify query "{q}"', cwd=current_proj)

        elif choice == "14":
            concept = input("\nMasukkan nama class/file/modul: ").strip()
            if concept:
                run_cmd(f'graphify explain "{concept}"', cwd=current_proj)

        elif choice == "15":
            html_file = Path(current_proj) / "graphify-out" / "graph.html"
            if html_file.exists():
                print(f"[v] Membuka {html_file} di browser...")
                webbrowser.open(html_file.as_uri())
            else:
                print(f"[!] File graph.html belum ada di {current_proj}\\graphify-out\\")
                print("    Silakan jalankan Scan Awal (Menu 12) terlebih dahulu.")
            input("Tekan Enter...")

        elif choice == "16":
            md_file = Path(current_proj) / "graphify-out" / "GRAPH_REPORT.md"
            if md_file.exists():
                if os.name == "nt":
                    os.system(f'notepad.exe "{md_file}"')
                else:
                    os.system(f'cat "{md_file}"')
            else:
                print("[!] File GRAPH_REPORT.md belum ditemukan.")
            input("Tekan Enter...")

        elif choice == "21":
            start_9router()

        elif choice == "22":
            print("[v] Membuka dashboard 9Router...")
            webbrowser.open("http://localhost:20128/dashboard")
            input("Tekan Enter...")

        elif choice == "23":
            stop_9router()

        elif choice == "31":
            url = input("\nMasukkan URL target (default: http://localhost:3000): ").strip()
            if not url:
                url = "http://localhost:3000"
            run_cmd(f'npx playwright codegen {url}', cwd=current_proj)

        elif choice == "32":
            url = input("\nMasukkan URL yang ingin di-screenshot: ").strip()
            if not url:
                url = "https://flutter.dev"
            out_img = input("Nama file gambar (default: screenshot.png): ").strip() or "screenshot.png"
            run_cmd(f'npx playwright screenshot {url} "{out_img}"', cwd=current_proj)

        elif choice == "33":
            url = input("\nMasukkan URL yang ingin dibuka: ").strip() or "https://google.com"
            run_cmd(f'npx playwright open {url}', cwd=current_proj)

        elif choice == "34":
            run_cmd("npx playwright test", cwd=current_proj)

        elif choice == "41":
            p = Path(current_proj)
            rules_dir = p / ".agents" / "rules"
            rules_dir.mkdir(parents=True, exist_ok=True)
            with open(rules_dir / "ponytail.md", "w", encoding="utf-8") as f:
                f.write(DEFAULT_PONYTAIL_RULE)
            print(f"[v] Rule Ponytail berhasil disalin ke {rules_dir}\\ponytail.md")
            input("Tekan Enter...")

        elif choice == "42":
            print("\n" + "=" * 60)
            print(DEFAULT_PONYTAIL_RULE)
            print("=" * 60)
            input("\nTekan Enter...")

        else:
            print("[!] Pilihan tidak valid.")
            input("Tekan Enter...")

if __name__ == "__main__":
    main()
