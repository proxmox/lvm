

LVMVERSION=2.02.86
LVMRELEASE=1
LVMDIR=lvm2-${LVMVERSION}
LVMSRC=lvm2_${LVMVERSION}.orig.tar.gz
LVMDEBSRC=lvm2_${LVMVERSION}-${LVMRELEASE}.debian.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

all: ${LVMSRC} ${LVMDEBSRC}
	rm -rf ${LVMDIR} tmpdeb
	mkdir tmpdeb
	cd tmpdeb; tar xvf ../${LVMDEBSRC}
	mv tmpdeb/debian/clvm.defaults tmpdeb/debian/clvm.default
	cd tmpdeb; ln -s ../patchdir patches; quilt push -a	
	tar xf ${LVMSRC}
	cp -av tmpdeb/debian ${LVMDIR}
	cd ${LVMDIR}; dpkg-buildpackage -b -uc -us

.PHONY: download
download:
	rm -f ${LVMSRC} ${LVMDEBSRC}
	wget http://ftp.de.debian.org/debian/pool/main/l/lvm2/${LVMSRC}
	wget http://ftp.de.debian.org/debian/pool/main/l/lvm2/${LVMDEBSRC}

.PHONY: clean
clean:
	rm -rf *~ tmpdeb debian/*~ *_${ARCH}.deb *_${ARCH}.udeb *.changes *.dsc ${LVMDIR}
