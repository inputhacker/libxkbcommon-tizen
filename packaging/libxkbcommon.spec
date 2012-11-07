Name:           libxkbcommon
Version:        0.0.800
Release:        0
License:        MIT
Summary:        Wayland libxkbcommon library
Url:            http://wayland.freedesktop.org/
Group:          Development/Libraries/C and C++

#Git-Clone:	git://anongit.freedesktop.org/xorg/lib/libxkbcommon
#Git-Web:	http://cgit.freedesktop.org/xorg/lib/libxkbcommon/
Source:         %{name}-%{version}.tar.xz
BuildRequires:  autoconf >= 2.60
BuildRequires:  automake
BuildRequires:  bison
BuildRequires:  flex
BuildRequires:  libtool >= 2
BuildRequires:  pkgconfig
BuildRequires:  xz
BuildRequires:  pkgconfig(kbproto) >= 1.0.4
BuildRequires:  pkgconfig(xorg-macros) >= 1.8
BuildRequires:  pkgconfig(xproto)
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
(Upstream has not provided a description)

%package devel
Summary:        Development files for the Wayland libxkbcommon library
Group:          Development/Libraries/C and C++
Requires:       %{name} = %{version}

%description devel
(Upstream has not provided a description)

This package contains the development headers for the library found
in %{name}.

%prep
%setup -qn %{name}

%build
autoreconf -fi;
%configure --disable-static
make %{?_smp_mflags} V=1;

%install
%make_install

%post  -p /sbin/ldconfig

%postun  -p /sbin/ldconfig

%files
%defattr(-,root,root)
%{_libdir}/libxkbcommon.so.0*

%files devel
%defattr(-,root,root)
%{_includedir}/xkbcommon
%{_libdir}/libxkbcommon.so
%{_libdir}/pkgconfig/xkbcommon.pc

%changelog
