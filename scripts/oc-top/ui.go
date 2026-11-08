package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
	"github.com/mattn/go-runewidth"
)

const (
	tabActivity = iota
	tabPrompt
	tabReport
	tabStderr
	tabCount
)

// filterMode selects which runs appear in the sidebar.
type filterMode string

const (
	filterRunning filterMode = "running"
	filter24h     filterMode = "24h"
	filterAll     filterMode = "all"
)

type tickMsg time.Time
type rescanMsg time.Time

type model struct {
	scanner *Scanner
	runs    []*Run // filtered and sorted view
	sel     int
	selName string

	tab      int
	follow   bool
	filter   filterMode
	helpFull bool // shows the long footer at narrow widths

	vp       viewport.Model
	yoffsets map[string]int // scroll offset per run and tab
	width    int
	height   int

	now     time.Time
	frame   int
	ticks   int
	confirm bool // waiting for y/n after x

	footerMsg   string
	footerUntil time.Time

	// last content build, avoids a full rebuild on every tick
	builtRun     string
	builtVersion int
	builtTab     int
	builtWidth   int
}

func newModel(dir string, filter filterMode) model {
	sc := NewScanner(dir)
	sc.Scan()
	m := model{
		scanner:  sc,
		follow:   true,
		filter:   filter,
		yoffsets: map[string]int{},
		now:      time.Now(),
	}
	// prime the timelines so the first frame is already useful.
	for _, r := range sc.Runs() {
		tail(r)
	}
	m.rebuildRuns()
	return m
}

func (m model) Init() tea.Cmd {
	return tea.Batch(
		tea.Tick(time.Second, func(t time.Time) tea.Msg { return tickMsg(t) }),
		tea.Tick(2*time.Second, func(t time.Time) tea.Msg { return rescanMsg(t) }),
	)
}

// sorted view: running first, then newest first.
func sortRuns(runs []*Run) {
	sort.Slice(runs, func(i, j int) bool {
		if runs[i].Running != runs[j].Running {
			return runs[i].Running
		}
		if !runs[i].Started.Equal(runs[j].Started) {
			return runs[i].Started.After(runs[j].Started)
		}
		return runs[i].DirName > runs[j].DirName
	})
}

// filtered returns the runs visible under the active filter mode.
func (m *model) filtered(all []*Run) []*Run {
	out := make([]*Run, 0, len(all))
	for _, r := range all {
		if keepRun(r, m.now, m.filter) {
			out = append(out, r)
		}
	}
	return out
}

// keepRun reports whether one run belongs in the selected filter mode.
func keepRun(r *Run, now time.Time, mode filterMode) bool {
	switch mode {
	case filterRunning:
		return r.Running
	case filter24h:
		return r.Running || (!r.Started.IsZero() && now.Sub(r.Started) <= 24*time.Hour)
	case filterAll:
		return true
	default:
		return r.Running
	}
}

// parseFilter accepts the command-line filter names.
func parseFilter(s string) (filterMode, error) {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "running":
		return filterRunning, nil
	case "24h", "24", "last24h", "last-24h":
		return filter24h, nil
	case "all":
		return filterAll, nil
	default:
		return "", fmt.Errorf("invalid --filter %q (want running, 24h, or all)", s)
	}
}

// nextFilter cycles Running -> Last 24h -> All.
func nextFilter(mode filterMode) filterMode {
	switch mode {
	case filterRunning:
		return filter24h
	case filter24h:
		return filterAll
	default:
		return filterRunning
	}
}

func (m *model) rebuildRuns() {
	all := m.scanner.Runs()
	view := m.filtered(all)
	sortRuns(view)
	m.runs = view
	// Keep the selected run by its stable directory id, not by index.
	// The id is not a user-chosen name, so it stays put when rows re-sort.
	idx := -1
	for i, r := range view {
		if r.DirName == m.selName {
			idx = i
			break
		}
	}
	if idx >= 0 {
		m.sel = idx
		return
	}
	if len(view) == 0 {
		m.sel = 0
		m.selName = ""
		return
	}
	if m.sel < 0 {
		m.sel = 0
	}
	if m.sel >= len(view) {
		m.sel = len(view) - 1
	}
	m.selName = view[m.sel].DirName
}

