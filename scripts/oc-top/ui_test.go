package main

import (
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
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

	// Nested rows keep their guides and summary inside the sidebar width.
	root := &Run{DirName: "root", Name: "root", State: "running", Running: true, Started: now.Add(-time.Hour), IdleLimit: 300}
	child := &Run{DirName: "child", Parent: "root", Name: "child-with-a-long-name", State: "done", Started: now.Add(-50 * time.Minute)}
	grand := &Run{DirName: "grand", Parent: "child", Name: "grandchild-with-a-long-name-that-will-truncate", State: "done", Started: now.Add(-40 * time.Minute)}
	sibling := &Run{DirName: "sibling", Parent: "root", Name: "sibling", State: "running", Running: true, Started: now.Add(-30 * time.Minute), IdleLimit: 300}
	runs := []*Run{root, child, grand, sibling}
	for _, sideW := range []int{32, 24} {
		m := model{runs: runs, now: now}
		side := m.sidebar(sideW)
		lines := strings.Split(side, "\n")
		if len(lines) != len(runs)*2 {
			t.Errorf("sideW=%d: got %d lines want %d", sideW, len(lines), len(runs)*2)
		}
		for _, line := range lines {
			if w := lipgloss.Width(line); w > sideW {
				t.Errorf("sideW=%d: line width=%d want <=%d line=%q", sideW, w, sideW, line)
			}
		}
		if !strings.Contains(side, "├ ") || !strings.Contains(side, "└ ") {
			t.Errorf("sideW=%d: child rows miss guide glyphs: %q", sideW, side)
		}
		if strings.Contains(side, "0 run") {
			t.Errorf("sideW=%d: zero running count should be hidden: %q", sideW, side)
		}
		if !strings.Contains(side, "1 sub ·") {
			t.Errorf("sideW=%d: quiet child summary missing: %q", sideW, side)
		}
	}
	summaryModel := model{runs: runs, now: now}
	if side := summaryModel.sidebar(32); !strings.Contains(side, "3 sub · 1 run") {
		t.Errorf("parent row misses child summary: %q", side)
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

func TestTabAtColumns(t *testing.T) {
	t.Parallel()
	for _, active := range []struct {
		name string
		tab  int
	}{
		{"activity active", tabActivity},
		{"prompt active", tabPrompt},
		{"report active", tabReport},
		{"stderr active", tabStderr},
	} {
		m := model{tab: active.tab}
		labels := m.tabLabels()
		col := 0
		for i, label := range labels {
			w := lipgloss.Width(label)
			cases := []struct {
				name string
				x    int
			}{
				{"first", col},
				{"middle", col + w/2},
				{"last", col + w - 1},
			}
			for _, tc := range cases {
				if got := m.tabAt(tc.x); got != i {
					t.Errorf("%s: tab %d %s column %d: tabAt=%d want %d", active.name, i, tc.name, tc.x, got, i)
				}
			}
			if i < len(labels)-1 {
				if got := m.tabAt(col + w); got != -1 {
					t.Errorf("%s: separator after tab %d column %d: tabAt=%d want -1", active.name, i, col+w, got)
				}
			}
			col += w + 1
		}
		if got := m.tabAt(col); got != -1 {
			t.Errorf("%s: past end column %d: tabAt=%d want -1", active.name, col, got)
		}
	}
	empty := model{}
	if got := empty.tabAt(-1); got != -1 {
		t.Errorf("negative column: tabAt=%d want -1", got)
	}
}

func TestMouseTabClick(t *testing.T) {
	t.Parallel()
	newM := func() model {
		m := model{width: 100, height: 20, now: time.Now(), yoffsets: map[string]int{}}
		m.resizeViewport()
		return m
	}
	// column of the first cell of the Report tab.
	probe := newM()
	x := 0
	for i, label := range probe.tabLabels() {
		if i == tabReport {
			break
		}
		x += lipgloss.Width(label) + 1
	}
	x++ // past the left padding cell

	m := newM()
	next, _ := m.Update(tea.MouseMsg{Button: tea.MouseButtonLeft, Action: tea.MouseActionPress, X: x, Y: 1})
	m = derefModel(next)
	if m.tab != tabReport {
		t.Errorf("left press on tab bar: tab=%d want %d", m.tab, tabReport)
	}

	m = newM()
	next, _ = m.Update(tea.MouseMsg{Button: tea.MouseButtonLeft, Action: tea.MouseActionPress, X: x, Y: 5})
	m = derefModel(next)
	if m.tab != tabActivity {
		t.Errorf("left press below tab bar: tab=%d want %d", m.tab, tabActivity)
	}
}

func TestArrowTabKeysWrap(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name string
		msg  tea.KeyMsg
		from int
		want int
	}{
		{"right wraps", tea.KeyMsg{Type: tea.KeyRight}, tabStderr, tabActivity},
		{"l wraps", tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'l'}}, tabStderr, tabActivity},
		{"left wraps", tea.KeyMsg{Type: tea.KeyLeft}, tabActivity, tabStderr},
		{"h wraps", tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'h'}}, tabActivity, tabStderr},
	}
	for _, tc := range cases {
		m := model{width: 100, height: 20, tab: tc.from, now: time.Now(), yoffsets: map[string]int{}}
		m.resizeViewport()
		next, _ := m.updateKeys(tc.msg)
		got := derefModel(next)
		if got.tab != tc.want {
			t.Errorf("%s: tab=%d want %d", tc.name, got.tab, tc.want)
		}
	}
}

