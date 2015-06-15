TARGETS = filterline

filterline: filterline.c
	cc -Wall -xc -O3 -o filterline filterline.c

clean:
	rm -f filterline
	rm -f filterline_*.deb
	rm -f filterline-*.rpm
	rm -rf packaging/deb/filterline/usr

deb: $(TARGETS)
	mkdir -p packaging/deb/filterline/usr/sbin
	cp $(TARGETS) packaging/deb/filterline/usr/sbin
	cd packaging/deb && fakeroot dpkg-deb --build filterline .
	mv packaging/deb/filterline_*.deb .

rpm: $(TARGETS)
	mkdir -p $(HOME)/rpmbuild/{BUILD,SOURCES,SPECS,RPMS}
	cp ./packaging/rpm/filterline.spec $(HOME)/rpmbuild/SPECS
	cp $(TARGETS) $(HOME)/rpmbuild/BUILD
	./packaging/rpm/buildrpm.sh filterline
	cp $(HOME)/rpmbuild/RPMS/x86_64/filterline*.rpm .

valgrind: filterline
	valgrind ./filterline fixtures/L fixtures/F
