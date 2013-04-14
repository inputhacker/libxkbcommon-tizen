Name:           libxkbcommon
Version:        0.3.0
Release:        0
License:        MIT
Summary:        Wayland libxkbcommon library
Url:            http://wayland.freedesktop.org/
Group:          Development/Libraries

#Git-Clone:	git://anongit.freedesktop.org/xorg/lib/libxkbcommon
#Git-Web:	http://cgit.freedesktop.org/xorg/lib/libxkbcommon/
Source:         %{name}-%{version}.tar.xz
BuildRequires:  autoconf >= 2.60
BuildRequires:  automake
BuildRequires:  bison
BuildRequires:  flex
BuildRequires:  libtool >= 2
BuildRequires:  pkgconfig
BuildRequires:  pkgconfig(kbproto) >= 1.0.4
BuildRequires:  pkgconfig(xorg-macros) >= 1.8
BuildRequires:  pkgconfig(xproto)

%description
Keyboard handling library using XKB data.

%package devel
Summary:        Development files for the Wayland libxkbcommon library
Group:          Development/Libraries
Requires:       %{name} = %{version}

%description devel
Keyboard handling library using XKB data.

This package contains the development headers for the library found
in %{name}.

%prep
%setup -qn %{name}

%build
%autogen
%configure --disable-static
make %{?_smp_mflags} V=1;

%install
%make_install

%post  -p /sbin/ldconfig

%postun  -p /sbin/ldconfig

%files
%defattr(-,root,root)
%license COPYING
%{_libdir}/libxkbcommon.so.0*

%files devel
%defattr(-,root,root)
%{_includedir}/xkbcommon
%{_libdir}/libxkbcommon.so
%{_libdir}/pkgconfig/xkbcommon.pc

%changelog