func treeStamp(min int) time.Time {
	return time.Date(2026, 11, 8, 12, min, 0, 0, time.Local)
}

func runNames(runs []*Run) []string {
	out := make([]string, 0, len(runs))
	for _, r := range runs {
		out = append(out, r.DirName)
	}
	return out
}

func TestArrangeRunsTree(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name string
		runs []*Run
		want []string
	}{
		{
			name: "children follow parent oldest first",
			runs: []*Run{
				{DirName: "parent", Started: treeStamp(10)},
				{DirName: "later", Parent: "parent", Started: treeStamp(30)},
				{DirName: "earlier", Parent: "parent", Started: treeStamp(20)},
				{DirName: "other", Started: treeStamp(5)},
			},
			want: []string{"parent", "earlier", "later", "other"},
		},
		{
			name: "nested children stay under their parent",
			runs: []*Run{
				{DirName: "root", Started: treeStamp(10)},
				{DirName: "child-a", Parent: "root", Started: treeStamp(20)},
				{DirName: "grand", Parent: "child-a", Started: treeStamp(25)},
				{DirName: "child-b", Parent: "root", Started: treeStamp(30)},
			},
			want: []string{"root", "child-a", "grand", "child-b"},
		},
		{
			name: "top level keeps running first",
			runs: []*Run{
				{DirName: "old-running", Started: treeStamp(1), Running: true},
				{DirName: "new-done", Started: treeStamp(40)},
				{DirName: "mid-done", Started: treeStamp(20)},
			},
			want: []string{"old-running", "new-done", "mid-done"},
		},
		{
			name: "missing parent shows top level",
			runs: []*Run{
				{DirName: "root", Started: treeStamp(10)},
				{DirName: "orphan", Parent: "gone", Started: treeStamp(30)},
			},
			want: []string{"orphan", "root"},
		},
	}
	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			got := runNames(arrangeRuns(tc.runs))
			if strings.Join(got, ",") != strings.Join(tc.want, ",") {
				t.Errorf("order=%v want %v", got, tc.want)
			}
		})
	}
}

func TestFilterRunningKeepsAncestors(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 11, 8, 19, 30, 0, 0, time.Local)
	runs := []*Run{
		{DirName: "parent", Started: now.Add(-48 * time.Hour), State: "done"},
		{DirName: "child", Parent: "parent", Started: now.Add(-47 * time.Hour), Running: true, State: "running"},
		{DirName: "grandchild", Parent: "child", Started: now.Add(-46 * time.Hour), Running: true, State: "running"},
		{DirName: "unrelated", Started: now.Add(-2 * time.Hour), State: "done"},
	}
	m := model{now: now, filter: filterRunning}
	got := runNames(m.visibleRuns(runs))
	want := []string{"parent", "child", "grandchild"}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Errorf("visible=%v want %v", got, want)
	}
}

