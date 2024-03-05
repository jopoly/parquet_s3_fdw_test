%global sname arrow

Summary:	Apache arrow
Name:		%{sname}
Version:	%{arrow_release_version}
Release:	%{?dist}
License:	Apache 2.0
Source0:	apache-arrow-%{?arrow_release_version}.tar.gz
URL:		https://github.com/apache/arrow
BuildRequires:	libcurl-devel snappy-devel openssl-devel cmake

%description
This Apache Arrow for Rocky Linux 8

%prep
%setup -q -n arrow-apache-arrow-%{version}

cd cpp
%{__cmake} -DBUILD_SHARED_LIBS=ON -DARROW_PARQUET=ON -DARROW_WITH_SNAPPY=ON -DARROW_WITH_RE2=OFF . 

%build

cd cpp
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}

cd cpp
%{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}


%{__install} -d %{buildroot}/usr/local/include
%{__install} -d %{buildroot}/usr/local/lib64

%clean
%{__rm} -rf %{buildroot}

%post 
echo '/usr/local/lib64' > /etc/ld.so.conf.d/arrow.conf
/sbin/ldconfig

%postun 
%{__rm} -f /etc/ld.so.conf.d/arrow.conf
/sbin/ldconfig

%files
%defattr(755,root,root,755)
/usr/local/include/*
/usr/local/lib64/*
/usr/local/share/doc/arrow/*
/usr/local/share/arrow/gdb/gdb_arrow.py
/usr/local/share/gdb/auto-load/usr/local/lib64/libarrow.so.1200.0.0-gdb.py

%changelog
* Wed Nov 8 2023 - 1.1.1
- Init spec
