# `cfg`: Declarative Machine Configuration on Guix

## Goal

`cfg` is a frontend for managing a Guix-based machine with one central rule:

> **Commands may feel imperative, but persistent machine changes must be represented declaratively in Git.**

The dotfiles repository is the source of truth. `cfg` provides a convenient frontend over Guix, Flatpak, Git-sourced packages, Cargo/npm imports, live source checkouts, Git history, and eventually a GUI.

```text
clone dotfiles
    ↓
./bootstrap.sh
    ↓
cfg bootstrap
    ↓
cfg search / add / install / remove / sync / update
    ↓
declarative files change
    ↓
providers reconcile the machine with those declarations
```

Guix remains responsible for reproducible system/package builds whenever possible. `cfg` should avoid becoming a second package manager: it orchestrates providers, generates declarations, resolves external metadata, creates plans, and applies them through the appropriate backend.

---

## Core invariants

### Declarative source of truth

The repository records:

- arbitrary Guix system/Home configuration
- Guix system packages
- Guix Home/user packages
- Guix channel revisions
- Flatpak applications
- Git-sourced packages
- Cargo/npm packages that intentionally remain native
- live source checkouts
- normal application configuration files
- generated/custom Guix package definitions
- lock/resolution information

The machine should be reconstructable from this repository plus intentionally external secrets.

### `sync` and `update` are different

`cfg sync` reconciles **declared configuration/state at the currently locked versions**:

> Does the actual machine match what the repository currently declares?

For Guix this includes `guix home reconfigure` and/or `guix system reconfigure`, so arbitrary Scheme configuration, services, package membership, dotfile mappings, environment variables, boot/system configuration, and other Guix-managed state are applied by `sync`.

It does **not** discover or adopt newer package versions/revisions.

`cfg update` reconciles **versions** of already managed things:

> Are there newer versions/revisions for software that is already declared?

It does **not** add/remove membership solely because the repository and machine differ.

Because changing Guix package/channel versions eventually requires a reconfigure, `cfg update` should detect unapplied Guix configuration changes. If applying the update would also apply unrelated unsynced configuration, it should stop and offer:

```text
[s] sync first
[b] perform sync-update
[d] show diff
[c] cancel
```

`cfg sync-update` computes one combined plan containing both version movement and state/configuration reconciliation, and should avoid redundant rebuilds. Ideally it performs at most one Guix Home reconfigure and one Guix System reconfigure for the final desired state.

The invariant is:

> **`sync` changes state/configuration, never versions. `update` changes versions, never membership. `sync-update` deliberately does both.**

### Git history vs deployed history

Git owns configuration source history:

```text
git restore
git diff
git commit
```

Guix generations own deployed system history:

```text
guix system roll-back
guix home roll-back
```

These are complementary, not replacements for one another.

---

## Suggested repository layout

```text
dotfiles/
├── bootstrap.sh
├── README.md
│
├── cfg/
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs
│       ├── core/
│       ├── protocol/
│       ├── plan/
│       ├── repo/
│       └── git/
│
├── providers/
│   ├── guix/
│   ├── flatpak/
│   ├── git/
│   ├── cargo/
│   ├── npm/
│   └── ...
│
├── guix/
│   ├── system.scm
│   ├── home.scm
│   ├── channels.scm
│   ├── vars.scm
│   │
│   ├── modules/
│   │   ├── desktop.scm
│   │   ├── development.scm
│   │   └── ...
│   │
│   ├── services/
│   │   ├── dotfiles.scm
│   │   ├── island-shell.scm
│   │   └── ...
│   │
│   ├── packages/
│   │   ├── island-shell.scm
│   │   ├── generated-tool.scm
│   │   └── ...
│   │
│   └── generated/
│       ├── packages.scm
│       └── ...
│
├── state/
│   ├── packages.scm
│   ├── lock.scm
│   ├── providers.scm
│   └── sources.scm
│
├── config/
│   ├── nvim/
│   ├── tmux/
│   ├── fish/
│   ├── hypr/
│   ├── island-shell/
│   └── ...
│
├── templates/
│   └── ...
│
├── agents/
│   └── AGENTS.md
│
├── secrets.example.scm
└── .gitignore
```

`system.scm` and `home.scm` do **not** need to live in `/etc`. The repository itself is the canonical configuration location, and the Guix provider invokes Guix directly against those entry points.

A useful ownership rule is:

```text
guix/system.scm
 guix/home.scm
 guix/modules/
 guix/services/
 guix/packages/
     → handwritten arbitrary Guix code
     → cfg does not rewrite it unless explicitly asked

guix/generated/
 state/
     → machine-oriented declarations/locks
     → cfg/providers may edit or regenerate these
```

This preserves the full expressiveness of Guix rather than forcing all system behavior into a schema understood by `cfg`.

---

## Bootstrap

`bootstrap.sh` should stay intentionally small. Its responsibility is only to make `cfg` and the initial provider set available:

```text
1. Find the repository root.
2. Build `cfg`, preferably in a temporary Guix development environment.
3. Build/install/link bundled provider executables.
4. Put them in ~/.local/bin (or another bootstrapped PATH directory).
5. Run `cfg bootstrap`.
```

