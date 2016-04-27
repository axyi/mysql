Name: tarantool-mysql
Version: 1.1.0
Release: 1%{?dist}
Summary: MySQL connector for Tarantool
Group: Applications/Databases
License: BSD
URL: https://github.com/tarantool/mysql
Source0: https://github.com/tarantool/%{name}/archive/%{version}/%{name}-%{version}.tar.gz
BuildRequires: cmake >= 2.8
BuildRequires: gcc >= 4.5
BuildRequires: tarantool-devel >= 1.6.8.0
BuildRequires: mariadb-devel >= 5.1.0
Requires: tarantool >= 1.6.8.0

%description
MySQL connector for Tarantool.

%prep
%setup -q -n %{name}-%{version}

%build
%cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo
make %{?_smp_mflags}

## Requires MySQL
#%%check
#make %%{?_smp_mflags} check

%install
%make_install

%files
%{_libdir}/tarantool/*/
%{_datarootdir}/tarantool/*/
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE

%changelog
* Wed Feb 17 2016 Roman Tsisyk <roman@tarantool.org> 1.0.1-1
- Initial version of the RPM spec
