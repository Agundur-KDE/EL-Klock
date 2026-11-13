Name:           elklock
Version:        %{elklock_version}
Release:        1
Summary:        Eternal Lands clock and alerts for KDE Plasma 6
License:        GPL-3.0-only AND LGPL-3.0-only
URL:            https://github.com/Agundur-KDE/EL-Klock
Source0:        elklock-%{version}.tar.gz
BuildArch:      noarch
Requires:       plasma6-workspace
Requires:       libplasma6-components
Requires:       qt6-declarative-imports
Requires:       qt6-multimedia-imports
Requires:       kf6-kirigami-imports
Requires:       kf6-kcmutils-imports
Requires:       kf6-knotifications-imports

%description
EL-Klock shows Eternal Lands game time, selected Special Day notifications
and recent invasion warnings from Mercator in KDE Plasma 6.
No account or personal token is required.

%prep
%setup -q

%build
# Pure QML and precompiled gettext catalogs; no native code.

%install
mkdir -p %{buildroot}/usr
cp -a usr/share %{buildroot}/usr/

%files
%{_datadir}/plasma/plasmoids/de.agundur.elklock/
%{_datadir}/locale/*/LC_MESSAGES/plasma_applet_de.agundur.elklock.mo
%doc %{_datadir}/doc/elklock/
