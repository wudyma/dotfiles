"""Parse application configs and load code without plugins or network access."""
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]


class ConfigTests(unittest.TestCase):
    def test_toml_configs(self):
        for path in (REPO / 'config').rglob('*.toml'):
            with self.subTest(path=str(path.relative_to(REPO))):
                with path.open('rb') as stream:
                    tomllib.load(stream)

    def test_json_configs(self):
        # Zed intentionally uses JSON with comments and trailing commas.
        paths = [REPO / 'claude/settings.json', REPO / 'config/nvim/lazy-lock.json',
                 REPO / 'config/fish/vendor/manifest.json',
                 REPO / 'config/windows_terminal/settings.json']
        for path in paths:
            with self.subTest(path=str(path.relative_to(REPO))):
                json.loads(path.read_text(encoding='utf-8'))

    def test_git_attributes_for_windows_scripts(self):
        paths = ('example.cmd', 'example.CMD', 'example.bat', 'example.BAT', 'example.sh')
        result = subprocess.run(['git', 'check-attr', 'eol', '--', *paths], cwd=REPO,
                                capture_output=True, text=True, check=True)
        endings = [line.rsplit(': ', 1)[1] for line in result.stdout.splitlines()]
        self.assertEqual(endings, ['crlf', 'crlf', 'crlf', 'crlf', 'lf'])

    @unittest.skipUnless(shutil.which('oxfmt'), 'oxfmt is not installed')
    def test_zed_jsonc_syntax_and_format(self):
        result = subprocess.run(['oxfmt', '--check', 'config/zed/settings.json'], cwd=REPO,
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('bat') and shutil.which('eza'), 'bat/eza are not installed')
    def test_bat_and_eza_without_user_theme_cache(self):
        with tempfile.TemporaryDirectory(prefix='dotfiles-cli-') as temporary:
            root = Path(temporary)
            sample = root / 'sample.txt'
            sample.write_text('example\n')
            env = dict(os.environ, HOME=temporary, XDG_CONFIG_HOME=str(root / 'config'),
                       XDG_CACHE_HOME=str(root / 'cache'),
                       BAT_CONFIG_PATH=str(REPO / 'config/bat/config'),
                       EZA_CONFIG_DIR=str(REPO / 'config/eza'))
            for command in (
                ['bat', '--paging=never', '--color=never', str(sample)],
                ['eza', '--color=never', '--icons=auto', str(root)],
            ):
                with self.subTest(tool=command[0]):
                    result = subprocess.run(command, env=env, capture_output=True,
                                            text=True, timeout=20)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stderr, '')
                    self.assertNotIn('\x1b[', result.stdout)

    @unittest.skipUnless(shutil.which('starship'), 'Starship is not installed')
    def test_prompt_for_remote_detached_head_and_merge(self):
        with tempfile.TemporaryDirectory(prefix='dotfiles-prompt-') as temporary:
            root = Path(temporary)
            env = dict(os.environ, HOME=temporary, XDG_CACHE_HOME=str(root / 'cache'),
                       STARSHIP_CONFIG=str(REPO / 'config/starship.toml'),
                       GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_NOSYSTEM='1',
                       SSH_CONNECTION='127.0.0.1 12345 127.0.0.1 22', TERM='xterm-256color')

            def run(*command):
                return subprocess.run(command, cwd=root, env=env, capture_output=True,
                                      text=True, timeout=20, check=True)

            run('git', 'init', '-q')
            run('git', '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                '-c', 'commit.gpgSign=false', 'commit', '--allow-empty', '-qm', 'fixture')
            run('git', 'checkout', '--detach', '-q', 'HEAD')
            commit = run('git', 'rev-parse', 'HEAD').stdout.strip()
            (root / '.git/MERGE_HEAD').write_text(commit + '\n')
            result = run('starship', 'prompt', '--cmd-duration', '65000')
            plain = re.sub(r'\x1b\[[0-9;]*m', '', result.stdout)
            self.assertIn('@' + socket.gethostname().split('.')[0], plain)
            self.assertIn(commit[:7], plain)
            self.assertIn('MERGING', plain)
            self.assertIn('in 1m', plain)
            self.assertEqual(result.stderr, '')
            for name in ('SSH_CONNECTION', 'SSH_CLIENT', 'SSH_TTY'):
                env.pop(name, None)
            self.assertEqual(run('starship', 'module', 'hostname').stdout, '')

    @unittest.skipUnless(shutil.which('nvim'), 'Neovim is not installed')
    def test_neovim_lua_syntax(self):
        with tempfile.TemporaryDirectory(prefix='dotfiles-nvim-') as temporary:
            env = dict(os.environ, HOME=temporary, XDG_CONFIG_HOME=temporary,
                       XDG_DATA_HOME=temporary, XDG_STATE_HOME=temporary,
                       XDG_CACHE_HOME=temporary, DOTFILES_LUA_ROOT=str(REPO / 'config/nvim'))
            result = subprocess.run(
                ['nvim', '--headless', '-u', 'NONE', '-i', 'NONE', '-n',
                 '-c', 'lua for _, p in ipairs(vim.fn.glob(vim.env.DOTFILES_LUA_ROOT '
                 '.. "/**/*.lua", false, true)) do local ok, err = loadfile(p); '
                 'if not ok then io.stderr:write(err); vim.cmd("cquit 1") end end',
                 '-c', 'qa!'], env=env, capture_output=True, text=True, timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('tmux'), 'tmux is not installed')
    def test_tmux_load_and_reload_without_plugins(self):
        # A short /tmp path also fits macOS's Unix socket length limit.
        with tempfile.TemporaryDirectory(prefix='dt-', dir='/tmp') as temporary:
            root = Path(temporary)
            config = root / '.config/tmux'
            config.mkdir(parents=True)
            for name in ('tmux.conf', 'macos.conf'):
                shutil.copyfile(REPO / 'config/tmux' / name, config / name)
            env = dict(os.environ, HOME=temporary, SHELL='/bin/sh')
            env.pop('TMUX', None)
            command = ['tmux', '-S', str(root / 'socket')]

            def run(*args):
                return subprocess.run(command + list(args), env=env, capture_output=True,
                                      text=True, timeout=20)

            try:
                result = run('-f', str(config / 'tmux.conf'), 'new-session', '-d',
                             '-s', 'validation', '/bin/sh')
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stderr, '')
                before = run('show-options', '-s', 'terminal-features').stdout
                before_overrides = run('show-options', '-s', 'terminal-overrides').stdout
                result = run('source-file', str(config / 'tmux.conf'))
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stderr, '')
                self.assertEqual(run('show-options', '-s', 'terminal-features').stdout, before)
                self.assertEqual(run('show-options', '-s', 'terminal-overrides').stdout, before_overrides)
                result = run('show-options', '-gv', 'default-terminal')
                self.assertEqual(result.stdout.strip(), 'tmux-256color')
            finally:
                run('kill-server')

    @unittest.skipUnless(shutil.which('nvim'), 'Neovim is not installed')
    def test_neovim_latex_server_restart_and_browser(self):
        with tempfile.TemporaryDirectory(prefix='dotfiles-nvim-') as temporary:
            env = dict(os.environ, HOME=temporary, XDG_CONFIG_HOME=temporary,
                       XDG_DATA_HOME=temporary, XDG_STATE_HOME=temporary,
                       XDG_CACHE_HOME=temporary, DOTFILES_LUA_ROOT=str(REPO / 'config/nvim'))
            for name in ('SSH_CONNECTION', 'SSH_CLIENT', 'SSH_TTY'):
                env.pop(name, None)
            result = subprocess.run(
                ['nvim', '--headless', '-u', 'NONE', '-i', 'NONE', '-n',
                 '-l', str(REPO / 'tests/test_nvim.lua')],
                env=env, capture_output=True, text=True, timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
