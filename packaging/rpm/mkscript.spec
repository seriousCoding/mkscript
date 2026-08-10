Name:           mkscript
Version:        1.2.0
Release:        1%{?dist}
Summary:        Create executable Bash script skeletons safely

License:        MIT
URL:            https://github.com/seriousCoding/mkscript
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  bash
BuildRequires:  make
Requires:       bash

%description
mkscript creates executable Bash script files with a standard
#!/usr/bin/env bash shebang and a default comment header. It refuses to
overwrite existing files, symbolic links, and directories, can
optionally add a Bash strict-mode line via -s or --strict, can create
shortcuts for new or existing local scripts, and can check or remove
those shortcuts later.

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
* Mon Aug 10 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.2.0-1
- Add a default comment header to every newly created script
- Update package smoke tests and Homebrew formula validation

* Mon Aug 10 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.1.0-1
- Add link check and link removal modes
- Prefer a suitable personal macOS bin directory already on PATH
- Add Homebrew formula support and documentation

* Mon Aug 10 2026 Richard CodeJunky Townsend <rtownsend.appdesign.dev@gmail.com> - 1.0.1-1
- Add global and link-only shortcut support