After bootstrap, normal interaction should go through `cfg`:

```sh
git clone <dotfiles-url> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
cfg bootstrap
cfg sync-update
```

`cfg` knows the repository path and therefore knows where the Guix entry points, provider configuration, state, lock files, configs, and generated package definitions live.

---

## Arbitrary Guix configuration

Guix remains the actual system/home configuration language. `cfg` should **not** attempt to model every possible Guix feature.

Handwritten Scheme remains ordinary Scheme:

```text
guix/system.scm
guix/home.scm
guix/modules/*.scm
guix/services/*.scm
guix/packages/*.scm
```

For example, `system.scm` can import both handwritten modules and cfg-generated package declarations:

```scheme
(use-modules
  (config desktop)
  (config development)
  (config generated packages))

(operating-system
  ...
  (packages
    (append %cfg-system-packages
            %my-extra-packages))

  (services
    (append %desktop-services
            %my-custom-services
            %base-services)))
```

This gives a strict boundary:

```text
Guix
    owns actual system/home behavior

cfg providers
    know how to modify declarations and invoke backends

cfg-core
    plans/orchestrates/reports
```

`cfg` augments Guix; it does not replace Guix with a smaller configuration language.

---

## Live-editable dotfiles

Normal app configs remain normal text files:

```text
~/dotfiles/config/nvim
~/dotfiles/config/hypr
~/dotfiles/config/tmux
~/dotfiles/config/island-shell
```

The **Guix Home configuration**, not `cfg-core`, declares where these are deployed. A custom service such as:

```text
guix/services/dotfiles.scm
```

can describe live mappings conceptually like:

```scheme
(service home-dotfiles-service-type
  (home-dotfiles-configuration
    (root %dotfiles-dir)
    (links
      '((".config/nvim"         . "config/nvim")
        (".config/hypr"         . "config/hypr")
        (".config/tmux"         . "config/tmux")
        (".config/island-shell" . "config/island-shell")))))
```

The deployed state is then:

```text
~/.config/nvim
    → ~/dotfiles/config/nvim
```

so editing:

```sh
nvim ~/.config/nvim/init.lua
```

edits the repository directly and takes effect immediately. Changing file contents behind an already-correct live link does **not** require `cfg sync`.

### Live-editing CLI

`cfg` can provide a Git-aware ergonomic frontend without owning the deployment mechanism:

```sh
cfg edit nvim
cfg path nvim
cfg diff nvim
cfg revert nvim
cfg commit nvim
```

`cfg edit nvim` opens the repository source using `$EDITOR`.

`cfg path nvim` can report:

```text
source: ~/dotfiles/config/nvim
target: ~/.config/nvim
mode:   live
managed by: guix/home
```

`cfg revert nvim` scopes a Git restore to that config and confirms destructive changes:

```text
Revert live configuration:

  M config/nvim/init.lua
  M config/nvim/lua/plugins.lua

Restore these files from HEAD? [y/N]
```

`cfg commit nvim` should commit only that configuration rather than blindly staging unrelated repository changes.

### Config-management helpers

Useful structural commands:

```sh
cfg config list
cfg config info nvim
cfg config add ...
cfg config remove ...
```

These commands do not directly create/remove symlinks. They modify or request a modification to the Guix declaration. The actual deployment happens on `cfg sync` through the Guix provider.

Therefore:

```text
edit content behind an existing live link
    → immediately active
    → no sync required

change the link/mapping itself
    → Guix config changed
    → cfg sync required
```

### Generated configurations

Some apps need literal values generated from Scheme variables. These can use templates:

```text
templates/foo.toml.in
```

For a generated config:

```sh
cfg edit foo
```

opens the source template, not the generated output.

After changing it, `cfg status` reports that regeneration/reconfiguration is required:

```text
CONFIG OUT OF SYNC

  foo
    source template modified
    sync required
```

This gives two explicit deployment modes:

```text
live
    repository ←symlink→ application
    edits are immediately active

generated
    repository template
        ↓ Guix
    deployed generated file
    sync required
```

### Editing Guix itself

Convenience commands can expose the main Guix entry points:

```sh
cfg edit --system
cfg edit --home
```

or provider-specific forms such as:

```sh
cfg guix edit system
cfg guix edit home
```

Changes to arbitrary Guix Scheme are reported as requiring `cfg sync`, unlike ordinary modifications behind already-established live links.

---

## Shared/global variables

`guix/vars.scm` can export values shared by the system and generated configuration:

```scheme
(define-module (config vars)
  #:export (%username
            %home
            %projects-dir))

(define %username "joaogabriel")
(define %home (string-append "/home/" %username))
(define %projects-dir (string-append %home "/projects"))
```

These can feed:

- Guix system configuration
- Guix Home
- generated app configs
- shell environment variables
- custom services
- `cfg` templates

For ordinary programs, environment variables are usually the easiest interoperability layer. For programs requiring literal paths, `cfg` can render templates from these values.

---

## Declarative intent and lock state

