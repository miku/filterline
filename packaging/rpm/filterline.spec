Summary:    Filter file by line number.
Name:       filterline
Version:    0.1.5
Release:    0
License:    MIT
BuildArch:  x86_64
BuildRoot:  %{_tmppath}/%{name}-build
Group:      System/Base
Vendor:     Leipzig University Library, https://www.ub.uni-leipzig.de
URL:        https://github.com/miku/filterline

%description

filterline: filter file by line number.
http://unix.stackexchange.com/a/209470/376

%prep
# the set up macro unpacks the source bundle and changes in to the represented by
# %{name} which in this case would be my_maintenance_scripts. So your source bundle
# needs to have a top level directory inside called my_maintenance _scripts
# %setup -n %{name}

%build
# this section is empty for this example as we're not actually building anything

%install
# create directories where the files will be located
mkdir -p $RPM_BUILD_ROOT/usr/local/bin

# put the files in to the relevant directories.
# the argument on -m is the permissions expressed as octal. (See chmod man page for details.)
install -m 755 filterline $RPM_BUILD_ROOT/usr/local/bin

%post
# the post section is where you can run commands after the rpm is installed.
# insserv /etc/init.d/my_maintenance

%clean
rm -rf $RPM_BUILD_ROOT
rm -rf %{_tmppath}/%{name}
rm -rf %{_topdir}/BUILD/%{name}

# list files owned by the package here
%files
%defattr(-,root,root)
/usr/local/bin/filterline


%changelog
* Mon Jun 15 2015 Martin Czygan
- 0.1.2, variable line length

* Mon Jun 15 2015 Martin Czygan
- 0.1.1, allow 16 * LINE_MAX lines

* Mon Jun 15 2015 Martin Czygan
- initial release
