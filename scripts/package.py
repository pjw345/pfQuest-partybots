"""Build a reproducible AddOn ZIP without repository or test files."""
from pathlib import Path
import re
import zipfile

root = Path(__file__).resolve().parents[1]
addon = root / "pfQuest-partybots"
match = re.search(r"^## Version: ([0-9]+\.[0-9]+\.[0-9]+)$", (addon / "pfQuest-partybots.toc").read_text(), re.M)
if not match:
    raise SystemExit("Missing semantic version in AddOn TOC")
output = root / "dist" / ("pfQuest-partybots-" + match.group(1) + ".zip")
output.parent.mkdir(exist_ok=True)
files = ["Core.lua", "Tracker.lua", "Panel.lua", "pfQuest-partybots.toc", "README.md", "LICENSE"]
with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for name in files:
        info = zipfile.ZipInfo("pfQuest-partybots/" + name, date_time=(2026, 10, 21, 0, 0, 0))
        info.create_system = 3
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        archive.writestr(info, (addon / name).read_bytes())
print(output)
