package main

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

var (
	styleTitle  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#e6e2d3"))
	styleDim    = lipgloss.NewStyle().Foreground(lipgloss.Color("#8a857a"))
	styleDimLit = lipgloss.NewStyle().Foreground(lipgloss.Color("#a49d8c"))
	styleGreen  = lipgloss.NewStyle().Foreground(lipgloss.Color("#8fce6e"))
	styleRed    = lipgloss.NewStyle().Foreground(lipgloss.Color("#f07a7a"))
	styleYellow = lipgloss.NewStyle().Foreground(lipgloss.Color("#e9c46a"))
	styleOrange = lipgloss.NewStyle().Foreground(lipgloss.Color("#f0a35e"))
	styleCyan   = lipgloss.NewStyle().Foreground(lipgloss.Color("#7ec8e3"))

	styleRowSel = lipgloss.NewStyle().Background(lipgloss.Color("#3a372e")).Foreground(lipgloss.Color("#f4f1e6"))
	styleRow    = lipgloss.NewStyle()

	styleTab      = lipgloss.NewStyle().Padding(0, 1)
	styleTabOn    = lipgloss.NewStyle().Padding(0, 1).Bold(true).Background(lipgloss.Color("#4a4537")).Foreground(lipgloss.Color("#fdfaf0"))
	styleChipOff  = lipgloss.NewStyle().Foreground(lipgloss.Color("#8a857a"))
	styleChipOn   = lipgloss.NewStyle().Bold(true).Background(lipgloss.Color("#4a4537")).Foreground(lipgloss.Color("#fdfaf0"))
	styleTabName  = []string{"Activity", "Prompt", "Report", "Stderr"}
	styleFooter   = lipgloss.NewStyle().Foreground(lipgloss.Color("#8a857a")).Background(lipgloss.Color("#242219"))
	styleToolDone = lipgloss.NewStyle().Foreground(lipgloss.Color("#c8c2b2"))
	styleToolRun  = lipgloss.NewStyle().Foreground(lipgloss.Color("#e9c46a"))
	styleToolErr  = lipgloss.NewStyle().Foreground(lipgloss.Color("#f07a7a"))
)

// spinner frames used for running runs.
var spinnerFrames = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

// glyph returns the status text for one run.
func glyph(r *Run, frame int) string {
	switch r.State {
	case "running":
		return spinnerFrames[frame%len(spinnerFrames)]
	case "done":
		return "✓"
	case "failed":
		return "✗"
	case "blocked":
		return "!"
	case "hung", "timeout", "slow":
		return "⌛"
	case "usage-limit":
		return "⊘"
	default:
		return "?"
	}
}

// glyphStyle gives the status glyph its color.
func glyphStyle(state string) lipgloss.Style {
	switch state {
	case "running":
		return styleCyan
	case "done":
		return styleGreen
	case "failed":
		return styleRed
	case "blocked":
		return styleYellow
	case "hung", "timeout", "slow":
		return styleOrange
	case "usage-limit":
		return styleCyan
	default:
		return styleDim
	}
}

// toolStyle colors a tool row by its status.
func toolStyle(status string) lipgloss.Style {
	switch strings.ToLower(status) {
	case "running", "pending", "queued":
		return styleToolRun
	case "error", "failed", "cancelled", "canceled":
		return styleToolErr
	default:
		return styleToolDone
	}
}
