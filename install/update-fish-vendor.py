#!/usr/bin/env python3
"""Explicitly refresh a vendored Fish plugin at a full Git commit ID."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import tarfile
import tempfile
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('plugin', choices=('fzf', 'bass'))
    parser.add_argument('commit', help='Full 40-character Git commit SHA')
    args = parser.parse_args()
    if not re.fullmatch(r'[0-9a-f]{40}', args.commit):
        parser.error('commit must be a full lowercase Git SHA')
    root = Path(__file__).resolve().parents[1] / 'config/fish/vendor'
    manifest_path = root / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    repository = manifest[args.plugin]['repository']
    url = repository.replace('https://github.com/', 'https://codeload.github.com/') + '/tar.gz/' + args.commit
    with urllib.request.urlopen(url, timeout=60) as response:
        archive_data = response.read()
    with tempfile.TemporaryDirectory(prefix='dotfiles-vendor-') as temporary:
        staging = Path(temporary) / args.plugin
        staging.mkdir()
        hashes = {}
        with tarfile.open(fileobj=io.BytesIO(archive_data), mode='r:gz') as archive:
            for member in archive.getmembers():
                relative = Path(*Path(member.name).parts[1:])
                if not member.isfile() or relative.is_absolute() or '..' in relative.parts:
                    continue
                if not relative.parts or (relative.parts[0] not in ('functions', 'conf.d', 'completions')
                                          and not relative.name.lower().startswith(('license', 'readme'))):
                    continue
                data = archive.extractfile(member).read()
                path = staging / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                hashes[str(relative)] = hashlib.sha256(data).hexdigest()
        if not any(name.startswith('functions/') for name in hashes):
            raise SystemExit('Archive has no plugin functions; existing vendor files preserved')
        if not any(name.lower().startswith('license') for name in hashes):
            raise SystemExit('Archive has no license; existing vendor files preserved')
        destination = root / args.plugin
        # Preserve the previous version if replacement or manifest writing fails.
        backup = root / (args.plugin + '.previous')
        if backup.exists():
            raise SystemExit(f'Resolve existing update backup first: {backup}')
        destination.rename(backup)
        try:
            shutil.copytree(staging, destination)
            manifest[args.plugin] = {'repository': repository, 'commit': args.commit, 'files': hashes}
            staged_manifest = root / 'manifest.json.tmp'
            staged_manifest.write_text(json.dumps(manifest, indent=2) + '\n')
            staged_manifest.replace(manifest_path)
        except Exception:
            shutil.rmtree(destination, ignore_errors=True)
            backup.rename(destination)
            raise
        shutil.rmtree(backup)
    print(f'Updated {args.plugin} to {args.commit}. Run tests and review the diff before committing.')


if __name__ == '__main__':
    main()
