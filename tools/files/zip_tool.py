"""Maya 2.0 - ZIP Tool (create/extract/list archives, workspace-scoped)"""
import zipfile
from .safe_path import resolve_safe_path


class ZipTool:
    def create(self, output_name: str, files: list, **kwargs) -> str:
        if not files:
            return "Error: 'files' list is required"
        try:
            out_path = resolve_safe_path(output_name)
            out_path.parent.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
                for f in files:
                    src = resolve_safe_path(f)
                    if not src.exists():
                        return f"Error: file not found: {f}"
                    zf.write(src, arcname=src.name)
            return f"Created {output_name} with {len(files)} file(s)"
        except ValueError as e:
            return f"Error: {e}"
        except Exception as e:
            return f"Error: could not create zip ({e})"

    def extract(self, zip_name: str, extract_to: str = ".", **kwargs) -> str:
        try:
            zip_path = resolve_safe_path(zip_name)
            if not zip_path.exists():
                return f"Error: zip file not found: {zip_name}"
            dest = resolve_safe_path(extract_to)
            dest.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(zip_path, "r") as zf:
                # Zip-slip guard: reject any entry whose extracted path would
                # land outside `dest`, before extracting anything.
                for member in zf.namelist():
                    member_path = (dest / member).resolve()
                    try:
                        member_path.relative_to(dest.resolve())
                    except ValueError:
                        return f"Error: unsafe path in zip entry: {member}"
                zf.extractall(dest)
            return f"Extracted {zip_name} to {extract_to}"
        except ValueError as e:
            return f"Error: {e}"
        except zipfile.BadZipFile:
            return f"Error: {zip_name} is not a valid zip file"
        except Exception as e:
            return f"Error: could not extract zip ({e})"

    def list_contents(self, zip_name: str, **kwargs) -> str:
        try:
            zip_path = resolve_safe_path(zip_name)
            if not zip_path.exists():
                return f"Error: zip file not found: {zip_name}"
            with zipfile.ZipFile(zip_path, "r") as zf:
                names = zf.namelist()
            return "\n".join(names) if names else "(empty zip)"
        except ValueError as e:
            return f"Error: {e}"
        except zipfile.BadZipFile:
            return f"Error: {zip_name} is not a valid zip file"
        except Exception as e:
            return f"Error: could not read zip ({e})"