Separate **what is desired** from **what exact versions were resolved**.

### `state/packages.scm`

Human intent:

```scheme
'((system
   (guix "hyprland")
   (guix "quickshell")
   (guix "flatpak"))

  (user
   (guix "neovim")
   (guix "tmux")
   (flatpak "com.spotify.Client"))

  (git
   ...))
```

### `state/lock.scm`

Generated and committed:

```scheme
'((channels
   (guix
    (commit "...")
    (fingerprint "...")))

  (git
   (foo
    (revision "87fc1e...")
    (source-hash "sha256-...")))

  ...)
```

The declaration says what to track. The lock file says what exact thing currently represents that declaration.

A nightly declaration does not mean that `sync` should pull the newest commit:

```text
cfg update
    → discover current branch head
    → review it
    → update lock

cfg sync
    → install whatever revision is already locked
```

---

## Provider architecture

`cfg` should be closer to a **microkernel** than a fat package-management CLI.

Core owns only the generic orchestration model:

```text
provider discovery
provider protocol
normalized search/package/update models
plans
confirmation
cross-provider orchestration
repository/state access
Git integration
status aggregation
JSON/frontend API
```

Ecosystem-specific behavior belongs to providers.

Conceptually, every provider offers capabilities equivalent to:

```rust
trait Provider {
    fn metadata(&self) -> ProviderMetadata;

    fn search(&self, query: SearchQuery) -> Result<Vec<SearchResult>>;
    fn resolve(&self, candidate: Candidate) -> Result<ResolvedPackage>;

    fn declared(&self) -> Result<Vec<DeclaredPackage>>;
    fn installed(&self) -> Result<Vec<InstalledPackage>>;
    fn available_updates(&self) -> Result<Vec<UpdateCandidate>>;

    fn plan_sync(&self, ctx: &Context) -> Result<Plan>;
    fn plan_update(&self, ctx: &Context) -> Result<Plan>;

    fn apply(&self, plan: Plan) -> Result<ApplyResult>;
}
```

This is a conceptual model; providers do not need to be Rust libraries.

### External providers by default

A clean design is for even the first-party providers to be separate executables:

```text
cfg
cfg-provider-guix
cfg-provider-flatpak
cfg-provider-git
cfg-provider-cargo
cfg-provider-npm
```

They can still ship together initially, but `cfg-core` does not have privileged provider-specific logic.

Third-party providers can then be added naturally:

```text
cfg-provider-pip
cfg-provider-gem
cfg-provider-go
cfg-provider-opam
...
```

Discovery can happen through:

```text
$PATH
~/.config/cfg/providers/
<dotfiles>/providers/
```

or explicit declarations in `state/providers.scm`.

Example:

```scheme
'((guix
   (enabled #t))

  (flatpak
   (enabled #t))

  (git
   (enabled #t))

  (cargo
   (enabled #t)
   (prefer-import-to-guix #t))

  (npm
   (enabled #t)
   (prefer-import-to-guix #t))

  (aur
   (enabled #f)))
```

The file configures providers; it does not implement them.

### External provider protocol

Providers can communicate using a versioned JSON protocol over stdin/stdout.

A handshake might return:

```json
{
  "protocol": 1,
  "name": "pip",
  "capabilities": [
    "search",
    "resolve",
    "installed",
    "sync",
    "update",
    "import-to-guix"
  ]
}
```

Operations can include:

```text
search
resolve
get-declared
get-installed
get-updates
plan-sync
plan-update
apply
status
```

Providers advertise capabilities rather than making core check provider names:

```text
search
resolve
sync
update
user-scope
system-scope
locking
rollback
import-to-guix
popularity-data
source-package
config-resources
```

This avoids code like:

```rust
if provider == "git" { ... }
```

and allows providers to be implemented in Rust, Scheme, Python, Go, or anything else capable of process I/O.

### Provider management

Useful core commands:

```sh
cfg provider list
cfg provider info <name>
cfg provider enable <name>
cfg provider disable <name>
cfg provider discover
```

The microkernel remains usable even if the set of providers changes completely.

---

## Generic search

`cfg search` searches every enabled provider advertising the `search` capability by default:

```sh
cfg search neovim
```

Example output:

```text
GUIX
  neovim                 0.11.x
  neovim-packer          ...

FLATPAK
  io.neovim.nvim         ...

NPM
  neovim                 ...

CARGO
  ...
```

Results should normally be grouped by provider because popularity/version semantics are not directly comparable across ecosystems.

Filtering always uses the generic provider option:

```sh
cfg search neovim --provider guix

cfg search foo \
    --provider npm \
    --provider cargo
```

The same filtering form applies to other cross-provider commands:

```sh
cfg status --provider guix
cfg sync --provider flatpak
cfg update --provider git --provider flatpak
```

There is no need for hardcoded `--guix`, `--npm`, etc. flags if arbitrary providers are supported.

Machine-readable forms:

```sh
cfg search spotify --json
cfg status --json
cfg plan --json
```

These become the stable interface for a future GUI or other frontends.

---

## Consistent CLI

