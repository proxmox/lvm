LVMVERSION=2.02.168
DMVERSION=1.02.137
DEBTAG=debian/2.02.168-2

PVERELEASE=pve1
PVELVMVER=${LVMVERSION}-${PVERELEASE}
PVEDMVER=${DMVERSION}-${PVERELEASE}

LVMDIR=LVM2.${LVMVERSION}
LVMSRC=${LVMDIR}.tar

ARCH:=$(shell dpkg-architecture -qDEB_HOST_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DMPKGLIST:=dmeventd dmsetup libdevmapper1.02.1 libdevmapper-event1.02.1 libdevmapper-dev
LVMPKGLIST:=clvm liblvm2app2.2 liblvm2cmd2.02 liblvm2-dev lvm2 python3-lvm2 python-lvm2

DEBS= 	$(foreach pkg, $(LVMPKGLIST), $(pkg)_${PVELVMVER}_${ARCH}.deb) \
	$(foreach pkg, $(DMPKGLIST), $(pkg)_${PVEDMVER}_${ARCH}.deb)

all: ${DEBS}

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}

.PHONY: deb
deb: ${DEBS}
${DEBS}: ${LVMSRC}
	rm -rf ${LVMDIR}
	tar xf ${LVMSRC}
	echo "git clone git://git.proxmox.com/git/lvm.git\\ngit checkout ${GITVERSION}" > ${LVMDIR}/debian/SOURCE
	for pkg in $(LVMPKGLIST) $(DMPKGLIST); do echo "debian/SOURCE" >> $(LVMDIR)/debian/$${pkg}.docs; done
	# Note: the patches in debian/patches are not used by the build process, so apply them manually here!
	cd ${LVMDIR}; ln -s ../patchdir patches
	cd ${LVMDIR}; quilt push -a
	cd ${LVMDIR}; rm -rf .pc ./patches
	mv ${LVMDIR}/debian/changelog ${LVMDIR}/debian/changelog.org
	cat changelog.Debian ${LVMDIR}/debian/changelog.org > ${LVMDIR}/debian/changelog
	cd ${LVMDIR}; dpkg-buildpackage -b -uc -us

.PHONY: download
download:
	rm -f ${LVMSRC}
	rm -rf ${LVMDIR}
	git clone -b ${DEBTAG} https://anonscm.debian.org/cgit/pkg-lvm/lvm2.git/ ${LVMDIR}
	tar cf ${LVMSRC} --exclude ".git" ${LVMDIR}


.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

.PHONY: clean
clean:
	rm -rf *~ *_${ARCH}.deb *_${ARCH}.udeb *.changes *.dsc *.buildinfo ${LVMDIR}
	find . -name '*~' -exec rm {} ';'