// setSelection clamps and records the selected run id.
func (m *model) setSelection(index int) {
	if len(m.runs) == 0 {
		m.sel = 0
		m.selName = ""
		return
	}
	if index < 0 {
		index = 0
	}
	if index >= len(m.runs) {
		index = len(m.runs) - 1
	}
	m.sel = index
	m.selName = m.runs[index].DirName
}

func (m *model) selected() *Run {
	if m.sel < 0 || m.sel >= len(m.runs) {
		return nil
	}
	r := m.runs[m.sel]
	m.selName = r.DirName
	return r
}

func (m *model) say(msg string) {
	m.footerMsg = msg
	m.footerUntil = m.now.Add(5 * time.Second)
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.resizeViewport()
	case tickMsg:
		m.now = time.Time(msg)
		m.ticks++
		m.frame++
		for _, r := range m.scanner.Runs() {
			tail(r)
		}
		if m.footerMsg != "" && m.now.After(m.footerUntil) {
			m.footerMsg = ""
		}
		m.refreshContent()
		return m, tea.Tick(time.Second, func(t time.Time) tea.Msg { return tickMsg(t) })
	case rescanMsg:
		m.scanner.Scan()
		m.rebuildRuns()
		m.refreshContent()
		return m, tea.Tick(2*time.Second, func(t time.Time) tea.Msg { return rescanMsg(t) })
	case tea.KeyMsg:
		if m.confirm {
			return m.updateConfirm(msg)
		}
		return m.updateKeys(msg)
	case tea.MouseMsg:
		if (msg.Button == tea.MouseButtonWheelUp || msg.Button == tea.MouseButtonWheelDown) && m.mouseInViewport(msg) {
			switch msg.Button {
			case tea.MouseButtonWheelUp:
				m.follow = false
				m.vp.LineUp(3)
				m.recordScroll()
			case tea.MouseButtonWheelDown:
				m.vp.LineDown(3)
				m.recordScroll()
			}
		}
		return m, nil
	}
	m.refreshContent()
	return m, nil
}

func (m *model) updateConfirm(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "y", "Y":
		r := m.selected()
		if r != nil && r.Running && r.PID > 0 {
			// SIGTERM only; oc notices the exit on its own.
			_ = syscall.Kill(r.PID, syscall.SIGTERM)
			m.say(fmt.Sprintf("SIGTERM sent to %s (pid %d)", r.Name, r.PID))
		} else {
			m.say("nothing to kill")
		}
		m.confirm = false
	case "n", "N", "esc":
		m.say("kill cancelled")
		m.confirm = false
	default:
	}
	m.refreshContent()
	return m, nil
}

func (m *model) updateKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	k := msg.String()
	switch k {
	case "q", "ctrl+c":
		return m, tea.Quit
	case "j", "down":
		m.move(1)
	case "k", "up":
		m.move(-1)
	case "J", "shift+down":
		m.scrollDownLine(1)
	case "K", "shift+up":
		m.scrollUpLine(1)
	case "g", "home":
		m.scrollTop()
	case "G", "end":
		m.scrollBottom()
	case "ctrl+u":
		m.follow = false
		m.vp.HalfPageUp()
		m.recordScroll()
	case "ctrl+d":
		m.vp.HalfPageDown()
		m.recordScroll()
	case "pgup":
		m.follow = false
		m.vp.PageUp()
		m.recordScroll()
	case "pgdown":
		m.vp.PageDown()
		m.recordScroll()
	case "?":
		m.helpFull = !m.helpFull
	case "tab":
		m.tab = (m.tab + 1) % tabCount
	case "shift+tab":
		m.tab = (m.tab + tabCount - 1) % tabCount
	case "1", "2", "3", "4":
		m.tab = int(k[0] - '1')
	case "f":
		m.follow = !m.follow
		if m.follow {
			m.vp.GotoBottom()
			m.recordScroll()
		}
		m.say("follow " + onOff(m.follow))
	case "a":
		m.filter = nextFilter(m.filter)
		m.rebuildRuns()
		m.say("filter " + filterLabel(m.filter))
	case "x":
		if r := m.selected(); r != nil && r.Running {
			m.confirm = true
		} else {
			m.say("selected run is not running")
		}
	case "y":
		m.copyRevise()
	}
	m.refreshContent()
	return m, nil
}

