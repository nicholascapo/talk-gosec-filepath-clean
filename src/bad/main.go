package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	pwd, _ := os.Getwd()
	filename := filepath.Join(pwd, "prefix", os.Args[1])

	_, err := os.Stat(filename)
	fmt.Printf("stat filename=%s error=%v\n", filename, err)
}
