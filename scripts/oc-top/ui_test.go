package main

import (
	"path/filepath"
	"strings"
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

func TestSidebarRowsNeverExceedWidth(t *testing.T) {
	t.Parallel()
	now := time.Now()
	cases := []struct {
		name  string
		state string
		r     *Run
	}{
		{"long running name", "running", &Run{Name: "a-very-long-run-name-that-must-not-overflow", State: "running", Running: true, Started: now.Add(-90 * time.Second), IdleLimit: 300}},
		{"wide hung glyph", "hung", &Run{Name: "smoke", State: "hung", Started: now.Add(-18*time.Minute - 14*time.Second), Seconds: 1094}},
		{"wide spinner", "running", &Run{Name: "w1-219", State: "running", Running: true, Started: now.Add(-18*time.Minute - 14*time.Second), IdleLimit: 300}},
		{"ended", "ended", &Run{Name: "ended-run", State: "ended", Started: now.Add(-3 * time.Minute), Seconds: 180}},
	}
	for _, tc := range cases {
		for _, selected := range []bool{false, true} {
			row := rowHead(tc.r, now, 0, 32, selected)
			if w := lipgloss.Width(row); w > 32 {
				t.Errorf("%s selected=%v: width=%d want <=32 row=%q", tc.name, selected, w, row)
			}
		}
		row := rowHead(tc.r, now, 0, 32, true)
		if !strings.Contains(row, "▌") {
			t.Errorf("%s: selected row misses block marker: %q", tc.name, row)
		}
		if strings.Contains(tc.name, "long") && !strings.Contains(row, "…") {
			t.Errorf("%s: expected truncated ellipsis in %q", tc.name, row)
		}
	}
}

func TestEndedStateFromEvents(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	blocked := filepath.Join(dir, "blocked-20261108-120000-3")
	ended := filepath.Join(dir, "silent-20261108-120000-4")
	writeFile(t, filepath.Join(blocked, "events.jsonl"),
		`{"type":"text","timestamp":1794158473523,"part":{"type":"text","text":"STATUS: blocked"}}`+"\n")
	writeFile(t, filepath.Join(ended, "events.jsonl"),
		`{"type":"text","timestamp":1794158473523,"part":{"type":"text","text":"still thinking"}}`+"\n")

	sc := NewScanner(dir)
	for _, r := range sc.Scan() {
		tail(r)
	}
	for _, r := range sc.Scan() {
		switch r.DirName {
		case "blocked-20261108-120000-3":
			if r.State != "blocked" {
				t.Errorf("blocked run state=%q want blocked", r.State)
			}
		case "silent-20261108-120000-4":
			if r.State != "ended" {
				t.Errorf("silent run state=%q want ended", r.State)
			}
			if glyph(r, 0) != "?" {
				t.Errorf("ended glyph=%q want ?", glyph(r, 0))
			}
			if !strings.Contains(subLine(r), "ended") {
				t.Errorf("ended subline=%q want label ended", subLine(r))
			}
		}
	}
}

func TestTaskLabelFromPrompt(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	runDir := filepath.Join(dir, "task-20261108-120000-9")
	writeFile(t, filepath.Join(runDir, "prompt.txt"),
		"header\nTASK:\nBuild the sidebar and verify status changes\nsecond line\n")
	sc := NewScanner(dir)
	runs := sc.Scan()
	if len(runs) != 1 {
		t.Fatalf("runs=%d want 1", len(runs))
	}
	r := runs[0]
	got := r.displayName()
	if !strings.HasPrefix(got, "Build the sidebar") {
		t.Errorf("displayName=%q want prompt task line", got)
	}
	row := rowHead(r, time.Now(), 0, 32, true)
	if lipgloss.Width(row) > 32 {
		t.Errorf("task label row width=%d want <=32: %q", lipgloss.Width(row), row)
	}
	summary := summaryLine(r)
	if !strings.Contains(summary, "name task") {
		t.Errorf("summary=%q want real name task", summary)
	}
}

func derefModel(tm tea.Model) model {
	switch v := tm.(type) {
	case model:
		return v
	case *model:
		return *v
	default:
		panic("unexpected model type")
	}
}

func TestSelectionFollowsRuns(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "alpha-20261108-120000-1", "report.md"), "OC RUN alpha\nstate=done model=m time=1s session=s\n")
	writeFile(t, filepath.Join(dir, "beta-20261108-120000-2", "report.md"), "OC RUN beta\nstate=done model=m time=1s session=s\n")
	m := newModel(dir, filterAll)
	if before := m.selected(); before == nil {
		t.Fatal("no initial selection")
	}
	before := m.selected().DirName
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'j'}})
	m = derefModel(next)
	after := m.selected().DirName
	if before == after {
		t.Fatalf("selection did not move: %q", after)
	}
	next, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'3'}})
	m = derefModel(next)
	if m.tab != tabReport {
		t.Fatalf("tab=%d want Report", m.tab)
	}
	if m.builtRun != after {
		t.Fatalf("right pane built for %q want selected %q", m.builtRun, after)
	}
}

