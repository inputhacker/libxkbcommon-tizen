Name:           libxkbcommon
Version:        0.4.3
Release:        0
License:        MIT
Summary:        Wayland libxkbcommon library
Url:            http://wayland.freedesktop.org/
Group:          Development/Libraries

Source:         %{name}-%{version}.tar.xz
#X-Vcs-Url:     https://github.com/xkbcommon/libxkbcommon.git
Source1001:     libxkbcommon.manifest
BuildRequires:  autoconf >= 2.60
BuildRequires:  automake
BuildRequires:  bison
BuildRequires:  flex
BuildRequires:  libtool >= 2
BuildRequires:  pkgconfig(xorg-macros) >= 1.8
BuildRequires:  python
BuildRequires:  xkb-tizen-data

%global TZ_SYS_RO_SHARE  %{?TZ_SYS_RO_SHARE:%TZ_SYS_RO_SHARE}%{!?TZ_SYS_RO_SHARE:/usr/share}

%description
Keyboard handling library using XKB data.

%package devel
Summary:        Development files for the Wayland libxkbcommon library
Group:          Development/Libraries
Requires:       %{name} = %{version}-%{release}

%description devel
Keyboard handling library using XKB data.

This package contains the development headers for the library found
in %{name}.

%prep
%setup -q
cp %{SOURCE1001} .

# Generate tizen keymap header
export TZ_SYS_RO_SHARE="%{TZ_SYS_RO_SHARE}"
chmod a+x ./make_tizen_keymap.sh
./make_tizen_keymap.sh
chmod a+x ./gen_tables.sh
./gen_tables.sh

%build
%autogen --disable-static --disable-x11
%__make %{?_smp_mflags} V=1;

%install
%make_install

#for license notification
mkdir -p %{buildroot}/%{TZ_SYS_RO_SHARE}/license
cp -a %{_builddir}/%{buildsubdir}/COPYING %{buildroot}/%{TZ_SYS_RO_SHARE}/license/%{name}

%post  -p /sbin/ldconfig

%postun  -p /sbin/ldconfig

%files
%manifest %{name}.manifest
%defattr(-,root,root)
%{TZ_SYS_RO_SHARE}/license/%{name}
%{_libdir}/libxkbcommon.so.0*

%files devel
%manifest %{name}.manifest
%defattr(-,root,root)
%{_includedir}/xkbcommon
%{_libdir}/libxkbcommon.so
%{_libdir}/pkgconfig/xkbcommon.pc