func (m *model) move(d int) {
	if len(m.runs) == 0 {
		return
	}
	m.setSelection(m.sel + d)
}

func onOff(on bool) string {
	if on {
		return "on"
	}
	return "off"
}

func filterLabel(mode filterMode) string {
	switch mode {
	case filterRunning:
		return "Running"
	case filter24h:
		return "24h"
	case filterAll:
		return "All"
	default:
		return "Running"
	}
}

// copyRevise copies the revise command for the selected run.
func (m *model) copyRevise() {
	r := m.selected()
	if r == nil || r.Session == "" || r.Session == "none" {
		m.say("no session for this run yet")
		return
	}
	cmd := fmt.Sprintf("oc -s %s \"\"", r.Session)
	if wl, err := exec.LookPath("wl-copy"); err == nil {
		c := exec.Command(wl)
		c.Stdin = strings.NewReader(cmd)
		if err := c.Run(); err == nil {
			m.say("copied: " + cmd)
			return
		}
	}
	m.say(cmd)
}

// layout sizes the sidebar, divider, and right pane.
func (m *model) layout() (sideW, rightW int) {
	sideW = 32
	rightW = m.width - sideW - 1 // one column for the divider
	if m.width < 70 {
		sideW = 24
		rightW = m.width - sideW - 1
	}
	if rightW < 20 {
		rightW = 20
	}
	if sideW < 20 {
		sideW = 20
	}
	return
}

// clampYOffset keeps a line offset inside the visible viewport range.
func clampYOffset(offset, total, height int) int {
	if total <= height || height <= 0 {
		return 0
	}
	maxOffset := total - height
	if offset < 0 {
		return 0
	}
	if offset > maxOffset {
		return maxOffset
	}
	return offset
}

// yoffsetKey is the map key for one run and one tab.
func yoffsetKey(runName string, tab int) string {
	return runName + "\x00" + strconv.Itoa(tab)
}

// setYOffset stores a clamped offset for one run and tab.
func (m *model) setYOffset(runName string, tab, offset int) {
	if runName == "" {
		return
	}
	if m.yoffsets == nil {
		m.yoffsets = map[string]int{}
	}
	m.yoffsets[yoffsetKey(runName, tab)] = clampYOffset(offset, m.vp.TotalLineCount(), m.vp.Height)
}

// recordScroll saves the current viewport offset for the selected run/tab.
func (m *model) recordScroll() {
	if r := m.selected(); r != nil {
		m.setYOffset(r.DirName, m.tab, m.vp.YOffset)
	}
}

// restoreYOffset applies the stored offset for one run/tab.
func (m *model) restoreYOffset(runName string, tab int) {
	if off, ok := m.yoffsets[yoffsetKey(runName, tab)]; ok {
		m.vp.SetYOffset(clampYOffset(off, m.vp.TotalLineCount(), m.vp.Height))
	}
}

// mouseInViewport tells whether a mouse event is over the right pane.
func (m model) mouseInViewport(msg tea.MouseMsg) bool {
	if m.width <= 0 || m.height <= 0 {
		return false
	}
	sideW, _ := m.layout()
	return msg.X >= sideW+1 && msg.Y >= 2 && msg.Y <= m.height-2
}

// scrollUpLine scrolls the right pane up one line and disables follow.
func (m *model) scrollUpLine(n int) {
	m.follow = false
	m.vp.LineUp(n)
	m.recordScroll()
}

// scrollDownLine scrolls the right pane down one line.
func (m *model) scrollDownLine(n int) {
	m.vp.LineDown(n)
	m.recordScroll()
}

// scrollTop moves to the first line and disables follow.
func (m *model) scrollTop() {
	m.follow = false
	m.vp.GotoTop()
	m.recordScroll()
}

// scrollBottom moves to the last line and enables follow.
func (m *model) scrollBottom() {
	m.follow = true
	m.vp.GotoBottom()
	m.recordScroll()
}

// resizeViewport syncs the viewport size with the window.
func (m *model) resizeViewport() {
	if m.vp.TotalLineCount() > 0 || m.vp.YOffset > 0 {
		m.recordScroll()
	}
	_, rightW := m.layout()
	h := m.height - 3 // header, tab bar, footer
	if h < 4 {
		h = 4
	}
	if rightW < 10 {
		rightW = 10
	}
	m.vp = viewport.New(rightW, h)
	m.vp.MouseWheelEnabled = true
	m.vp.MouseWheelDelta = 3
	// keep paging keys away from run selection keys.
	m.vp.KeyMap = viewport.KeyMap{}
}

