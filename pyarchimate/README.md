# pyArchimate examples

`examples/generate_claims_model.py` builds a claims-handling model with
[pyArchimate 2.0.2](https://pypi.org/project/pyArchimate/2.0.2/) and writes:

- `examples/out/claims-handling.archimate` — open in Archi with File > Open
- `examples/out/claims-handling.xml` — import in Archi with File > Import > Open Exchange Format

pyArchimate 2.0.2 runs on Python 3.11, 3.12, 3.13, or 3.14. This example was
written with Python 3.13.

`examples/generate_harbor_landscape.py` builds a second model that uses every
ArchiMate element type, including Grouping. It writes:

- `examples/out/harbor-landscape.archimate`
- `examples/out/harbor-landscape.xml`

Open the `.archimate` file in Archi. The views are a context diagram, a
conceptual architecture (motivation and strategy), and a logical architecture
(business, application, technology, physical, and the change roadmap). Each
area is a Grouping element, and the concepts sit inside that box. The script
prints the reloaded counts: 71 elements, 146 relationships, and 3 views.

## Windows from Git Bash

Python and the virtual environment stay in your user profile. Nothing is
installed under Program Files.

Two tools are involved:

- **pyenv-win** installs and switches Python versions. Each version lives under
  `%USERPROFILE%\.pyenv`.
- **venv** is the standard-library command that builds a project environment
  from whichever Python pyenv-win has selected. The environment for this
  example is the `.venv` folder next to `requirements.txt`. Packages installed
  there stay inside that folder.

A venv keeps the Python it was created with. After you switch pyenv-win to
another version, create the venv again.

### 1. Install pyenv-win

Open Git Bash and clone pyenv-win into your home directory:

```bash
git clone --depth 1 https://github.com/pyenv-win/pyenv-win.git "$HOME/.pyenv"
```

That creates `$HOME/.pyenv/pyenv-win`. Add it to Git Bash by appending this
block to `~/.bashrc`:

```bash
export PYENV="$HOME/.pyenv/pyenv-win"
export PYENV_ROOT="$HOME/.pyenv/pyenv-win"
export PYENV_HOME="$HOME/.pyenv/pyenv-win"
export PATH="$PYENV/bin:$PYENV/shims:$PATH"
```

Load the file in the current window:

```bash
source ~/.bashrc
pyenv --version
```

`pyenv --version` prints the pyenv-win version. Every new Git Bash window
reads `~/.bashrc`, so the command stays available.

### 2. Install Python 3.13

List the 3.13 builds pyenv-win can download, then install one:

```bash
pyenv install --list | grep -E '^3\.13\.'
pyenv install 3.13.5
pyenv global 3.13.5
pyenv rehash
```

`pyenv global` writes the choice into your user profile. Close Git Bash, open
it again, and check which interpreter comes first:

```bash
pyenv version
python --version
type -a python
```

`python --version` reports `Python 3.13.5`. `type -a python` lists the shim
under `$HOME/.pyenv/pyenv-win/shims` before any other `python`.

To use a different installed version in one window only:

```bash
pyenv shell 3.12.10
python --version
```

`pyenv shell` lasts until you close the window. `pyenv global 3.13.5` returns
to the default.

### 3. Create the venv

Go to this folder. `python` here is the 3.13.5 selected above, and `venv`
copies that interpreter into `.venv`:

```bash
cd /c/Users/you/Documents/proyectos-dev/archimate-diagram-as-code/pyarchimate
python -m venv .venv
source .venv/Scripts/activate
python --version
```

On Windows the activation script is `.venv/Scripts/activate`. Git Bash runs
that file with `source`. The prompt gains a `(.venv)` prefix, and `python`
and `pip` inside the window are the copies in `.venv/Scripts`.

`.venv` is listed in `.gitignore`.

### 4. Install pyArchimate and generate the model

Stay in the activated environment:

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python examples/generate_claims_model.py
python examples/generate_harbor_landscape.py
```

`requirements.txt` pins `pyArchimate==2.0.2`. The claims script prints the
output paths and the reloaded counts: 14 elements, 17 relationships, and 3
views. The Harbor script prints 71 elements, 146 relationships, and 3 views.

Leave the environment with:

```bash
deactivate
```

### 5. Run it again later

Open Git Bash, go to this folder, and activate the existing venv:

```bash
cd /c/Users/you/Documents/proyectos-dev/archimate-diagram-as-code/pyarchimate
source .venv/Scripts/activate
python examples/generate_claims_model.py
python examples/generate_harbor_landscape.py
```

### 6. Rebuild the venv after changing the Python version

pyenv-win can install another release, for example 3.12.10. The existing
`.venv` still points at 3.13.5 until you create it again:

```bash
pyenv install 3.12.10
pyenv shell 3.12.10
cd /c/Users/you/Documents/proyectos-dev/archimate-diagram-as-code/pyarchimate
rm -rf .venv
python -m venv .venv
source .venv/Scripts/activate
python -m pip install -r requirements.txt
python examples/generate_claims_model.py
python examples/generate_harbor_landscape.py
```

Use a version in the 3.11–3.14 range. pyArchimate 2.0.2 declares that range
as its supported Pythons.
