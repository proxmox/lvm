RELEASE=2.0

LVMVERSION=2.02.86
DMVERSION=1.02.65
DEBRELEASE=1
# also update debian changelog patch
PVERELEASE=${DEBRELEASE}pve1
PVEVER=${LVMVERSION}-${PVERELEASE}
DMVER=${DMVERSION}-${PVERELEASE}

LVMDIR=lvm2-${LVMVERSION}
LVMSRC=lvm2_${LVMVERSION}.orig.tar.gz
LVMDEBSRC=lvm2_${LVMVERSION}-${DEBRELEASE}.debian.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)


DEBS=							\
	clvm_${PVEVER}_${ARCH}.deb			\
	dmsetup_${DMVER}_${ARCH}.deb			\
	libdevmapper1.02.1_${DMVER}_${ARCH}.deb		\
	libdevmapper-dev_${DMVER}_${ARCH}.deb		\
	liblvm2app2.2_${PVEVER}_${ARCH}.deb		\
	liblvm2cmd2.02_${PVEVER}_${ARCH}.deb		\
	liblvm2-dev_${PVEVER}_${ARCH}.deb		\
	lvm2_${PVEVER}_${ARCH}.deb

all: deb

.PHONY: dinstall
dinstall: deb
	dpkg -i ${DEBS}

.PHONY: deb
deb ${DEBS}: ${LVMSRC} ${LVMDEBSRC}
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

.PHONY: upload
upload:
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -rf /pve/${RELEASE}/extra/clvm_*.deb
	rm -rf /pve/${RELEASE}/extra/lvm2_*.deb
	rm -rf /pve/${RELEASE}/extra/dmsetup_*.deb
	rm -rf /pve/${RELEASE}/extra/liblvm2*.deb
	rm -rf /pve/${RELEASE}/extra/libdevmapper*.deb
	rm -rf /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: clean
clean:
	rm -rf *~ tmpdeb *_${ARCH}.deb *_${ARCH}.udeb *.changes *.dsc ${LVMDIR}