Provider-specific operations use a **provider-first grammar**:

```text
cfg <provider> <command> ...
```

This avoids ambiguity between provider names and package names and makes arbitrary provider plugins fit naturally.

### Search

Search is intentionally cross-provider and remains at the root:

```sh
cfg search <query>
cfg search <query> --provider <name>
```

### Add

Modify declaration only:

```sh
cfg <provider> add <package>
```

Examples:

```sh
cfg guix add neovim
cfg flatpak add spotify
cfg git add https://github.com/foo/bar
```

No machine change occurs.

### Install

Add declaration and perform targeted reconciliation:

```sh
cfg <provider> install <package>
```

Examples:

```sh
cfg guix install neovim
cfg flatpak install spotify
cfg git install https://codeberg.org/foo/bar
```

### Remove

Remove declaration only:

```sh
cfg <provider> remove <package>
```

### Uninstall

Remove declaration and reconcile it away:

```sh
cfg <provider> uninstall <package>
```

### Scope

The configuration model has three useful scopes:

```text
user
    broadly useful personal software

system
    host-level software/services/configuration

shell
    project-specific development dependencies
```

Default scope is user/Home where the provider supports it:

```sh
cfg guix install neovim
```

Explicit machine-wide scope:

```sh
cfg guix install hyprland --system
```

Project-shell scope:

```sh
cfg guix add cargo-watch --shell
```

`--shell` is preferred over `--local`, because `local` is ambiguous (user-local, machine-local, source-local, or project-local).

Internally:

```text
scope = user | system | shell
```

Providers advertise which scopes they support.

### Guix-specific command exception

Normal providers should remain constrained to the common provider vocabulary (`search`, `add`, `install`, `remove`, `uninstall`, `sync`, `update`, `status`).

Guix is the intentional exception because it is not merely another package source: it is the host System/Home configuration substrate. It may therefore expose dedicated operations such as:

```sh
cfg guix shell
cfg guix rebuild
cfg guix edit
cfg guix generations
cfg guix rollback
cfg guix gc
```

This exception should not become precedent for arbitrary providers to invent separate incompatible DSLs.

### Cross-provider commands

Operations naturally applying to the whole managed machine remain at the root:

```sh
cfg search ...
cfg status
cfg sync
cfg update
cfg sync-update
cfg plan
cfg diff
cfg commit
cfg push
```

A provider-specific sync can be expressed either as:

```sh
cfg guix sync
```

or generically:

```sh
cfg sync --provider guix
```

The first is convenient for direct provider work; the second is useful for generic tooling/scripts.

---

## Project-local Guix environments

Not every development tool belongs in the global user environment.

Broadly useful runtimes/tools can remain installed through Guix Home, for example:

```text
git
neovim
cargo
python
tmux
```

Tools that are only useful for one project should normally live in that project's Guix shell:

```text
cargo-watch
pytest
project-specific Python packages
project-specific npm/Cargo CLIs
Topcoat CLI
project-only linters/generators
```

A preferred project layout is:

```text
~/Projects/foo/
├── .guix/
│   ├── manifest.scm
│   ├── channels.scm       # optional
│   └── packages/          # optional local package definitions
├── .nvim.lua
├── AGENTS.md              # optional project-specific instructions
└── ...
```

The canonical project-local scope flag is:

```text
--shell
```

Examples:

```sh
cfg guix add cargo-watch --shell
cfg guix add python-pytest --shell
```

These modify the current project's Guix shell declaration rather than Guix Home.

Entering the shell:

```sh
cfg guix shell
```

Running one command inside it:

```sh
cfg guix shell -- cargo test
```

A currently running process environment cannot gain newly declared packages retroactively. After changing the manifest, enter a fresh shell or invoke the desired command through a fresh `cfg guix shell -- ...`.

Foreign providers may eventually target the same scope:

```sh
cfg cargo add cargo-watch --shell
cfg pip add ruff --shell
```

Their preferred behavior should still be to import/translate the dependency into the project's Guix environment when practical, rather than creating unrelated global state.

### Global agent instructions

The dotfiles repository should track a canonical global agent policy:

```text
agents/AGENTS.md
```

Guix Home can deploy/link it into whatever locations individual coding-agent tools expect.

The global instructions should tell agents to:

- detect project Guix environments;
- use `cfg guix shell -- <command>` for project build/test/tool execution;
- prefer project-shell dependencies over global installs;
- use `cfg guix add <package> --shell` for project-only tools;
- avoid globally installing something merely to make one project work;
- treat broadly useful tools such as Git, Neovim, Cargo and Python as acceptable Home/user packages.

Project repositories can add their own `AGENTS.md` files for project-specific behavior.

---

## `sync`, `update`, and `sync-update`

### `cfg sync`

`cfg sync` means:

> Make actual provider/system/configuration state match the repository at the **currently locked versions**.

It detects and reconciles:

- declared but missing packages
- installed but undeclared packages
- Guix system/Home configuration drift
- changed services/environment/system settings
- dotfile mapping changes
- generated config changes
- source checkout mismatch
- missing generated Guix packages
- other provider state drift