func (m *model) refreshContent() {
	r := m.selected()
	if r == nil {
		if m.builtRun != "" && m.builtRun != m.selName {
			m.setYOffset(m.builtRun, m.builtTab, m.vp.YOffset)
		}
		m.builtRun = ""
		m.builtTab = m.tab
		return
	}
	if m.builtRun != "" && (r.DirName != m.builtRun || m.tab != m.builtTab) {
		m.setYOffset(m.builtRun, m.builtTab, m.vp.YOffset)
	}
	if r.DirName == m.builtRun && r.Version == m.builtVersion && m.tab == m.builtTab && m.width == m.builtWidth {
		return
	}
	m.builtRun = r.DirName
	m.builtVersion = r.Version
	m.builtTab = m.tab
	m.builtWidth = m.width
	_, rightW := m.layout()
	content := ""
	switch m.tab {
	case tabActivity:
		content = activityText(r, rightW)
	case tabPrompt:
		content = readTabFile(r, "prompt.txt", "(no prompt.txt)")
	case tabReport:
		content = readTabFile(r, "report.md", "(report not ready yet)")
	case tabStderr:
		content = readTabFile(r, "stderr.log", "(no stderr output)")
	}
	m.vp.SetContent(content)
	if m.follow {
		m.vp.GotoBottom()
		m.setYOffset(r.DirName, m.tab, m.vp.YOffset)
	} else if _, ok := m.yoffsets[yoffsetKey(r.DirName, m.tab)]; ok {
		m.restoreYOffset(r.DirName, m.tab)
	} else {
		m.vp.SetYOffset(0)
	}
}

func readTabFile(r *Run, name, missing string) string {
	p := filepath.Join(r.Dir, name)
	st, err := os.Stat(p)
	if err != nil {
		return missing
	}
	b, err := os.ReadFile(p)
	if err != nil {
		return missing
	}
	if len(b) == 0 {
		return missing + " (empty)"
	}
	_ = st
	return strings.TrimRight(string(b), "\n")
}

// summaryLine is the one-line overview above the Activity timeline.
func summaryLine(r *Run) string {
	modelS := r.Model
	if modelS == "" {
		modelS = "unknown model"
	}
	cwd := r.Cwd
	if cwd == "" {
		cwd = "-"
	}
	sess := r.Session
	if sess == "" || sess == "none" {
		sess = "-"
	}
	type kv struct {
		tool  string
		count int
	}
	var hist []kv
	for t, c := range r.ToolHist {
		hist = append(hist, kv{t, c})
	}
	sort.Slice(hist, func(i, j int) bool {
		if hist[i].count != hist[j].count {
			return hist[i].count > hist[j].count
		}
		return hist[i].tool < hist[j].tool
	})
	tools := "-"
	if len(hist) > 0 {
		parts := make([]string, 0, len(hist))
		for _, h := range hist {
			parts = append(parts, fmt.Sprintf("%s×%d", h.tool, h.count))
		}
		tools = strings.Join(parts, " ")
	}
	return fmt.Sprintf("name %s · model %s · cwd %s · session %s · tools %s", r.Name, modelS, cwd, sess, tools)
}

func activityText(r *Run, width int) string {
	if width < 10 {
		width = 10
	}
	var b strings.Builder
	summary := strings.Join(strings.Fields(summaryLine(r)), " ")
	b.WriteString(fitDisplayText(summary, width))
	b.WriteString("\n\n")
	if len(r.Timeline) == 0 {
		b.WriteString("(no activity yet)")
		return b.String()
	}
	for _, e := range r.Timeline {
		ts := styleDim.Render("--:--:--")
		if !e.Time.IsZero() {
			ts = styleDim.Render(e.Time.Format("15:04:05"))
		}
		switch e.Kind {
		case "tool":
			title := fmt.Sprintf("%-8s", shortOneLine(e.Title))
			line := fmt.Sprintf("%s  %s %s", ts, toolStyle(e.Status).Render(title), e.Summary)
			b.WriteString(ansi.Truncate(line, width, "…"))
			b.WriteString("\n")
		case "text":
			b.WriteString("\n")
			for _, w := range wrapText(e.Text, width) {
				b.WriteString(styleDimLit.Render(w))
				b.WriteString("\n")
			}
		case "finish":
			line := fmt.Sprintf("%s  step finish  in %d  out %d  cost $%.4f", ts, e.TokensIn, e.TokensOut, e.Cost)
			b.WriteString(styleDim.Render(fitDisplayText(line, width)))
			b.WriteString("\n")
		case "error":
			line := fmt.Sprintf("%s  ERROR %s", ts, shortOneLine(e.Message))
			b.WriteString(styleRed.Render(fitDisplayText(line, width)))
			b.WriteString("\n")
		}
	}
	return b.String()
}