func TestFooterModes(t *testing.T) {
	t.Parallel()
	m := model{width: 80, height: 20, now: time.Now()}
	f := m.footer()
	if !strings.Contains(f, "? help") {
		t.Errorf("narrow footer=%q want short help with ? hint", f)
	}
	if lipgloss.Width(f) > m.width {
		t.Errorf("narrow footer width=%d want <=%d", lipgloss.Width(f), m.width)
	}
	m.helpFull = true
	f = m.footer()
	if !strings.Contains(f, "j/k runs") {
		t.Errorf("full footer=%q want full help", f)
	}
	if lipgloss.Width(f) > m.width {
		t.Errorf("full footer width=%d want <=%d", lipgloss.Width(f), m.width)
	}
}

func TestFilterModes(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 11, 8, 19, 30, 0, 0, time.Local)
	cases := []struct {
		name string
		r    *Run
		mode filterMode
		want bool
	}{
		{"running old", &Run{Running: true, Started: now.Add(-100 * time.Hour)}, filterRunning, true},
		{"recent not running", &Run{Started: now.Add(-23 * time.Hour)}, filterRunning, false},
		{"running old in 24h", &Run{Running: true, Started: now.Add(-100 * time.Hour)}, filter24h, true},
		{"recent in 24h", &Run{Started: now.Add(-23 * time.Hour)}, filter24h, true},
		{"old in all", &Run{Started: now.Add(-100 * time.Hour)}, filterAll, true},
		{"old in 24h", &Run{Started: now.Add(-25 * time.Hour)}, filter24h, false},
	}
	for _, tc := range cases {
		if got := keepRun(tc.r, now, tc.mode); got != tc.want {
			t.Errorf("%s: keepRun=%v want %v", tc.name, got, tc.want)
		}
	}
	parseCases := []struct {
		in   string
		want filterMode
	}{
		{"running", filterRunning},
		{"Running", filterRunning},
		{"24h", filter24h},
		{"all", filterAll},
	}
	for _, tc := range parseCases {
		got, err := parseFilter(tc.in)
		if err != nil || got != tc.want {
			t.Errorf("parseFilter(%q)=%v,%v want %v", tc.in, got, err, tc.want)
		}
	}
	if _, err := parseFilter("everything"); err == nil {
		t.Error("parseFilter(everything) err=nil want error")
	}
	if nextFilter(filterRunning) != filter24h || nextFilter(filter24h) != filterAll || nextFilter(filterAll) != filterRunning {
		t.Errorf("nextFilter order is wrong")
	}
}