It does not discover/adopt newer versions.

For the Guix provider, a sync may include:

```text
cfg sync
    ↓
cfg-provider-guix
    ├── guix home reconfigure guix/home.scm
    │     ├── Home/user packages
    │     ├── dotfile mappings
    │     ├── generated configs
    │     ├── environment
    │     ├── user services
    │     └── arbitrary Home Scheme
    │
    └── sudo guix system reconfigure guix/system.scm
          ├── system packages
          ├── services
          ├── kernel/firmware configuration
          ├── filesystems
          ├── boot configuration
          └── arbitrary system Scheme
```

Only the required reconfigurations need run. A Home-only change should not force a full system rebuild.

For undeclared packages:

```text
foo is installed but is not declared.

[y] remove this
[N] keep this
[A] remove all undeclared
[K] keep all undeclared
>
```

Noninteractive forms:

```sh
cfg sync --keep-extra
cfg sync --prune
```

Dirty source checkouts should never be removed automatically.

### Guix applied-state tracking

The Guix provider should remember enough local machine state to distinguish desired source from last-applied state, for example:

```text
~/.local/state/cfg/providers/guix.json
```

Conceptually:

```json
{
  "system_generation": 42,
  "home_generation": 18,
  "system_config_fingerprint": "sha256:...",
  "home_config_fingerprint": "sha256:..."
}
```

This state is machine-local and not committed.

The provider, not core, determines the relevant Guix configuration closure/fingerprint. That allows `cfg status` to report whether arbitrary Scheme changes require a reconfigure without `cfg-core` understanding Scheme.

Live-linked config content is different: changing `config/nvim/init.lua` does not make the Guix link declaration stale, so it is reported as a Git/live config modification rather than as requiring a system reconfigure.

### `cfg update`

`cfg update` advances versions/revisions of **already declared/managed software**.

It may update:

- Guix channel lock/revision
- packages resolved through the newer Guix channel
- Flatpaks
- Git stable/nightly locks
- native Cargo/npm backend locks

It does not add/remove package membership merely because of declaration drift.

A special Guix rule is required: if arbitrary Guix configuration has changed since the last successful sync, applying new Guix versions through a reconfigure would also apply those unrelated configuration changes.

Therefore:

```text
$ cfg update

Cannot perform a clean update.

Guix configuration has unapplied changes:
  M guix/services/desktop.scm

[s] sync first
[b] perform sync-update
[d] show diff
[c] cancel
>
```

This preserves the semantic difference between update and sync.

If configuration is already synchronized, `update` can move Guix channel/package locks and perform the necessary reconfigure to apply those version-only changes.

### `cfg sync-update`

`cfg sync-update` computes a **single combined plan** containing:

```text
available version updates
+
declaration/membership drift
+
Guix configuration drift
+
generated config work
+
provider-specific reconciliation
```

After confirmation, it applies the final desired state.

For Guix it should optimize the operation into the minimum required rebuilds, ideally:

```text
update Guix lock/channel
        +
latest repository configuration
        ↓
one Guix Home reconfigure (if needed)
one Guix System reconfigure (if needed)
```

rather than naïvely doing one rebuild for `update` and another for `sync`.

### Explicit Guix rebuild

Provider-specific escape hatches are still useful:

```sh
cfg guix sync
cfg guix sync --home
cfg guix sync --system
cfg guix sync --force
```

A friendly alias may exist:

```sh
cfg guix rebuild
```

with semantics equivalent to a forced Guix sync/reconfigure rather than introducing a new core concept.

---

## Plans and confirmation

Every state-changing operation should produce a plan before applying.

Example:

```text
$ cfg flatpak install spotify

Resolved:

  Spotify
  provider: Flatpak
  remote: Flathub
  id: com.spotify.Client

Declaration:
  + state/packages.scm: com.spotify.Client

Machine:
  + install com.spotify.Client

Proceed? [Y/n]
```

Alias resolution must always show the canonical package before modification.

The repository stores the canonical ID, not the friendly search term.

---

## Future GUI

The GUI should use the same core as the CLI.

Ideal Rust structure:

```text
cfg-core
    provider model
    declarations
    planning
    reconciliation
    Git integration

cfg-cli
    terminal frontend

cfg-gui
    optional future GUI
```

If the GUI is separate, it can consume stable JSON output:

```sh
cfg search spotify --json
cfg status --json
cfg plan --json
```

The GUI should not parse human terminal text.

This allows an app-store-like frontend whose backend still produces declarative changes through `cfg`.

---

## Git integration

After successful state changes:

```text
Repository changed:

 M state/packages.scm
 M state/lock.scm

[c] commit
[p] commit + push
[d] diff
[N] leave dirty
>
```

Optional commands:

```sh
cfg commit
cfg push
cfg history
```

and automation flags:

```sh
cfg update --commit
cfg update --push
```

Do not make Git commits mandatory. Do not automatically include unrelated dirty live configs in a package-management commit.

---

## Guix and Nonguix

Guix proper follows GNU's free-software distribution policy.