// wrapText splits plain text into lines of at most width display cells.
func wrapText(s string, width int) []string {
	if width < 1 {
		width = 1
	}
	var out []string
	for _, para := range strings.Split(s, "\n") {
		words := strings.Fields(para)
		if len(words) == 0 {
			out = append(out, "")
			continue
		}
		line := ""
		for _, word := range words {
			for ansi.StringWidth(word) > width {
				if line != "" {
					out = append(out, line)
					line = ""
				}
				chunk := ansi.Truncate(word, width, "")
				out = append(out, chunk)
				word = strings.TrimPrefix(word, chunk)
				if word == chunk {
					break
				}
			}
			if line == "" {
				line = word
			} else if ansi.StringWidth(line)+1+ansi.StringWidth(word) > width {
				out = append(out, line)
				line = word
			} else {
				line += " " + word
			}
		}
		out = append(out, line)
	}
	return out
}

// fmtDur formats seconds as 3m12s.
func fmtDur(sec int) string {
	if sec < 0 {
		sec = 0
	}
	h := sec / 3600
	mi := (sec % 3600) / 60
	s := sec % 60
	if h > 0 {
		return fmt.Sprintf("%dh%dm", h, mi)
	}
	if mi > 0 {
		return fmt.Sprintf("%dm%02ds", mi, s)
	}
	return fmt.Sprintf("%ds", s)
}

// idleText renders the idle seconds for one running run.
func idleText(r *Run, now time.Time) (string, lipgloss.Style) {
	idle := r.idle(now)
	text := fmt.Sprintf("idle %s", fmtDur(idle))
	if r.IdleLimit <= 0 {
		return text, styleDim
	}
	ratio := float64(idle) / float64(r.IdleLimit)
	if ratio >= 0.8 {
		return text, styleRed
	}
	if ratio >= 0.5 {
		return text, styleYellow
	}
	return text, styleDim
}

func (m *model) header() string {
	counts := map[string]int{}
	total := 0.0
	for _, r := range m.runs {
		counts[r.State]++
		total += r.Cost
	}
	bad := counts["failed"] + counts["hung"] + counts["timeout"]
	parts := []string{
		styleTitle.Render("oc-top"),
		styleDim.Render(fmt.Sprintf("  %d running · %d done · %d failed+hung+timeout · %d blocked · $%.4f total",
			counts["running"], counts["done"], bad, counts["blocked"], total)),
		styleDimLit.Render(fmt.Sprintf("  %s · follow %s", m.filterChips(), onOff(m.follow))),
	}
	return strings.Join(parts, "")
}

// filterChips renders the three filter modes with the active one highlighted.
func (m *model) filterChips() string {
	modes := []filterMode{filterRunning, filter24h, filterAll}
	parts := make([]string, 0, len(modes))
	for _, mode := range modes {
		label := filterLabel(mode)
		if mode == m.filter {
			parts = append(parts, styleChipOn.Render("["+label+"]"))
		} else {
			parts = append(parts, styleChipOff.Render(label))
		}
	}
	return strings.Join(parts, " ")
}

func (m *model) tabBar() string {
	var tabs []string
	for i, name := range styleTabName {
		if i == m.tab {
			tabs = append(tabs, styleTabOn.Render(fmt.Sprintf("%d %s", i+1, name)))
		} else {
			tabs = append(tabs, styleTab.Render(fmt.Sprintf("%d %s", i+1, name)))
		}
	}
	bar := strings.Join(tabs, " ")
	pos := styleDim.Render(m.scrollText())
	if m.width <= 0 {
		return bar
	}
	gap := m.width - lipgloss.Width(bar) - lipgloss.Width(pos) - 1
	if gap <= 0 {
		return bar
	}
	return bar + strings.Repeat(" ", gap) + pos
}