func TestScrollOffsetClamp(t *testing.T) {
	t.Parallel()
	cases := []struct {
		offset, total, height, want int
	}{
		{-5, 100, 10, 0},
		{5, 100, 10, 5},
		{999, 100, 10, 90},
		{999, 10, 10, 0},
		{5, 0, 10, 0},
		{5, 100, 0, 0},
	}
	for _, tc := range cases {
		if got := clampYOffset(tc.offset, tc.total, tc.height); got != tc.want {
			t.Errorf("clampYOffset(%d,%d,%d)=%d want %d", tc.offset, tc.total, tc.height, got, tc.want)
		}
	}
}

func TestFollowToggleOnScroll(t *testing.T) {
	t.Parallel()
	content := strings.Repeat("line\n", 80)
	newM := func(follow bool) model {
		m := model{width: 120, height: 20, follow: follow, yoffsets: map[string]int{}}
		m.resizeViewport()
		m.vp.SetContent(content)
		return m
	}
	m := newM(true)
	m.vp.GotoBottom()
	m.updateKeys(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'K'}})
	if m.follow {
		t.Error("K did not turn follow off")
	}
	m = newM(true)
	m.vp.GotoBottom()
	m.updateKeys(tea.KeyMsg{Type: tea.KeyPgUp})
	if m.follow {
		t.Error("pgup did not turn follow off")
	}
	m = newM(true)
	m.vp.GotoBottom()
	m.updateKeys(tea.KeyMsg{Type: tea.KeyCtrlU})
	if m.follow {
		t.Error("ctrl+u did not turn follow off")
	}
	m = newM(true)
	m.vp.GotoBottom()
	next, _ := m.Update(tea.MouseMsg{Button: tea.MouseButtonWheelUp, Action: tea.MouseActionPress, X: 50, Y: 5})
	m = derefModel(next)
	if m.follow {
		t.Error("wheel up did not turn follow off")
	}
	m = newM(false)
	m.vp.GotoTop()
	m.updateKeys(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'G'}})
	if !m.follow {
		t.Error("G did not turn follow on")
	}
	if m.vp.YOffset != m.vp.TotalLineCount()-m.vp.Height {
		t.Errorf("G offset=%d want bottom", m.vp.YOffset)
	}
	m = newM(false)
	m.vp.GotoTop()
	m.updateKeys(tea.KeyMsg{Type: tea.KeyEnd})
	if !m.follow {
		t.Error("end did not turn follow on")
	}
	m = newM(false)
	m.vp.GotoBottom()
	m.updateKeys(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'g'}})
	if m.follow || m.vp.YOffset != 0 {
		t.Errorf("g follow=%v offset=%d want off/0", m.follow, m.vp.YOffset)
	}
}

func TestPerTabScrollOffsets(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	runDir := filepath.Join(dir, "one-20261108-120000-1")
	lines := func(prefix string) string {
		var b strings.Builder
		for i := 0; i < 40; i++ {
			b.WriteString(prefix + " " + strings.Repeat("x", i) + "\n")
		}
		return b.String()
	}
	writeFile(t, filepath.Join(runDir, "prompt.txt"), lines("prompt"))
	writeFile(t, filepath.Join(runDir, "report.md"), lines("report"))
	m := newModel(dir, filterAll)
	m.width = 120
	m.height = 20
	m.follow = false
	m.resizeViewport()
	m.tab = tabPrompt
	m.refreshContent()
	m.vp.SetYOffset(7)
	m.recordScroll()
	if got := m.yoffsets[yoffsetKey(runDirName(runDir), tabPrompt)]; got == 0 {
		t.Fatalf("offset not recorded")
	}
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'3'}})
	m = derefModel(next)
	if m.tab != tabReport {
		t.Fatalf("tab=%d want report", m.tab)
	}
	if m.vp.YOffset != 0 {
		t.Errorf("report offset=%d want 0", m.vp.YOffset)
	}
	next, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'2'}})
	m = derefModel(next)
	if m.vp.YOffset != 7 {
		t.Errorf("prompt offset=%d want 7", m.vp.YOffset)
	}
}

func runDirName(path string) string {
	return filepath.Base(path)
}
