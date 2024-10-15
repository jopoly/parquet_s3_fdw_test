%global sname aws_s3_cpp

%{!?llvm:%global llvm 1}

Summary:	AWS S3 CPP
Name:		%{sname}
Version:	%{aws_release_version}
Release:	%{?package_release_version}.%{?dist}
License:	Apache 2.0
Source0:	aws-sdk-cpp.tar.bz2
URL:		https://github.com/aws/aws-sdk-cpp
BuildRequires:	libcurl-devel openssl-devel libuuid-devel pulseaudio-libs-devel cmake

%description
This AWS S3 SDK CPP for Rocky Linux 8

%prep
%setup -q -n aws-sdk-cpp-%{version}

%{__cmake} -DBUILD_ONLY="s3" . 

%build

 %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}

%{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

# Install README file under PostgreSQL installation directory:
%{__install} -d %{buildroot}/usr/local/include
%{__install} -d %{buildroot}/usr/local/lib64

%clean
%{__rm} -rf %{buildroot}

%post 
echo '/usr/local/lib64' > /etc/ld.so.conf.d/aws_s3_cpp.conf
/sbin/ldconfig

%postun 
%{__rm} -f /etc/ld.so.conf.d/aws_s3_cpp.conf
/sbin/ldconfig

%files
%defattr(755,root,root,755)
/usr/local/include/*
/usr/local/lib64/*


%changelog
* Wed Nov 8 2023 - 1.1.1
- Init spec