// scrollText describes the visible line inside the total line count.
func (m *model) scrollText() string {
	total := m.vp.TotalLineCount()
	offset := m.vp.YOffset
	if total <= 0 {
		return "line 0/0 · 0%"
	}
	percent := int((float64(offset) / float64(total) * 100) + 0.5)
	return fmt.Sprintf("line %d/%d · %d%%", offset, total, percent)
}

func (m *model) sidebar(sideW int) string {
	var b strings.Builder
	if len(m.runs) == 0 {
		if m.filter == filterRunning {
			b.WriteString(styleDim.Render("No runs active"))
			b.WriteString("\n")
			b.WriteString(styleDimLit.Render("press a for recent runs"))
		} else {
			b.WriteString(styleDim.Render("no oc runs yet"))
		}
		return b.String()
	}
	for i, r := range m.runs {
		sel := i == m.sel
		head := rowHead(r, m.now, m.frame, sideW, sel)
		sub := fmt.Sprintf("  %s", subLine(r))
		if sel {
			b.WriteString(styleRowSel.Width(sideW).Render(head))
		} else {
			b.WriteString(styleRow.Width(sideW).Render(head))
		}
		b.WriteString("\n")
		if sel {
			b.WriteString(styleRowSel.Width(sideW).Render(styleDimLit.Render(sub)))
		} else {
			b.WriteString(styleRow.Width(sideW).Render(styleDimLit.Render(sub)))
		}
		if i < len(m.runs)-1 {
			b.WriteString("\n")
		}
	}
	return b.String()
}

// rowHead builds one sidebar head line that always fits sideW columns.
// The glyph, name, and metric blocks all have fixed widths, so columns align.
func rowHead(r *Run, now time.Time, frame, sideW int, selected bool) string {
	glyphText := glyph(r, frame)
	elapsed := fmtDur(r.elapsed(now))
	idlePlain := ""
	idleStyled := ""
	if r.Running {
		text, st := idleText(r, now)
		idlePlain = " " + text
		idleStyled = " " + st.Render(text)
	}
	metrics := elapsed + idlePlain
	prefix := "  "
	if selected {
		prefix = "▌ "
	}

	// prefix + glyph cell + spaces + metrics + name must fit sideW.
	metricsWidth := 15
	fixed := runewidth.StringWidth(prefix) + 2 + 1 + 1 + metricsWidth
	nameWidth := sideW - fixed
	if nameWidth > 18 {
		nameWidth = 18
	}
	if sideW < 32 {
		metricsWidth = sideW - runewidth.StringWidth(prefix) - 2 - 1 - 1 - 4
		if metricsWidth < 8 {
			metricsWidth = 8
		}
		metrics = elapsed + idlePlain
		nameWidth = sideW - (runewidth.StringWidth(prefix) + 2 + 1 + 1 + metricsWidth)
	}
	if nameWidth < 4 {
		nameWidth = 4
	}
	name := fitDisplayText(r.displayName(), nameWidth)
	namePad := strings.Repeat(" ", nameWidth-runewidth.StringWidth(name))
	metricsRendered := elapsed + idleStyled
	if runewidth.StringWidth(metrics) > metricsWidth {
		metrics = fitDisplayText(metrics, metricsWidth)
		metricsRendered = metrics
	}
	metricsPad := ""
	if gap := metricsWidth - runewidth.StringWidth(metrics); gap > 0 {
		metricsPad = strings.Repeat(" ", gap)
	}
	glyphPad := ""
	if gap := 2 - runewidth.StringWidth(glyphText); gap > 0 {
		glyphPad = strings.Repeat(" ", gap)
	}
	return prefix + glyphStyle(r.State).Render(glyphText) + glyphPad + " " + name + namePad + " " + metricsPad + metricsRendered
}

// fitDisplayText truncates plain text to a display width, ending in … when cut.
func fitDisplayText(s string, width int) string {
	if width <= 0 {
		return ""
	}
	if runewidth.StringWidth(s) <= width {
		return s
	}
	if width == 1 {
		return "…"
	}
	out := ""
	for _, r := range s {
		if runewidth.StringWidth(out)+runewidth.RuneWidth(r)+1 > width {
			return out + "…"
		}
		out += string(r)
	}
	return out
}

