Name:           mkscript
Version:        1.0.0
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
#!/usr/bin/env bash shebang. It refuses to overwrite existing files,
symbolic links, and directories, and can optionally add a Bash
strict-mode line via -s or --strict.

%prep
%autosetup

%build
%make_build

%install
%make_install PREFIX=%{_prefix} DESTDIR=%{buildroot}
rm -f %{buildroot}%{_docdir}/mkscript/LICENSE

%check
make test

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/mkscript
%{_mandir}/man1/mkscript.1*

%changelog
* Mon Aug 10 2026 Richard CodeJunky Townsend <seriousCoding@users.noreply.github.com> - 1.0.0-1
- Initial package