func TestTreeGuides(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name string
		runs []*Run
		want map[string]string
	}{
		{
			name: "first middle last child",
			runs: []*Run{
				{DirName: "root", Started: treeStamp(0)},
				{DirName: "first", Parent: "root", Started: treeStamp(1)},
				{DirName: "middle", Parent: "root", Started: treeStamp(2)},
				{DirName: "last", Parent: "root", Started: treeStamp(3)},
			},
			want: map[string]string{"root": "", "first": "├ ", "middle": "├ ", "last": "└ "},
		},
		{
			name: "depth two keeps the ancestor bar",
			runs: []*Run{
				{DirName: "root", Started: treeStamp(0)},
				{DirName: "child-a", Parent: "root", Started: treeStamp(1)},
				{DirName: "grand-a", Parent: "child-a", Started: treeStamp(2)},
				{DirName: "child-b", Parent: "root", Started: treeStamp(3)},
				{DirName: "grand-b", Parent: "child-b", Started: treeStamp(4)},
			},
			want: map[string]string{
				"root":    "",
				"child-a": "├ ",
				"grand-a": "│ └ ",
				"child-b": "└ ",
				"grand-b": "  └ ",
			},
		},
		{
			name: "single child uses the corner",
			runs: []*Run{
				{DirName: "root", Started: treeStamp(0)},
				{DirName: "only", Parent: "root", Started: treeStamp(1)},
				{DirName: "grand", Parent: "only", Started: treeStamp(2)},
			},
			want: map[string]string{"root": "", "only": "└ ", "grand": "  └ "},
		},
	}
	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			rows := treeRows(arrangeRuns(tc.runs))
			for i, row := range rows {
				want, ok := tc.want[row.run.DirName]
				if !ok {
					t.Fatalf("unexpected row %q", row.run.DirName)
				}
				if got := treeGuides(rows, i); got != want {
					t.Errorf("%s: guides=%q want %q", row.run.DirName, got, want)
				}
			}
		})
	}
}

func TestTreeGuidesSub(t *testing.T) {
	t.Parallel()
	cases := []struct {
		name string
		runs []*Run
		want map[string]string
	}{
		{
			name: "connector becomes a continuation bar",
			runs: []*Run{
				{DirName: "root", Started: treeStamp(0)},
				{DirName: "first", Parent: "root", Started: treeStamp(1)},
				{DirName: "last", Parent: "root", Started: treeStamp(2)},
			},
			want: map[string]string{"root": "", "first": "│ ", "last": "  "},
		},
		{
			name: "depth two keeps ancestors and drops the corner",
			runs: []*Run{
				{DirName: "root", Started: treeStamp(0)},
				{DirName: "child-a", Parent: "root", Started: treeStamp(1)},
				{DirName: "grand-a", Parent: "child-a", Started: treeStamp(2)},
				{DirName: "child-b", Parent: "root", Started: treeStamp(3)},
				{DirName: "grand-b", Parent: "child-b", Started: treeStamp(4)},
			},
			want: map[string]string{
				"root":    "",
				"child-a": "│ ",
				"grand-a": "│   ",
				"child-b": "  ",
				"grand-b": "    ",
			},
		},
	}
	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			rows := treeRows(arrangeRuns(tc.runs))
			for i, row := range rows {
				want, ok := tc.want[row.run.DirName]
				if !ok {
					t.Fatalf("unexpected row %q", row.run.DirName)
				}
				if got := treeGuidesSub(rows, i); got != want {
					t.Errorf("%s: sub guides=%q want %q", row.run.DirName, got, want)
				}
			}
		})
	}
}