// subLine is the dim second line of one sidebar row.
func subLine(r *Run) string {
	base := ""
	if r.ToolCount == 0 {
		base = "(no tools yet)"
	} else {
		base = fmt.Sprintf("last %s · %d calls", r.LastTool, r.ToolCount)
	}
	if r.State == "ended" {
		return "ended · " + base
	}
	return base
}

func (m *model) footer() string {
	if m.confirm {
		return styleRed.Render("kill selected run? press y to confirm, n to cancel")
	}
	if m.footerMsg != "" {
		return styleFooter.Render(m.footerMsg)
	}
	help := "j/k runs · J/K & shift+↑↓ scroll · ctrl+u/d half · pgup/pgdn page · g/G/home/end top/bottom · f follow · a filter · x kill · y copy · ? help · q quit"
	if m.width > 0 && m.width < 110 && !m.helpFull {
		help = "j/k runs · J/K scroll · a filter · x kill · ? help · q"
	}
	return styleFooter.Render(fitWords(help, m.width))
}

// fitWords trims a help line at a word boundary so it never wraps mid-word.
func fitWords(s string, width int) string {
	if width <= 0 || lipgloss.Width(s) <= width {
		return s
	}
	words := strings.Fields(s)
	out := ""
	for _, w := range words {
		next := w
		if out != "" {
			next = out + " " + w
		}
		if lipgloss.Width(next) > width {
			break
		}
		out = next
	}
	if out == "" {
		// Even one word is too long; keep it rather than split it.
		return words[0]
	}
	return out
}

// sideWindow returns the first sidebar line to show.
// Each run takes two lines, so the start stays even.
func sideWindow(sel, rows int, height int) (start int) {
	if height <= 0 || rows <= 0 || sel < 0 {
		return 0
	}
	selLine := sel * 2
	if selLine+2 > height {
		start = selLine + 2 - height
		if start < 0 {
			start = 0
		}
		if start%2 == 1 {
			start--
		}
	}
	return
}

// paneSeparator draws the vertical divider between the two panes.
func paneSeparator(height int) string {
	if height <= 0 {
		return ""
	}
	lines := make([]string, height)
	for i := range lines {
		lines[i] = styleDim.Render("│")
	}
	return strings.Join(lines, "\n")
}

func (m model) View() string {
	if m.width == 0 {
		return "oc-top"
	}
	sideW, rightW := m.layout()
	mainH := m.height - 3 // header, tab bar, footer
	if mainH < 2 {
		mainH = 2
	}
	var main string
	if len(m.runs) == 0 {
		if m.filter == filterRunning {
			side := m.sidebar(sideW)
			side = clipLines(side, 0, mainH)
			main = lipgloss.JoinHorizontal(lipgloss.Top, side, paneSeparator(mainH), "")
		} else {
			empty := emptyText(m)
			main = lipgloss.Place(rightW, mainH, lipgloss.Center, lipgloss.Center, empty)
		}
	} else {
		side := m.sidebar(sideW)
		// clip the sidebar to the visible height, keeping the selection in view.
		side = clipLines(side, sideWindow(m.sel, len(m.runs), mainH), mainH)
		main = lipgloss.JoinHorizontal(lipgloss.Top, side, paneSeparator(mainH), m.vp.View())
	}
	head := m.header()
	tabs := m.tabBar()
	foot := m.footer()
	return lipgloss.JoinVertical(lipgloss.Left, head, tabs, main, foot)
}

// emptyText explains an empty run list.
func emptyText(m model) string {
	if len(m.scanner.Runs()) == 0 {
		return "no oc runs yet\nstart one with:  oc \"your task\""
	}
	return "no runs match the current filter\npress a to show all runs"
}

// clipLines keeps at most n lines starting at start.
func clipLines(s string, start, n int) string {
	if n <= 0 {
		return s
	}
	lines := strings.Split(s, "\n")
	if start >= len(lines) {
		return ""
	}
	if start+n >= len(lines) {
		return strings.Join(lines[start:], "\n")
	}
	return strings.Join(lines[start:start+n], "\n")
}
