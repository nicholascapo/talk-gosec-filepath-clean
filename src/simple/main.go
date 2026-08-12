package main

import (
	"fmt"
	"path/filepath"
)

func main() {
	untrusted := "/../../../etc/passwd"

	fmt.Println(filepath.Clean(untrusted))
	fmt.Println("/path/example" + filepath.Clean(untrusted))
	fmt.Println(filepath.Clean("/path/example/" + untrusted))
	fmt.Println(filepath.Clean(filepath.Join("/", "path", "example", untrusted)))
}
