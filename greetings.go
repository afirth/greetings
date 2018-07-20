package greetings

import "strings"

var (
	// World is available for your convenience
	World = "world"
)

// Hello greets in
func Hello(in string) (out string) {
	return strings.Join([]string{
		"hello",
		in,
	}, ", ")
}
