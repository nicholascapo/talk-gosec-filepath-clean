all: slides.pdf

simple: src/simple/main.go
	go run ./src/simple

bad: src/bad/main.go
	@echo -------------------------------------------
	go run ./src/bad file
	@echo -e \\n-------------------------------------------
	go run ./src/bad ../../../../../../../../../../../../../../etc/passwd
	@echo -e \\n-------------------------------------------
	go run github.com/securego/gosec/v2/cmd/gosec@v2.28.0 --color=false --include G703 ./src/bad

good: src/good/main.go
	@echo -------------------------------------------
	go run ./src/good file
	@echo -e \\n-------------------------------------------
	go run ./src/good ../../../../../../../../../../../../../../etc/passwd
	@echo -e \\n-------------------------------------------
	go run github.com/securego/gosec/v2/cmd/gosec@v2.28.0 --color=false --include G703 ./src/good

gosec:
	go run github.com/securego/gosec/v2/cmd/gosec@latest --color=false --include G703 ./...

src/simple/output.txt: src/simple/main.go
	make simple  | grep -v '^make' | sed 's#go run#$$ go run#' | sed 's#$(CURDIR)/##' > src/simple/output.txt || true

src/bad/output.txt: src/bad/main.go
	make bad     | grep -v '^make' | sed 's#go run#$$ go run#' | sed 's#$(CURDIR)/##' > src/bad/output.txt || true

src/good/output.txt: src/good/main.go
	make good    | grep -v '^make' | sed 's#go run#$$ go run#' | sed 's#$(CURDIR)/##' > src/good/output.txt || true

src/bad/ssa.html: src/bad/main.go
	cd src/bad && GOSSAFUNC=main go build . && rm bad
	touch src/bad/ssa.html

slides.pdf: slides.typ src/simple/output.txt src/bad/output.txt src/good/output.txt src/bad/ssa.html
	which typst && typst compile --creation-timestamp=$(shell date -d 'today 00:00' +%s) slides.typ slides.pdf || docker run --rm --workdir=/src --volume="${CURDIR}:/src/" ghcr.io/typst/typst:0.15.1 compile --creation-timestamp=$(shell date -d 'today 00:00' +%s) slides.typ slides.pdf

watch:
	which typst && typst watch slides.typ slides.pdf || docker run -it --rm --workdir=/src --volume="${CURDIR}:/src/" ghcr.io/typst/typst:0.15.1 watch slides.typ slides.pdf

.PHONY: watch
