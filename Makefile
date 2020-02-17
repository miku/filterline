TARGETS = filterline

filterline: filterline.c
	cc -Wall -xc -O3 -o filterline filterline.c

.PHONY: format
format:
	clang-format -i -style WebKit filterline.c

.PHONY: clean
clean:
	rm -f filterline
	rm -f filterline_*.deb
	rm -f filterline-*.rpm
	rm -rf packaging/deb/filterline/usr

.PHONY: deb
deb: $(TARGETS)
	mkdir -p packaging/deb/filterline/usr/sbin
	cp $(TARGETS) packaging/deb/filterline/usr/sbin
	cd packaging/deb && fakeroot dpkg-deb --build filterline .
	mv packaging/deb/filterline_*.deb .

.PHONY: rpm
rpm: $(TARGETS)
	mkdir -p $(HOME)/rpmbuild/{BUILD,SOURCES,SPECS,RPMS}
	cp ./packaging/rpm/filterline.spec $(HOME)/rpmbuild/SPECS
	cp $(TARGETS) $(HOME)/rpmbuild/BUILD
	./packaging/rpm/buildrpm.sh filterline
	cp $(HOME)/rpmbuild/RPMS/x86_64/filterline*.rpm .

.PHONY: valgrind
valgrind: clean filterline
	valgrind -v ./filterline fixtures/L fixtures/F
