package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/afirth/greetings"
)

func main() {

	var you string
	if you = filepath.Base(os.Getenv("HOME")); you == "" {
		you = "friend"
	}

	for _, who := range []string{greetings.World, you} {
		fmt.Println(greetings.Hello(who))
	}
}
