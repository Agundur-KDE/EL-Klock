Name:           elklock
Version:        0.1.0
Release:        1
Summary:        Eternal Lands clock and alerts for KDE Plasma 6
License:        GPL-3.0-only AND LGPL-3.0-only
URL:            https://github.com/Agundur-KDE/EL-Klock
Source0:        elklock-%{version}.tar.gz
BuildArch:      noarch
BuildRequires:  gettext-tools
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
for po in translate/*/*.po; do
    lang=$(basename "$(dirname "$po")")
    mkdir -p "locale/$lang/LC_MESSAGES"
    msgfmt --check-format -o "locale/$lang/LC_MESSAGES/plasma_applet_de.agundur.elklock.mo" "$po"
done

%install
widget=%{buildroot}%{_datadir}/plasma/plasmoids/de.agundur.elklock
mkdir -p "$widget"
cp -a package/metadata.json package/contents LICENSE LICENSES NOTICE.md "$widget/"
cp -a locale "$widget/contents/"
mkdir -p %{buildroot}%{_datadir}/locale
cp -a locale/. %{buildroot}%{_datadir}/locale/

%files
%license LICENSE LICENSES NOTICE.md
%doc README.md
%dir %{_datadir}/plasma
%dir %{_datadir}/plasma/plasmoids
%{_datadir}/plasma/plasmoids/de.agundur.elklock/
%{_datadir}/locale/*/LC_MESSAGES/plasma_applet_de.agundur.elklock.mo
