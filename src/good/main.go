package main

import (
	"fmt"
	"net/url"
	"os"
	"path/filepath"
)

func main() {
	pwd, _ := os.Getwd()
	path := filepath.Join(pwd, "prefix", os.Args[1])

	//gosec says: // filepath.Clean normalizes and removes traversal components
	filename := filepath.Clean(path)
	_, err := os.Stat(filename)
	fmt.Printf("Clean filename=%s error=%v\n", filename, err)

	//gosec says: // filepath.Abs calls Clean internally (per Go docs)
	filename, _ = filepath.Abs(path)
	_, err = os.Stat(filename)
	fmt.Printf("Abs filename=%s error=%v\n", filename, err)

	//gosec says: // url.PathEscape escapes path components
	filename, _ = url.PathUnescape(url.PathEscape(path))
	_, err = os.Stat(filename)
	fmt.Printf("PathEscape filename=%s error=%v\n", filename, err)
}
