pkgname='caelestia-shell'
pkgver=2.0.0
pkgrel=2
pkgdesc='The desktop shell for the Caelestia dotfiles'
arch=('x86_64' 'aarch64')
url='https://github.com/GwynnN7/caelestia-shell'
license=('GPL-3.0-only')
depends=('caelestia-cli' 'quickshell-git' 'ddcutil' 'brightnessctl' 'app2unit' 'libcava' 'networkmanager'
         'lm_sensors' 'fish' 'aubio' 'libpipewire' 'glibc' 'gcc-libs' 'ttf-material-symbols-variable' 'power-profiles-daemon'
         'ttf-rubik-vf' 'ttf-cascadia-code-nerd' 'swappy' 'libqalculate' 'bash' 'qt6-base' 'qt6-declarative' 'qt6-imageformats')
makedepends=('git' 'cmake' 'ninja' 'qt6-shadertools')
provides=($pkgname)
conflicts=("${pkgname}-git")

source=("git+https://github.com/GwynnN7/${pkgname}.git")
sha256sums=('SKIP')

build() {
    cd "${srcdir}/${pkgname}"

    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/ -DDISTRIBUTOR="AUR (package: $pkgname)" -DVERSION="$pkgver"
    cmake --build build
}

package() {
    cd "${srcdir}/${pkgname}"

    DESTDIR="$pkgdir" cmake --install build
    install -Dm644 LICENSE "$pkgdir"/usr/share/licenses/$pkgname/LICENSE
}