from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def run_shell(self, script, cwd=None):
        return subprocess.run(
            ["/bin/bash", "-c", f"source {shlex.quote(str(REPO / 'install.sh'))}\n{script}"],
            cwd=cwd,
            text=True,
            capture_output=True,
        )

    def test_brew_failure_stops_installation(self):
        result = self.run_shell('brew() { return 23; }; install_homebrew; echo UNREACHABLE')
        self.assertEqual(result.returncode, 23)
        self.assertNotIn("installation complete", result.stdout)
        self.assertNotIn("UNREACHABLE", result.stdout)

    def test_install_targets_preserve_full_and_partial_setup(self):
        setup = '''
install_homebrew() { echo brew; }
install_shell() { echo shell; }
install_vite_plus() { echo vite; }
install_git() { echo git; }
install_ghostty() { echo ghostty; }
'''
        full = ["brew", "shell", "vite", "git", "ghostty"]
        for target, expected in (("", full), ("all", full), ("install", full),
                                 ("brew", ["brew"]), ("homebrew", ["brew"]),
                                 ("shell", ["shell"]), ("git", ["git"])):
            with self.subTest(target=target):
                result = self.run_shell(setup + f"main {target}")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), expected)

    def test_failed_download_does_not_execute_installer(self):
        result = self.run_shell('''
curl() { return 22; }
fake_shell() { echo UNREACHABLE; }
run_installer fake_shell https://example.invalid/installer
''')
        self.assertEqual(result.returncode, 22)
        self.assertNotIn("UNREACHABLE", result.stdout)

    def test_bundle_uses_repo_from_other_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_shell('brew() { printf "%s\\n" "$@"; }; install_homebrew', directory)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"--file={REPO / 'Brewfile'}", result.stdout)

    def test_git_setup_preserves_existing_includes(self):
        result = self.run_shell('''
stow() { printf '%s\\n' "$@"; }
git() {
  if [ "$*" = 'config --global --get-all include.path' ]; then
    printf '%s\\n' '~/.gitconfig.other' '~/.gitconfig.personal'
  else
    echo UNEXPECTED_GIT_WRITE
  fi
}
install_git
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"--dir={REPO}", result.stdout)
        self.assertNotIn("UNEXPECTED_GIT_WRITE", result.stdout)

    def test_local_startup_survives_installer_additions_and_reruns(self):
        shared = REPO / "zsh/.config/zsh/shared.zsh"
        original_shared = shared.read_bytes()
        with tempfile.TemporaryDirectory() as directory:
            for scenario in ("fresh", "local", "legacy"):
                with self.subTest(scenario=scenario):
                    target_home = Path(directory) / scenario
                    target_home.mkdir()
                    rc = target_home / ".zshrc"
                    if scenario == "local":
                        rc.write_text("export EXISTING_SETTING=kept\n")
                    elif scenario == "legacy":
                        rc.symlink_to(REPO / "zsh/.zshrc")
                    command = ["/bin/bash", str(REPO / "scripts/install-zsh.sh"), str(target_home)]
                    subprocess.run(command, check=True, capture_output=True)
                    self.assertFalse(rc.is_symlink())
                    self.assertEqual((target_home / ".config/zsh/shared.zsh").resolve(), shared)
                    self.assertFalse((target_home / ".config/zsh").is_symlink())
                    if scenario == "local":
                        self.assertIn("EXISTING_SETTING=kept", rc.read_text())
                    with rc.open("a") as stream:
                        stream.write("\nexport INSTALLER_SETTING=local\n")
                    expected = rc.read_bytes()
                    subprocess.run(command, check=True, capture_output=True)
                    self.assertEqual(rc.read_bytes(), expected)
        self.assertEqual(shared.read_bytes(), original_shared)


if __name__ == "__main__":
    unittest.main()