func TestSidebarTreeLayout(t *testing.T) {
	t.Parallel()
	now := time.Now()
	build := &Run{DirName: "build", Name: "build", State: "done", Started: now.Add(-time.Hour)}
	api := &Run{DirName: "api", Parent: "build", Name: "api", State: "done", Started: now.Add(-50 * time.Minute)}
	apiTests := &Run{DirName: "api-tests", Parent: "api", Name: "api-tests", State: "done", Started: now.Add(-40 * time.Minute)}
	docs := &Run{DirName: "docs", Parent: "build", Name: "docs", State: "done", Started: now.Add(-30 * time.Minute)}
	m := model{runs: []*Run{build, api, apiTests, docs}, now: now, sel: -1}
	lines := strings.Split(ansi.Strip(m.sidebar(32)), "\n")
	if len(lines) != 8 {
		t.Fatalf("got %d lines want 8: %q", len(lines), lines)
	}
	headWants := map[int]string{
		0: "  ✓  build",
		2: "  ├ ✓  api",
		4: "  │ └ ✓  api-tests",
		6: "  └ ✓  docs",
	}
	for idx, want := range headWants {
		if !strings.HasPrefix(lines[idx], want) {
			t.Errorf("head line %d=%q want prefix %q", idx, lines[idx], want)
		}
	}
	subWants := map[int]string{
		1: "  3 sub · (no tools yet)",
		3: "  │ 1 sub · (no tools yet)",
		5: "  │   (no tools yet)",
		7: "    (no tools yet)",
	}
	for idx, want := range subWants {
		if !strings.HasPrefix(lines[idx], want) {
			t.Errorf("sub line %d=%q want prefix %q", idx, lines[idx], want)
		}
	}

	m.sel = 2
	lines = strings.Split(ansi.Strip(m.sidebar(32)), "\n")
	if !strings.HasPrefix(lines[4], "▌ │ └ ✓  api-tests") {
		t.Errorf("selected depth-two row=%q want marker in column 0 and full name", lines[4])
	}
}

func TestRunAt(t *testing.T) {
	t.Parallel()
	runsOf := func(n int) []*Run {
		runs := make([]*Run, n)
		for i := range runs {
			runs[i] = &Run{DirName: "run" + strconv.Itoa(i)}
		}
		return runs
	}
	cases := []struct {
		name   string
		rows   int
		sel    int
		height int
		y      int
		want   int
	}{
		{"first line of first row", 12, 0, 11, 2, 0},
		{"second line of first row", 12, 0, 11, 3, 0},
		{"first line of second row", 12, 0, 11, 4, 1},
		{"scrolled first line", 12, 6, 11, 2, 3},
		{"scrolled second line", 12, 6, 11, 3, 3},
		{"scrolled next row", 12, 6, 11, 4, 4},
		{"above the list", 12, 0, 11, 1, -1},
		{"below the list", 12, 0, 11, 10, -1},
		{"past the last run", 2, 0, 11, 6, -1},
		{"empty list", 0, 0, 11, 2, -1},
		{"unknown height", 12, 0, 0, 2, -1},
	}
	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			m := model{height: tc.height, sel: tc.sel, runs: runsOf(tc.rows)}
			if got := m.runAt(tc.y); got != tc.want {
				t.Errorf("runAt(%d)=%d want %d", tc.y, got, tc.want)
			}
		})
	}
}

