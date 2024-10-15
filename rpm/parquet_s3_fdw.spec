%global sname parquet_s3_fdw

%{!?llvm:%global llvm 0}

Summary:	PGSpider Foreign Data Wrapper (FDW) for the parquets3
Name:		%{sname}_%{pgmajorversion}
Version:	%{?release_version}
Release:	%{?package_release_version}.%{?dist}
License:	TOSHIBA CORPORATION
Source0:	parquet_s3_fdw.tar.bz2
URL:		https://github.com/pgspider/%{sname}
BuildRequires:	pgspider%{pgmajorversion}-devel pgdg-srpm-macros
BuildRequires: arrow >= 12.0.0
BuildRequires: aws_s3_cpp >= 1.11.91
Requires:	pgspider%{pgmajorversion}-server

%description
This PGSpider extension implements a Foreign Data Wrapper (FDW) for the Parquet S3.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for parquet_s3_fdw
Requires:	%{name}%{?_isa} = %{version}-%{release}
%if 0%{?rhel} && 0%{?rhel} == 7
%ifarch aarch64
Requires:	llvm-toolset-7.0-llvm >= 7.0.1
%else
Requires:	llvm5.0 >= 5.0
%endif
%endif
%if 0%{?suse_version} == 1315
Requires:	llvm
%endif
%if 0%{?suse_version} >= 1500
Requires:	llvm10
%endif
%if 0%{?fedora} || 0%{?rhel} >= 8
Requires:	llvm => 5.0
%endif

%description llvmjit
This packages provides JIT support for parquet_s3_fdw
%endif

%prep

%setup -q -n %{sname}-%{version}

%build

USE_PGXS=1 LLVM_CXXFLAGS=-std=c++17 PATH=%{pginstdir}/bin/:$PATH %{__make} with_llvm=no %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}

USE_PGXS=1 LLVM_CXXFLAGS=-std=c++17 PATH=%{pginstdir}/bin/:$PATH %{__make} with_llvm=no %{?_smp_mflags} install DESTDIR=%{buildroot}

# Install README file under PGSpider installation directory:
%{__install} -d %{buildroot}%{pginstdir}/share/extension
%{__install} -m 755 README.md %{buildroot}%{pginstdir}/share/extension/README-%{sname}
%{__rm} -f %{buildroot}%{_docdir}/pgsql/extension/README.md

%clean
%{__rm} -rf %{buildroot}

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%defattr(755,root,root,755)
%doc %{pginstdir}/share/extension/README-%{sname}
%{pginstdir}/lib/%{sname}.so
%{pginstdir}/share/extension/%{sname}--*.sql
%{pginstdir}/share/extension/%{sname}.control

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/%{sname}*.bc
   %{pginstdir}/lib/bitcode/%{sname}/*.bc
   %{pginstdir}/lib/bitcode/%{sname}/src/*.bc
%endif

%changelog
* Wed Nov 8 2023 - 1.0.1
- Init build spec

* Tue Jan 17 2023 hrkuma - 1.0.0
- Features:
-     Support PosgreSQL 15.0
-     Support modify feature
-     Support aws region and endpoint options
- Bug fixes:
-     Fix duplicated data issue when file name contains space
-     Allow insert without key column

* Tue Jun 21 2022 hrkuma - 0.3.0
- Support schemaless feature
- Merge parquet_fdw changes (- 2021 Dec 17)

* Thu Dec 23 2021 hrkuma - 0.2.1
- Support PostgreSQL 14.0

* Mon Dec 6 2021 hrkuma - 0.2
- Support get version
- Merge parquet_fdw changes (- Feb 22)
- Support multi versions test
- Support keep connection control and connection cache information

* Wed Mar 3 2021 t-kataym - 0.1
- This 1st release can work with PostgreSQL 13.
- The code is based on parquet_fdw created by adjust GmbH.
- This FDW supports following features as same as the original parquet_fdw :
-     Support SELECT of parquet file on local file system.
-     Support to create a foreign table for multiple files by specifying file paths.
- This FDW supports following features in addition to the original parquet_fdw :
-     Support SELECT of parquet file on Amazon S3.
-     Support MinIO access instead of Amazon S3.
-     Support to create a foreign table for multiple files in a directory by specifying a directory path.
- The followings are limitations as same as the original parquet_fdw :
-     Modification (INSERT, UPDATE and DELETE) is not supported.
-     Transaction is not supported.
- The followings are limitations for S3 feature :
-     Cannot create a single foreign table using parquet files on both file system and Amazon S3.
-     AWS region is hard-coded as "ap-northeast-1". If you want to use another region, you need to modify the source code by changing "AP_NORTHEAST_1" in parquet_s3_fdw_connection.cpp.
