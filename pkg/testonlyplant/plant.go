// Package testonlyplant is TEST ONLY - do not merge. It plants deliberate
// command-injection and path-injection flaws to prove CodeQL catches them.
package testonlyplant

import (
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
)

// Handler is TEST ONLY - do not merge.
func Handler(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("file")
	f, err := os.Open(filepath.Join("/var/data", name))
	if err == nil {
		_ = f.Close()
	}
	out, _ := exec.Command("sh", "-c", r.FormValue("cmd")).CombinedOutput()
	_, _ = w.Write(out)
}