**Nonguix** is a third-party Guix channel for software/firmware that official Guix does not ship under those policies.

For this machine it is relevant for things such as:

- non-free firmware
- NVIDIA support
- Steam and related compatibility packaging
- other software excluded from official Guix

Conceptually:

```text
Guix package universe
├── official Guix channel
├── Nonguix channel
└── local package modules from this repository
```

Nonguix is not equivalent to the AUR. It is much narrower.

---

## Git-sourced packages

The provider is `git`, not `github`.

```sh
cfg git install https://github.com/foo/bar
cfg git install https://codeberg.org/foo/bar
cfg git install https://git.example.org/foo/bar
```

Forge-specific APIs are optional enhancements; plain Git remains the baseline.

### Update policies

A Git package may be:

```text
pinned
stable
nightly
```

#### Pinned

Exact revision/tag; never advances automatically.

#### Stable

Tracks newest matching release/tag:

```scheme
(update
  (stable
    (tag-pattern "^v[0-9]")))
```

#### Nightly

Tracks current head of a branch:

```scheme
(update
  (nightly
    (branch "main")))
```

`cfg update` discovers the candidate and updates the committed lock only after review/application.

### Prefer native Guix packages

For installed source software, prefer generating a normal local Guix package:

```text
git source
    ↓
inspect project
    ↓
generate guix/packages/foo.scm
    ↓
Guix performs isolated build
    ↓
/gnu/store result
```

This gives exact Git revisions, source hashes, isolated builds, generations, rollback, garbage collection, and normal PATH integration.

---

## `~/opt` and live source checkouts

Keep `~/opt`, but give it a different meaning:

```text
~/opt
    = mutable source trees being developed/hacked on

/gnu/store
    = installed packaged software
```

Example:

```sh
cfg git clone https://github.com/foo/bar
```

may create `~/opt/bar` and declare it in `state/sources.scm`.

`cfg status` can detect:

```text
missing declared checkout
undeclared checkout
wrong remote
wrong branch
dirty checkout
```

Never delete a dirty checkout automatically.

A useful graduation path:

```sh
cfg git package bar
```

can inspect the project and generate a native Guix package when it becomes something that should be installed rather than hacked on.

---

## Cargo and npm

Persistent Cargo/npm tools belong in the repository if they are part of the desired machine.

### Preferred behavior: import to Guix

```sh
cfg cargo install cargo-expand
```

should by default attempt:

```text
Cargo metadata/crates.io
    ↓
Guix importer
    ↓
local Guix package
    ↓
normal Guix installation
```

A flag preserves native installation:

```sh
cfg cargo install cargo-expand --keep-cargo
```

Likewise:

```sh
cfg npm install foo
```

can prefer translation/import into Guix when feasible, with:

```sh
cfg npm install foo --keep-npm
```

for a managed npm-global installation.

Native-backend declarations and locks are still committed so they remain reproducible.

Ephemeral commands such as ordinary `npx foo` need not become machine state unless explicitly installed.

---

## AUR compatibility

AUR packages cannot generally be treated as native Guix packages automatically because PKGBUILDs assume Arch package names, the Arch dependency graph, FHS paths, `makepkg`, and arbitrary shell packaging logic.

A best-effort importer can still use a PKGBUILD as a **packaging hint**.

```sh
cfg import aur foo-git
```

may extract:

- upstream Git URL
- description/license
- build system
- build dependencies
- binary paths
- build commands

and generate a first-pass Guix package for review.

### Arch-container escape hatch

For userspace software that is awkward to port:

```text
Guix host
    ↓
managed Arch container
    ├── pacman
    ├── makepkg
    └── paru
```

This preserves access to many AUR programs.

It is not suitable for deeply host-integrated software such as kernel modules, the host NVIDIA driver, bootloaders, filesystem drivers, host system services, or Hyprland plugins tightly coupled to the host ABI.

---

## AI-assisted package maintenance

AI can assist package updates but should never be the root of trust.

For a Git update:

```text
discover candidate release/commit
    ↓
fetch source
    ↓
deterministic structural inspection
    ↓
read changelog/README/commit messages
    ↓
optional LLM analysis
    ↓
isolated Guix build
    ↓
tests/smoke checks
    ↓
show proposed changes
    ↓
user approval
```

The model can inspect:

- old package definition
- source diff
- changelog
- commit messages
- README/build docs
- Cargo.toml/package.json/CMake changes
- build errors

and suggest changes such as binary renames, output-path changes, build-command changes, or new dependencies.

It may propose a patch, but that patch should be reviewable before application.

---

## Security review

AI can help with **security triage**, not certify safety.

Useful deterministic signals include:

- signed/unsigned tags
- source identity
- source hashes
- new dependencies
- dependency-source changes
- new install/postinstall scripts
- new downloaded binaries
- obfuscated/minified additions
- unusual network calls
- permission changes
- build-output changes
- isolated-build result
- tests

An AI summary can explain these signals, but never use:

```text
"LLM says safe" → trusted
```

as a security rule.

---

## Secrets

Secrets must not be placed into Guix store objects.

Avoid embedding API keys in `plain-file`, generated store files, package derivations, etc.