func TestMouseSidebarClickSelectsRun(t *testing.T) {
	t.Parallel()
	now := time.Now()
	newM := func() model {
		m := model{
			width:  100,
			height: 20,
			now:    now,
			runs: []*Run{
				{Dir: t.TempDir(), DirName: "a", Name: "a", Started: now, State: "done"},
				{Dir: t.TempDir(), DirName: "b", Name: "b", Started: now.Add(-time.Minute), State: "done"},
			},
			yoffsets: map[string]int{},
		}
		m.resizeViewport()
		m.refreshContent()
		return m
	}

	m := newM()
	next, _ := m.Update(tea.MouseMsg{Button: tea.MouseButtonLeft, Action: tea.MouseActionPress, X: 3, Y: 4})
	m = derefModel(next)
	if m.selName != "b" {
		t.Errorf("sidebar click selected %q want b", m.selName)
	}
	if m.builtRun != "b" {
		t.Errorf("right pane built for %q want b", m.builtRun)
	}

	next, _ = m.Update(tea.MouseMsg{Button: tea.MouseButtonLeft, Action: tea.MouseActionPress, X: 3, Y: 2})
	m = derefModel(next)
	if m.selName != "a" {
		t.Errorf("sidebar click selected %q want a", m.selName)
	}

	// A press outside the sidebar keeps the current selection.
	m = newM()
	next, _ = m.Update(tea.MouseMsg{Button: tea.MouseButtonLeft, Action: tea.MouseActionPress, X: 60, Y: 4})
	m = derefModel(next)
	if m.selName != "a" {
		t.Errorf("click outside sidebar selected %q want a", m.selName)
	}
}

func TestActivityTextWrapsLongRows(t *testing.T) {
	t.Parallel()
	longSummary := "summary " + strings.Repeat("alpha ", 30)
	longError := "boom " + strings.Repeat("beta ", 30)
	r := &Run{
		Name:     "run",
		Model:    "model",
		Cwd:      "/tmp/x",
		Session:  "ses",
		ToolHist: map[string]int{"bash": 2},
		Timeline: []Entry{
			{Kind: "tool", Tool: "bash", Title: "bash", Status: "completed", Summary: longSummary},
			{Kind: "finish", TokensIn: 1, TokensOut: 2, Cost: 0.5},
			{Kind: "error", Message: longError},
		},
	}
	for _, width := range []int{20, 34, 60} {
		t.Run(strconv.Itoa(width), func(t *testing.T) {
			t.Parallel()
			out := activityText(r, width)
			lines := strings.Split(out, "\n")
			flat := ""
			for i, line := range lines {
				if w := ansi.StringWidth(line); w > width {
					t.Errorf("line %d width=%d want <=%d: %q", i, w, width, line)
				}
				flat += ansi.Strip(line) + " "
			}
			compact := strings.ReplaceAll(flat, " ", "")
			for _, word := range []string{"alpha", "beta"} {
				if !strings.Contains(compact, word) {
					t.Errorf("%q lost from wrapped output", word)
				}
			}
			// Tool continuation lines hang under the summary after the padded title.
			hang := strings.Repeat(" ", 19)
			found := false
			for _, line := range lines {
				if strings.HasPrefix(ansi.Strip(line), hang) {
					found = true
					break
				}
			}
			if !found {
				t.Errorf("tool summary has no hanging indent")
			}
		})
	}
}

func TestWrapTabContentFitsWidth(t *testing.T) {
	t.Parallel()
	para := strings.Repeat("word ", 30)
	longWord := strings.Repeat("z", 95)
	input := "first line\n\n    ab cd\n" + para + "\n" + longWord
	for _, width := range []int{10, 24, 47} {
		t.Run(strconv.Itoa(width), func(t *testing.T) {
			t.Parallel()
			out := wrapTabContent(input, width)
			for i, line := range strings.Split(out, "\n") {
				if w := ansi.StringWidth(line); w > width {
					t.Errorf("line %d width=%d want <=%d: %q", i, w, width, line)
				}
			}
			if !strings.Contains(out, "first line\n\n") {
				t.Errorf("blank line not preserved: %q", out)
			}
			if !strings.Contains(out, "\n    ab") {
				t.Errorf("indentation not preserved: %q", out)
			}
			flat := strings.Join(strings.Fields(out), " ")
			if !strings.Contains(flat, strings.Join(strings.Fields(para), " ")) {
				t.Errorf("paragraph text lost: %q", out)
			}
			if got := strings.Count(strings.ReplaceAll(out, "\n", ""), "z"); got != len(longWord) {
				t.Errorf("long word z count=%d want %d", got, len(longWord))
			}
		})
	}
}
