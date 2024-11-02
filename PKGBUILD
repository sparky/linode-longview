pkgname=linode-longview
pkgver=1.1.5.sparky.2024.11.02
pkgrel=1
pkgdesc="A system monitoring agent for Linode customers."
arch=('any')
url="https://github.com/sparky/$pkgname"
license=('GPL2')
replaces=('longview')
depends=('perl-libwww' 'perl-crypt-ssleay' 'perl-io-socket-inet6'
	'perl-json' 'perl-try-tiny')
optdepends=('perl-dbd-mysql: MySQL support')
backup=('etc/linode/longview.key'
	'etc/linode/longview.d/Apache.conf'
	'etc/linode/longview.d/MySQL.conf'
	'etc/linode/longview.d/Nginx.conf')
install=linode-longview.install
source=("${pkgname}-head::git+file://$PWD")
sha256sums=('SKIP')

pkgver() {
	cd "${pkgname}-head"
	perl -Ilib -MLinode::Longview::Util -e 'print $Linode::Longview::Util::VERSION'
}

package() {
	cd "${pkgname}-head"
	DESTDIR="$pkgdir" TARGET=vendor ./install.sh
}