Possible layout:

```text
dotfiles/
├── secrets.example.scm
└── secrets.local.scm       # gitignored
```

or preferably:

```text
secrets.age                 # encrypted and committed
```

with the decryption identity stored separately.

`cfg` can scaffold missing secrets:

```text
Missing secrets.local.scm.
Created template.

Required:
  [ ] llm-api-key

Fill it and rerun:
    cfg update
```

The CLI reads secrets at runtime and passes them only to operations that need them.

---

## Provider classes

A useful initial provider set:

| Provider | Purpose | Long-term preference |
|---|---|---|
| Guix | normal packages and system components | native |
| Flatpak | GUI/proprietary desktop apps | remain Flatpak |
| Git | arbitrary source software | generate Guix package |
| Cargo | Rust ecosystem tools | import to Guix by default |
| npm | Node ecosystem tools | import to Guix when possible |
| AUR container | compatibility escape hatch | migrate away when practical |

Potential future external providers:

```text
pip
gem
go
opam
appimage
brew
```

They can implement the provider protocol without changing core CLI semantics.

---

## Status model

`cfg status` should be one of the most useful commands.

Example:

```text
OUT OF SYNC
  + ripgrep
      declared in Guix Home, not installed

  - org.foo.Bar
      installed Flatpak, undeclared

OUT OF DATE
  neovim
      0.11.3 → 0.11.4

  foo
      git v1.8.2 → v1.9.0

CONFIG
  M config/nvim/init.lua
  M config/hypr/hyprland.conf

SOURCES
  island-shell
      dirty checkout

LOCK
  clean
```

Then:

```text
Suggested:
  cfg sync
  cfg update
```

The tool makes drift obvious without automatically fixing it.

---

### Live vs unapplied configuration in status

`cfg status` should distinguish repository edits that are already active through live links from Guix changes that need reconciliation:

```text
CONFIG REPOSITORY

  M config/nvim/init.lua
      live-linked; already active

GUIX CONFIGURATION

  M guix/services/desktop.scm
      requires sync

GENERATED CONFIG

  M templates/foo.toml.in
      requires sync/regeneration
```

This prevents ordinary live-editing from being mistaken for a pending system rebuild.

---

## Update behavior for Git packages

Stable package:

```text
foo v1.8.2
    ↓
new v1.9.0 tag discovered
    ↓
read changelog/commits
    ↓
inspect structural changes
    ↓
optional AI packaging review
    ↓
attempt isolated Guix build
    ↓
show plan
    ↓
confirm
    ↓
update package definition + lock
```

Nightly package:

```text
main@87fc1e
    ↓
main@c2819a discovered
    ↓
same review/build flow
```

Failures leave the previous lock/install intact.

---

## Transaction philosophy

A complete cross-provider operation cannot be perfectly atomic because Guix, Flatpak, Git, and external ecosystems have different transaction models.

`cfg` should therefore use:

```text
PLAN
    ↓
VALIDATE
    ↓
CONFIRM
    ↓
APPLY
    ↓
VERIFY
    ↓
REPORT
```

Whenever possible:

- update declarations only after successful validation
- keep previous lock state
- use Guix generations for Guix rollback
- do not destroy dirty source trees
- do not automatically commit failed operations
- record exactly which provider operations succeeded

---

## Suggested Rust architecture

A microkernel-oriented layout:

```text
cfg-core/
├── model/
│   ├── package.rs
│   ├── provider.rs
│   ├── config_resource.rs
│   ├── plan.rs
│   └── lock.rs
│
├── protocol/
│   ├── message.rs
│   ├── client.rs
│   └── capability.rs
│
├── providers/
│   ├── discovery.rs
│   └── external.rs
│
├── state/
│   ├── declarations.rs
│   ├── lock.rs
│   └── repository.rs
│
├── reconcile/
├── git/
└── security/

cfg-cli/
└── command parsing + terminal UX

providers/
├── guix/
├── flatpak/
├── git/
├── cargo/
└── npm/

cfg-gui/
└── optional frontend
```

The core exposes normalized operations rather than provider-specific terminal strings:

```rust
enum Operation {
    Search,
    Add,
    Install,
    Remove,
    Uninstall,
    Sync,
    Update,
    Status,
}
```

Each provider process translates normalized requests into ecosystem-specific behavior and returns normalized plans/results.

The GUI and CLI share the same `cfg-core`; neither needs to understand Guix/Flatpak/Cargo details directly.

---

## Example complete workflow

### New machine

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh

cfg bootstrap
cfg status
cfg sync-update
```

### Install Neovim declaratively

```sh
cfg guix install neovim
```

### Install a system package

```sh
cfg guix install hyprland --system
```

### Search everywhere

```sh
cfg search spotify
```

### Search only selected providers

```sh
cfg search prettier \
    --provider npm \
    --provider guix
