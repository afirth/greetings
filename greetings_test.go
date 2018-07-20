package greetings

import (
	"strings"
	"testing"
)

var greetingtests = []struct {
	in  string
	out string
}{
	{"joe", "hello, joe"},
	{World, "hello, world"},
}

//Hello should return "hello, <input>"
func TestHello(t *testing.T) {
	for _, tt := range greetingtests {
		got := Hello(tt.in)
		if strings.Compare(tt.out, got) != 0 {
			t.Errorf("got %q, want %q", got, tt.out)
		}
	}
}
