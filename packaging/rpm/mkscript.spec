Name:           mkscript
Version:        1.4.2
Release:        1%{?dist}
Summary:        Create Bash, Terraform, and Ansible starter files safely

License:        MIT
URL:            https://github.com/seriousCoding/mkscript
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  bash
BuildRequires:  make
Requires:       bash

%description
mkscript creates Bash, Terraform, and Ansible starter files with a
default comment header. Bash remains the default template and uses the
standard portable Bash interpreter header. The tool refuses to
overwrite existing files, symbolic links, and directories, can
optionally add a Bash strict-mode line via -s or --strict, and can
create, check, or remove Bash-specific global shortcuts later. The
-f mode can either list matching files under the current tree or look
up commands and filenames directly.

%prep
%autosetup

%build
%make_build

%install
%make_install PREFIX=%{_prefix} DESTDIR=%{buildroot}
rm -f %{buildroot}%{_docdir}/mkscript/README.md
rm -f %{buildroot}%{_docdir}/mkscript/LICENSE

%check
make test

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/mkscript
%{_mandir}/man1/mkscript.1*

%changelog
* Tue Aug 11 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.4.2-1
- Automate patch releases from successful main CI
- Add workflow concurrency and lookup directories

* Tue Aug 11 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.4.1-1
- Fix the -f unreadable-directory test for root-owned RPM %%check runs
- Keep GitHub Actions package and release builds passing in cloud builds

* Tue Aug 11 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.4.0-1
- Add -f lookup mode for commands and filenames
- Accept newline-separated lookup names on stdin for -f
- Keep -f 0 through -f 9 as local listing depth selectors
- Sync INSTALL.md, man page, and package metadata with the updated behavior

* Mon Aug 10 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.3.0-1
- Add Terraform and Ansible starter file templates
- Add -mv to move a Bash script and recreate its managed global link
- Add -f and --files to list matching current-tree files in a table
- Update docs, packaging metadata, and generated formula coverage for the new modes

* Mon Aug 10 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.2.0-1
- Add a default comment header to every newly created script
- Update package smoke tests and Homebrew formula validation

* Mon Aug 10 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.1.0-1
- Add link check and link removal modes
- Prefer a suitable personal macOS bin directory already on PATH
- Add Homebrew formula support and documentation

* Mon Aug 10 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.0.1-1
- Add global and link-only shortcut support