```

### Install a Flatpak by friendly query

```sh
cfg flatpak install spotify
```

The Flatpak provider resolves the query, displays the canonical ID, asks for confirmation, stores the canonical ID, and installs it.

### Add without installing

```sh
cfg guix add ripgrep
```

Later:

```sh
cfg status
cfg sync
```

### Live-edit Neovim

```sh
cfg edit nvim
```

Because the Guix-declared mapping is already a live symlink, editing the file is immediately active.

Review/revert/commit it with:

```sh
cfg diff nvim
cfg revert nvim
cfg commit nvim
```

### Modify system configuration

```sh
cfg edit --system
```

Then:

```sh
cfg status
cfg sync
```

applies the arbitrary Guix Scheme change through `guix system reconfigure`.

### Force a Guix rebuild

```sh
cfg guix rebuild
```

or equivalently:

```sh
cfg guix sync --force
```

### Track a Git project

```sh
cfg git install https://github.com/foo/bar
```

The Git provider detects the build system, proposes metadata, generates a local Guix package when appropriate, builds it, and records the lock.

### Keep a Cargo tool native

```sh
cfg cargo install cargo-expand --keep-cargo
```

### Live source project

```sh
cfg git clone https://github.com/joaogabrielfer/island-shell
```

Later:

```sh
cfg git package island-shell
```

### Update versions only

```sh
cfg update
```

If unsynced Guix configuration exists, `cfg` offers to sync first or switch to `sync-update`.

### Reconcile state/configuration only

```sh
cfg sync
```

### Fully converge to latest declared state

```sh
cfg sync-update
```

This resolves updates and state drift under one plan and minimizes duplicate Guix rebuilds.

---

## Design principle

The project should stop short of becoming its own package manager or system configuration language.

`cfg-core` owns:

```text
provider discovery/protocol
normalized search and package models
declarative intent/lock orchestration
planning and confirmation
cross-provider coordination
status aggregation
repository/Git workflow
frontend JSON API
AI-assisted review orchestration
```

Providers own:

```text
backend-specific discovery
backend-specific package/state inspection
sync/update planning for their ecosystem
execution against the actual backend
```

Guix owns:

```text
system configuration
Guix Home configuration
services
dotfile mapping/deployment
generated configuration
system/user package declarations
builds/dependencies
generations/rollback
```

Other existing systems own their native mechanics:

```text
Flatpak   → sandboxed desktop application delivery
Cargo     → Rust ecosystem metadata/build fallback
npm       → Node ecosystem fallback
Git       → source transport/history
Arch/AUR  → compatibility escape hatch
```

The core experience is:

> **imperative convenience → declarative source → explicit plan → provider reconciliation**

For the Guix-based setup, the strongest invariant is:

> **Guix remains the authoritative description of the machine; `cfg` is the orchestrator that makes that declarative model comfortable to operate.**

This preserves much of the convenience of Arch/AUR while making machine state visible, reproducible, reviewable, version-controlled, and still fully programmable through arbitrary Guix Scheme.

---

## Notes for later

These are intentional reminders for future configuration work rather than finalized architecture requirements.

### Neovim project-local configuration

Look into Neovim's local `exrc` support / `.nvim.lua` for project-specific behavior, especially:

- project-specific LSP settings;
- local compiler/tool paths;
- project commands;
- project-specific editor behavior.

The goal is to keep the global Neovim configuration focused while allowing projects to declare what is truly project-specific.

### Shell prompt

Change the shell prompt so it reflects the new environment model.

Potential useful prompt state:

```text
current project
Git branch/state
active Guix shell
project shell name
possibly config/system drift indicators
```

Example:

```text
fobos main* [guix:fobos]
❯
```

`cfg guix shell` may set helper variables such as:

```text
CFG_SHELL=1
CFG_PROJECT=fobos
```

so the prompt can detect this reliably.

### Standardize projects under `~/Projects`

Move toward keeping projects under:

```text
~/Projects
```

This gives one predictable root for:

- tmux-sessionizer;
- project discovery;
- agents;
- Guix shell discovery;
- Neovim workflows;
- project tooling.

### Focus workflow around Neovim + tmux-sessionizer

Move the daily project workflow toward:

```text
Neovim
+
tmux
+
tmux-sessionizer
+
~/Projects
+
Guix shells
```

The eventual project-selection flow should naturally provide:

- the project directory;
- a tmux session;
- the project Guix environment;
- `.nvim.lua` / project-specific Neovim behavior;
- project `AGENTS.md` instructions;
- clear shell-prompt environment state.

### Global vs project tools

Keep broadly useful tools globally available through Guix Home, such as:

```text
cargo
python
git
neovim
tmux
```

Prefer project Guix shells for tools only used in a specific repository, such as:

```text
cargo-watch
specific pip packages
Topcoat CLI
linters
generators
project-only CLIs
```

### Agent behavior

Keep the global agent policy tracked at:

```text
dotfiles/agents/AGENTS.md
```

and make it clear that coding agents should use project Guix shells instead of installing project dependencies globally.

### Guix CLI exception

Keep the normal provider command model consistent. Guix remains the one intentional exception and may expose dedicated functionality such as:

```text
shell
rebuild
edit
generations
rollback
gc
```

because Guix is the host configuration substrate, not merely another package provider.

