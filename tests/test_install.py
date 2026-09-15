"""Installer regression tests. All writes stay inside temporary directories."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles test ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.user_dir = self.root / "user"
        self.user_dir.mkdir()
        self.repo = self.root / "repo with spaces"
        shutil.copytree(REPO / "install", self.repo / "install")
        for name in ("fish", "nvim", "tmux", "zed", "ghostty", "bat", "eza", "yazi"):
            (self.repo / "config" / name).mkdir(parents=True)
        for name in (".gitconfig", "zsh/.zshrc", "zsh/.zprofile",
                     "zsh/.zshrc.local.example", "ssh/config", "config/starship.toml",
                     "claude/settings.json", "claude/CLAUDE.md"):
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("fixture\n")
        (self.repo / "ssh/config.d").mkdir()
        (self.repo / "ssh/config.d/host").write_text("Host example\n")
        self.script = self.repo / "install/install.sh"
        # Exclude user startup files and tools; fail loudly on unexpected effects.
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for command in ("curl", "git", "sudo", "chsh", "npm", "fish"):
            stub = self.bin / command
            stub.write_text('#!/bin/sh\necho unexpected-command >&2\nexit 97\n')
            stub.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.user_dir),
                        PATH=f"{self.bin}:/usr/bin:/bin", SHELL="/bin/bash")
        self.env.pop("BASH_ENV", None)
        self.env.pop("ENV", None)

    def run_install(self, *args, code=None, success=True):
        command = ["/bin/bash", str(self.script), *args]
        if code is not None:
            command = ["/bin/bash", "-c", 'source "$1"; ' + code,
                       "test", str(self.script), *args]
        result = subprocess.run(command, env=self.env, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("unexpected-command", result.stderr)
        return result

    def test_full_dry_run_does_not_write_or_download(self):
        self.run_install("--dry-run")
        self.assertEqual(list(self.user_dir.iterdir()), [])

    def test_links_dry_run_does_not_write(self):
        self.run_install("--links-only", "-n")
        self.assertEqual(list(self.user_dir.iterdir()), [])

    def test_links_are_idempotent_and_keep_local_overrides(self):
        local = self.user_dir / ".zshrc.local"
        local.write_text("personal settings\n")
        self.run_install("--links-only")
        self.run_install("--links-only")
        self.assertEqual((self.user_dir / ".config/fish").resolve(), self.repo / "config/fish")
        self.assertEqual(local.read_text(), "personal settings\n")
        self.assertEqual(list(self.user_dir.rglob("*.bak*")), [])
        self.assertEqual((self.user_dir / ".ssh/sockets").stat().st_mode & 0o777, 0o700)
        self.assertEqual((self.user_dir / ".ssh/config.d/host").read_text(), "Host example\n")

    def test_existing_backup_is_preserved(self):
        dst = self.user_dir / ".gitconfig"
        dst.write_text("current")
        backup = self.user_dir / ".gitconfig.bak"
        backup.write_text("older")
        self.run_install("--links-only")
        self.assertEqual(backup.read_text(), "older")
        self.assertEqual((self.user_dir / ".gitconfig.bak.1").read_text(), "current")

    def test_directory_symlink_is_replaced_without_writing_into_target(self):
        target = self.root / "old fish"
        target.mkdir()
        dst = self.user_dir / ".config/fish"
        dst.parent.mkdir()
        dst.symlink_to(target, target_is_directory=True)
        self.run_install("--links-only")
        self.assertEqual(dst.resolve(), self.repo / "config/fish")
        self.assertEqual(list(target.iterdir()), [])
        self.assertEqual(dst.with_name("fish.bak").resolve(), target)

    def test_broken_symlink_and_broken_backup_are_preserved(self):
        dst = self.user_dir / ".gitconfig"
        dst.symlink_to(self.root / "missing")
        backup = dst.with_name(".gitconfig.bak")
        backup.symlink_to(self.root / "also missing")
        self.run_install("--links-only")
        self.assertEqual(os.readlink(backup), str(self.root / "also missing"))
        self.assertEqual(os.readlink(dst.with_name(".gitconfig.bak.1")), str(self.root / "missing"))
        self.assertTrue(dst.exists())

    def test_missing_source_does_not_move_existing_destination(self):
        dst = self.root / "destination"
        dst.write_text("keep me")
        result = self.run_install(str(self.root / "absent"), str(dst),
                                  code='symlink "$2" "$3"', success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(dst.read_text(), "keep me")

    def test_plugins_dry_run_does_not_write_or_download(self):
        self.run_install("--plugins-only", "--dry-run")
        self.assertEqual(list(self.user_dir.iterdir()), [])

    def test_incompatible_modes_fail(self):
        result = self.run_install("--links-only", "--plugins-only", success=False)
        self.assertEqual(result.returncode, 2)

    def test_package_failures_are_reported(self):
        brew = self.bin / "brew"
        brew.write_text("#!/bin/sh\nexit 1\n")
        brew.chmod(0o755)
        result = self.run_install(code='OS=linux; install_packages; finish', success=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("Setup completed with", result.stdout)
        self.assertIn("brew install --formula fish", result.stdout)

    def test_linux_skips_macos_casks(self):
        result = self.run_install(code='OS=linux; DRY_RUN=true; install_packages')
        self.assertNotIn("--cask", result.stdout)
        result = self.run_install(code='OS=macos; DRY_RUN=true; install_packages')
        self.assertIn("--cask ghostty", result.stdout)
        self.assertIn("--cask zed", result.stdout)

    def test_unknown_option_fails_before_writes(self):
        result = self.run_install("--dryrun", success=False)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(list(self.user_dir.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
