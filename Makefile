LVMVERSION=2.02.116
DMVERSION=1.02.93
# also update debian changelog patch
PVERELEASE=pve3
PVEVER=${LVMVERSION}-${PVERELEASE}
DMVER=${DMVERSION}-${PVERELEASE}

LVMDIR=LVM2.${LVMVERSION}
#LVMSRC=lvm2_${LVMVERSION}.orig.tar.gz
LVMSRC=${LVMDIR}.tgz

# NOTE: we use debian package definitions from debian jessie
# but use latest upstream sources
LVMDEBSRC=lvm2_2.02.111-2.debian.tar.xz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)


DMPKGLIST:=dmeventd dmsetup libdevmapper1.02.1 libdevmapper-event1.02.1 libdevmapper-dev
LVMPKGLIST:=clvm liblvm2app2.2 liblvm2cmd2.02 liblvm2-dev lvm2

DEBS= 	$(foreach pkg, $(LVMPKGLIST), $(pkg)_${PVEVER}_${ARCH}.deb) \
	$(foreach pkg, $(DMPKGLIST), $(pkg)_${DMVER}_${ARCH}.deb)

all: ${DEBS}

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}

.PHONY: deb
deb ${DEBS}: ${LVMSRC} ${LVMDEBSRC}
	rm -rf ${LVMDIR}
	tar xf ${LVMSRC}
	cd ${LVMDIR}; tar xvf ../${LVMDEBSRC}
	echo "git clone git://git.proxmox.com/git/lvm.git\\ngit checkout ${GITVERSION}" > ${LVMDIR}/debian/SOURCE
	for pkg in $(LVMPKGLIST) $(DMPKGLIST); do echo "debian/SOURCE" >> $(LVMDIR)/debian/$${pkg}.docs; done
	cp -v patchdir/*.patch ${LVMDIR}/debian/patches
	cat patchdir/series >> ${LVMDIR}/debian/patches/series
	cd ${LVMDIR}; dpkg-buildpackage -b -uc -us

.PHONY: download
download:
	rm -f ${LVMSRC}
	wget ftp://sources.redhat.com/pub/lvm2/${LVMSRC}
	#rm -f ${LVMSRC} ${LVMDEBSRC}
	#wget http://ftp.de.debian.org/debian/pool/main/l/lvm2/${LVMSRC}
	#wget http://ftp.de.debian.org/debian/pool/main/l/lvm2/${LVMDEBSRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload

.PHONY: clean
clean:
	rm -rf *~ *_${ARCH}.deb *_${ARCH}.udeb *.changes *.dsc ${LVMDIR}
	find . -name '*~' -exec rm {} ';'
