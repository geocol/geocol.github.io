
all:
deps:
updatenightly:
	git clone https://github.com/geocol/geocol.github.io && cd geocol.github.io && git checkout origin/builder && make updatenightly
