"""Offline smoke tests for shell startup and vendored plugin integrity."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class VendorTests(unittest.TestCase):
    def test_vendored_plugins_match_manifest(self):
        root = REPO / 'config/fish/vendor'
        manifest = json.loads((root / 'manifest.json').read_text())
        for name, plugin in manifest.items():
            self.assertRegex(plugin['commit'], r'^[0-9a-f]{40}$')
            for file, expected in plugin['files'].items():
                self.assertEqual(hashlib.sha256((root / name / file).read_bytes()).hexdigest(), expected, file)
            self.assertTrue(any(file.lower().startswith('license') for file in plugin['files']))

    def test_lockfile_is_not_ignored(self):
        result = subprocess.run(
            ['git', 'check-ignore', '--no-index', 'config/nvim/lazy-lock.json'],
            cwd=REPO, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_neovim_lockfile_has_pinned_commits(self):
        lock = json.loads((REPO / 'config/nvim/lazy-lock.json').read_text())
        self.assertIn('LazyVim', lock)
        for plugin in lock.values():
            self.assertRegex(plugin['commit'], r'^[0-9a-f]{40}$')


class ShellTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dotfiles shell ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.config = self.root / 'config'
        shutil.copytree(REPO / 'config/fish', self.config / 'fish',
                        ignore=shutil.ignore_patterns('fish_variables', 'config-local.fish', '__pycache__'))
        shutil.copytree(REPO / 'zsh', self.root / 'zsh')
        # Isolate optional-tool tests from Homebrew installed on the test machine.
        for name in ('config-macos.fish', 'config-linux.fish'):
            (self.config / 'fish' / name).write_text('# platform fixture\n')
        for name in ('.zshrc.macos', '.zshrc.linux'):
            (self.root / 'zsh' / name).write_text('# platform fixture\n')
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.marker = self.root / 'unexpected'
        for name in ('curl', 'git', 'sudo', 'starship', 'zoxide'):
            stub = self.bin / name
            stub.write_text('#!/bin/sh\nprintf "%s\\n" "$0" >> "$DOTFILES_TEST_MARKER"\nexit 91\n')
            stub.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.root), XDG_CONFIG_HOME=str(self.config),
                        XDG_DATA_HOME=str(self.root / 'data'), XDG_CACHE_HOME=str(self.root / 'cache'),
                        PATH=f'{self.bin}:/usr/bin:/bin', TERM='xterm-ghostty',
                        LANG='C', LC_CTYPE='C',
                        DOTFILES_TEST_MARKER=str(self.marker), ZDOTDIR=str(self.root / 'zsh'))
        for name in ('ZSH', 'ZSH_CUSTOM', 'BASH_ENV', 'ENV', 'TMUX', 'CI', 'LC_ALL'):
            self.env.pop(name, None)

    def run_shell(self, shell, code, interactive=False):
        executable = shutil.which(shell)
        if not executable:
            self.skipTest(f'{shell} is not installed')
        args = [executable, '--no-config'] if shell == 'fish' else [executable, '-f']
        if interactive:
            args.append('-i')
        result = subprocess.run(args + ['-c', code], env=self.env, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_shell_syntax(self):
        for shell, paths in (
            ('fish', list((REPO / 'config/fish').rglob('*.fish'))),
            ('zsh', list((REPO / 'zsh').glob('.zshrc*')) + [REPO / 'zsh/.zprofile']),
        ):
            executable = shutil.which(shell)
            if not executable:
                self.skipTest(f'{shell} is not installed')
            for path in paths:
                result = subprocess.run([executable, '-n', str(path)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, f'{path}: {result.stderr}')

    def test_fish_noninteractive_only_sets_environment(self):
        result = self.run_shell('fish', 'source "$XDG_CONFIG_HOME/fish/config.fish"; printf "%s %s" "$TERM" "$EDITOR"')
        self.assertEqual(result.stdout, 'xterm-ghostty nvim')
        self.assertFalse(self.marker.exists())

    def test_zsh_noninteractive_only_sets_environment(self):
        result = self.run_shell('zsh', 'source "$ZDOTDIR/.zshrc"; printf "%s %s" "$TERM" "$EDITOR"')
        self.assertEqual(result.stdout, 'xterm-ghostty nvim')
        self.assertFalse(self.marker.exists())

    def test_shells_preserve_locale_and_local_environment_overrides(self):
        (self.config / 'fish/config-local.fish').write_text(
            'set -gx EDITOR local-editor\nset -gx EZA_CONFIG_DIR /local/eza\n')
        (self.root / '.zshrc.local').write_text(
            'export EDITOR=local-editor\nexport EZA_CONFIG_DIR=/local/eza\n')
        for shell, code in (
            ('fish', 'source "$XDG_CONFIG_HOME/fish/config.fish"; '
             'printf "%s|%s|%s|%s" "$LANG" "$LC_CTYPE" "$EDITOR" "$EZA_CONFIG_DIR"'),
            ('zsh', 'source "$ZDOTDIR/.zshrc"; '
             'printf "%s|%s|%s|%s" "$LANG" "$LC_CTYPE" "$EDITOR" "$EZA_CONFIG_DIR"'),
        ):
            with self.subTest(shell=shell):
                result = self.run_shell(shell, code)
                self.assertEqual(result.stdout, 'C|C|local-editor|/local/eza')
                self.assertEqual(result.stderr, '')

    def test_reloading_shell_config_does_not_duplicate_paths(self):
        for directory in ('bin', '.local/bin', '.bun/bin', '.cargo/bin'):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        for name in ('starship', 'zoxide'):
            (self.bin / name).unlink()
        for shell, code in (
            ('fish', 'source "$XDG_CONFIG_HOME/fish/config.fish"; '
             'source "$XDG_CONFIG_HOME/fish/config.fish"; '
             'printf "%s\\n" $PATH; printf "FUNCTIONS\\n"; printf "%s\\n" $fish_function_path'),
            ('zsh', 'source "$ZDOTDIR/.zshrc"; source "$ZDOTDIR/.zshrc"; '
             'printf "%s\\n" "${path[@]}"'),
        ):
            with self.subTest(shell=shell):
                result = self.run_shell(shell, code, interactive=True)
                paths = result.stdout.split('FUNCTIONS\n')[0].splitlines()
                self.assertEqual(len(paths), len(set(paths)), paths)
                for directory in ('.local/bin', '.bun/bin', '.cargo/bin'):
                    self.assertIn(str(self.root / directory), paths)
                if shell == 'fish':
                    functions = result.stdout.split('FUNCTIONS\n')[1].splitlines()
                    self.assertEqual(len(functions), len(set(functions)), functions)

    def test_zsh_directory_picker_preserves_special_characters(self):
        # Exercise the widget's directory collection without running a real ZLE.
        directory = self.root / 'project [draft] with spaces'
        directory.mkdir()
        for name, body in {
            'ghq': 'printf "%s\\n" "$PICK_DIRECTORY"',
            'fzf': 'while IFS= read -r line; do\n'
                   '  if [ "$line" = "$PICK_DIRECTORY" ]; then printf "%s\\n" "$line"; fi\n'
                   'done',
        }.items():
            stub = self.bin / name
            stub.write_text('#!/bin/sh\n' + body + '\n')
            stub.chmod(0o755)
        for name in ('starship', 'zoxide'):
            (self.bin / name).unlink()
        self.env['PICK_DIRECTORY'] = str(directory)
        result = self.run_shell('zsh', '''
            source "$ZDOTDIR/.zshrc"
            function zle() { :; }
            fzf_change_directory
            printf '%s' "$PWD"
        ''', interactive=True)
        self.assertEqual(result.stdout, str(directory))

    def test_fish_fresh_clone_has_complete_fzf_bindings(self):
        # Init tools are unavailable; only fzf's presence is needed to load bindings.
        for name in ('starship', 'zoxide'):
            (self.bin / name).unlink()
        stub = self.bin / 'fzf'
        stub.write_text('#!/bin/sh\nexit 0\n')
        stub.chmod(0o755)
        result = self.run_shell('fish', '''
            source "$XDG_CONFIG_HOME/fish/config.fish"
            source "$XDG_CONFIG_HOME/fish/functions/fish_user_key_bindings.fish"
            fish_user_key_bindings
            for func in _fzf_search_directory _fzf_search_git_log _fzf_search_git_status _fzf_search_history _fzf_search_processes _fzf_search_variables bass
                functions -q $func; or exit 1
            end
            bind ctrl-r
            printf 'TERM=%s' "$TERM"
        ''', interactive=True)
        self.assertIn('_fzf_search_history', result.stdout)
        self.assertIn('TERM=xterm-ghostty', result.stdout)
        self.assertFalse(self.marker.exists())
        self.assertNotIn('Unknown command', result.stderr)

    def test_zsh_without_omz_starts_offline(self):
        for name in ('starship', 'zoxide'):
            (self.bin / name).unlink()
        result = self.run_shell('zsh', 'source "$ZDOTDIR/.zshrc"; printf "%s" "$TERM"', interactive=True)
        self.assertEqual(result.stdout, 'xterm-ghostty')
        self.assertFalse(self.marker.exists())
        self.assertFalse((self.root / '.oh-my-zsh').exists())
