#import "@preview/slydst:0.1.5": slides // https://typst.app/universe/package/slydst/
#import "@preview/oxdraw:0.1.0": oxdraw // https://typst.app/universe/package/oxdraw
#import "@preview/cades:0.3.1": qr-code // https://typst.app/universe/package/cades/

#let bg = rgb("131723")
#set page(fill: bg)
#set text(fill: rgb("F0F6FC"))
#set text(font: "New Computer Modern")

#show raw.where(block: true): set text(1em / 1.4)

#show: slides.with(
  title: "A Problem in gosec Taint Analysis",
  subtitle: "\"Wait... filepath.Clean() doesn't do that!\"",
  date: none,
  authors: ("Nicholas Capo\nStaff Infrastructure Engineer\nAxios Media",),
  layout: "large",
  ratio: 4 / 3,
  title-color: rgb("77BBFF"),
  subslide-numbering: none,
)

== `gosec`

- "Inspects source code for security problems by scanning the Go AST and SSA code representation."
- Available standalone or as part of `golangci-lint`
- Finds things like:
  - G303 --- Creating tempfile using a predictable path (AST)
  - G403 --- Ensure minimum RSA key length of 2048 bits (AST)
- Added around 2026-02:
  - G7xx: taint analysis rules (SQL injection, command injection, path traversal, SSRF, XSS, log, SMTP injection, SSTI, unsafe deserialization, and open redirect)
  - Specifically:
    - G703 --- Path traversal via taint analysis (Taint)


== SSA

- Static Single-Assignment form
- https://go.dev/src/cmd/compile/internal/ssa/README

#table(
  columns: 3,
  align: (center, center),
  inset: 0.8em,
  "Go", "", "SSA",
  raw("y := 1\ny := 2\nx := y", block: true, lang: "go"),
  sym.arrow,
  raw("y1 := 1\ny2 := 2\nx1 := y2", block: true, lang: "go"),
)

=== Optimizations

https://go.dev/src/cmd/compile/internal/ssa/_gen/generic.rules)

```go
(Not (Neq(64|32|16|8|B|Ptr|64F|32F) x y)) => (Eq(64|32|16|8|B|Ptr|64F|32F) x y)
(Not (Less(64|32|16|8) x y)) => (Leq(64|32|16|8) y x)
```

=== Details
```bash
GOSSAFUNC=Example go build
```

== Taint Analysis

- Analysis takes place at the SSA level
- Uses `golang.org/x/tools/go/analysis.Analyzer`

#oxdraw(
  "graph LR
  in[User Input]
  src(Source)
  san(Sanitizer?)
  sin(Sink)
  boom[Boom!]

  in --> src
  src --> san
  san --> sin
  sin --> boom
  ",
  background: bg,
)

== Sources and Sinks

#link(
  "https://github.com/securego/gosec/blob/master/analyzers/pathtraversal.go#L25",
)[gosec/analyzers/pathtraversal.go:25]

```go
return taint.Config{
	Sources: []taint.Source{
		{Package: "os", Name: "Args", IsFunc: true},
		{Package: "os", Name: "Getenv", IsFunc: true},
	},
	Sinks: []taint.Sink{
		{Package: "os", Method: "Open"},
		{Package: "os", Method: "OpenFile"},
		...
	},
}
```


== Examples

=== Oneliner
```go
f, err := os.Open(os.Getenv("EXAMPLE_PATH"))
```

=== A Little More Complex
```go
pwd, err := os.Getwd()
filename = filepath.Join(pwd, "prefix", os.Args[1])
i, err = os.Stat(filename)
```

== Sanitizers

```go
taint.Config{
	Sanitizers: []taint.Sanitizer{
		// filepath.Clean normalizes and removes traversal components
		{Package: "path/filepath", Method: "Clean"},
		// filepath.Abs calls Clean internally (per Go docs)
		{Package: "path/filepath", Method: "Abs"},
		...
		// url.PathEscape escapes path components
		{Package: "net/url", Method: "PathEscape"},

		// Integer conversions eliminate path traversal vectors entirely —
		// the result can never contain "/" or ".." characters.
		{Package: "strconv", Method: "Atoi"},
		...
	},
}

```

== But!

#emph("filepath.Clean() doesn't do that!")

=== From #link("https://pkg.go.dev/path/filepath#Clean")[pkg.go.dev]:

Clean returns the shortest path name equivalent to path by purely lexical processing. It applies the following rules iteratively until no further processing can be done:

[...]
3. Eliminate each inner `..` path name element (the parent directory) along with the non-`..` element that precedes it.
4. Eliminate `..` elements that begin a rooted path: that is, replace `/..` by `/` at the beginning of a path, assuming Separator is `/`.

=== #emph("Meaning it doesn't so much clean as it does evaluate!")

== A Simple Test

=== `src/simple/main.go`

#raw(read("src/simple/main.go"), block: true, lang: "go")

=== Output
#raw(read("src/simple/output.txt"), block: true, lang: "bash")

= But does `gosec` find these?

== `src/bad/main.go`

#raw(read("src/bad/main.go"), block: true, lang: "go")

== Bad Output

#raw(read("src/bad/output.txt"), block: true, lang: "bash")

== `src/good/main.go`

#raw(read("src/good/main.go"), block: true, lang: "go")

== "Good" Output

#raw(read("src/good/output.txt"), block: true, lang: "bash")

=== Uh Oh!

== The Solution(?)

- Open an issue in `gosec`
- Probably need to change the sanitizers to use `os.Root`

=== From pkg.go.dev:

Root may be used to only access files within a single directory tree.

Methods on Root can only access files and directories beneath a root directory. If any component of a file name passed to a method of Root references a location outside the root, the method returns an error. File names may reference the directory itself (.).

== Links

#table(
  columns: 4,
  align: (center, center),
  inset: 0.8em,
  "Slides and\nSource Code", "Gosec", "Rules", "pathtraversal.go:25",
  qr-code("https://github.com/nicholascapo/talk-gosec-filepath-clean", width: 1.1in),
  qr-code("https://github.com/securego/gosec", width: 1.1in),
  qr-code("https://github.com/securego/gosec/blob/master/RULES.md", width: 1.1in),
  qr-code("https://github.com/securego/gosec/blob/master/analyzers/pathtraversal.go#L25", width: 1.1in),

  "SSA: Go Blog", "SSA: Wikipedia", "SSA: Rules", "os.Root",
  qr-code("https://go.dev/src/cmd/compile/internal/ssa/README", width: 1.1in),
  qr-code("https://en.wikipedia.org/wiki/Static_single-assignment_form", width: 1.1in),
  qr-code("https://go.dev/src/cmd/compile/internal/ssa/_gen/generic.rules", width: 1.1in),
  qr-code("https://pkg.go.dev/os#Root", width: 1.1in),
)
