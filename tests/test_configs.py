"""Parse application configs and load code without plugins or network access."""
import json
import os
from pathlib import Path
import shutil
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
                result = run('source-file', str(config / 'tmux.conf'))
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stderr, '')
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
