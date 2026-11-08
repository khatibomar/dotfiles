package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"
)

// defaultRunsDir resolves $OC_RUNS or ~/.local/state/oc.
func defaultRunsDir() string {
	if v := os.Getenv("OC_RUNS"); v != "" {
		return v
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ".local/state/oc"
	}
	return filepath.Join(home, ".local", "state", "oc")
}

func main() {
	dir := flag.String("dir", defaultRunsDir(), "oc runs directory")
	filter := flag.String("filter", string(filterRunning), "run filter: running, 24h, or all")
	flag.Parse()
	mode, err := parseFilter(*filter)
	if err != nil {
		fmt.Fprintln(os.Stderr, "oc-top:", err)
		os.Exit(2)
	}
	m := newModel(*dir, mode)
	p := tea.NewProgram(m, tea.WithMouseCellMotion())
	if _, err := p.Run(); err != nil {
		fmt.Fprintln(os.Stderr, "oc-top:", err)
		os.Exit(1)
	}
}
