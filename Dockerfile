FROM opensuse/tumbleweed

RUN zypper --non-interactive install \
      git gcc-c++ python3 cmake kf6-extra-cmake-modules kf6-ki18n-devel kf6-kconfig-devel \
      kf6-kcmutils-devel qt6-quick-devel qt6-test-devel qt6-quicktest-devel \
      qt6-multimedia-imports kf6-kirigami-imports kf6-kcmutils-imports \
      kf6-knotifications-imports gettext-tools ShellCheck \
    && zypper clean --all
