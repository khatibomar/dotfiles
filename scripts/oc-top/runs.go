package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Run is one oc executor run found under the runs directory.
type Run struct {
	Dir     string // absolute run directory
	DirName string // base name of the run directory
	Name    string
	Started time.Time

	Parent string // parent run's state dir name; empty for top-level
	Depth  int    // nesting depth from meta.json, 0 for top-level

	PID           int
	Running       bool
	State         string // running, done, failed, blocked, hung, timeout, usage-limit
	RevisionLabel string // "base label ↻N" for -s revision runs
	Model         string
	Session       string
	Cwd           string

	IdleLimit int
	HardLimit int

	Seconds int // final elapsed seconds, 0 while unknown
	Cost    float64

	Offset    int64
	Timeline  []Entry
	ToolHist  map[string]int
	ToolCount int
	LastTool  string
	Version   int // bumped when the timeline grows

	// StateKnown is false when State only comes from the event stream.
	StateKnown  bool
	EventStatus string

	// tab file caches, keyed by mtime so rereads stay cheap
	promptMod  time.Time
	promptText string
	reportMod  time.Time
	reportText string
	stderrMod  time.Time
	stderrText string
}

// idle returns seconds since the last events.jsonl write.
func (r *Run) idle(now time.Time) int {
	st, err := os.Stat(filepath.Join(r.Dir, "events.jsonl"))
	if err != nil {
		if r.Started.IsZero() {
			return 0
		}
		if d := int(now.Sub(r.Started).Seconds()); d > 0 {
			return d
		}
		return 0
	}
	if d := int(now.Sub(st.ModTime()).Seconds()); d > 0 {
		return d
	}
	return 0
}

// elapsed returns the display seconds for this run.
func (r *Run) elapsed(now time.Time) int {
	if r.Running {
		if r.Started.IsZero() {
			return 0
		}
		if d := int(now.Sub(r.Started).Seconds()); d > 0 {
			return d
		}
		return 0
	}
	if r.Seconds > 0 {
		return r.Seconds
	}
	// a run without result or report: estimate from the event stream.
	if !r.Started.IsZero() {
		if st, err := os.Stat(filepath.Join(r.Dir, "events.jsonl")); err == nil {
			if d := int(st.ModTime().Sub(r.Started).Seconds()); d > 0 {
				return d
			}
		}
	}
	return 0
}

var dirNameRe = regexp.MustCompile(`^(.*)-(\d{8})-(\d{6})-(\d+)$`)

// parseDirName splits "<name>-YYYYMMDD-HHMMSS-<pid>".
// ok is false when the name does not match.
func parseDirName(dirName string) (name string, started time.Time, pid int, ok bool) {
	m := dirNameRe.FindStringSubmatch(dirName)
	if m == nil {
		return "", time.Time{}, 0, false
	}
	t, err := time.ParseInLocation("20060102-150405", m[2]+"-"+m[3], time.Local)
	if err != nil {
		return "", time.Time{}, 0, false
	}
	p, err := strconv.Atoi(m[4])
	if err != nil {
		return "", time.Time{}, 0, false
	}
	return m[1], t, p, true
}

// parseTimeValue accepts epoch seconds, epoch milliseconds or RFC3339.
func parseTimeValue(v any) time.Time {
	switch t := v.(type) {
	case float64:
		if t > 1e12 {
			return time.UnixMilli(int64(t))
		}
		return time.Unix(int64(t), 0)
	case string:
		s := strings.TrimSpace(t)
		if s == "" {
			return time.Time{}
		}
		if n, err := strconv.ParseInt(s, 10, 64); err == nil {
			return parseTimeValue(float64(n))
		}
		if tm, err := time.Parse(time.RFC3339, s); err == nil {
			return tm
		}
	}
	return time.Time{}
}

// pidAlive reports whether a pid still refers to a live process.
func pidAlive(pid int) bool {
	if pid <= 0 {
		return false
	}
	err := syscall.Kill(pid, 0)
	return err == nil || err == syscall.EPERM
}

type metaJSON struct {
	Run       string `json:"run"`
	Name      string `json:"name"`
	Parent    string `json:"parent"`
	Depth     int    `json:"depth"`
	Cwd       string `json:"cwd"`
	Model     string `json:"model"`
	Readonly  bool   `json:"readonly"`
	Worktree  string `json:"worktree"`
	Session   string `json:"session"`
	IdleLimit int    `json:"idle_limit"`
	HardLimit int    `json:"hard_limit"`
	Started   any    `json:"started"`
}

type resultJSON struct {
	State   string `json:"state"`
	Model   string `json:"model"`
	Session string `json:"session"`
	Ended   any    `json:"ended"`
	Seconds int    `json:"seconds"`
	Exit    int    `json:"exit"`
}

func loadMeta(dir string) *metaJSON {
	b, err := os.ReadFile(filepath.Join(dir, "meta.json"))
	if err != nil {
		return nil
	}
	var m metaJSON
	if err := json.Unmarshal(b, &m); err != nil {
		return nil
	}
	return &m
}

func loadResult(dir string) *resultJSON {
	b, err := os.ReadFile(filepath.Join(dir, "result.json"))
	if err != nil {
		return nil
	}
	var m resultJSON
	if err := json.Unmarshal(b, &m); err != nil {
		return nil
	}
	return &m
}

// parseReportLine reads report.md line 2.
// Returns ("", 0, false) when the line or the file is missing.
func parseReportLine(path string) (state, model, session string, seconds int, ok bool) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", "", "", 0, false
	}
	lines := strings.Split(string(b), "\n")
	if len(lines) < 2 {
		return "", "", "", 0, false
	}
	line := strings.TrimSpace(lines[1])
	if !strings.HasPrefix(line, "state=") {
		return "", "", "", 0, false
	}
	fields := map[string]string{}
	for _, f := range strings.Fields(line) {
		if k, v, found := strings.Cut(f, "="); found {
			fields[k] = v
		}
	}
	state = fields["state"]
	model = fields["model"]
	session = fields["session"]
	if v, found := fields["time"]; found {
		v = strings.TrimSuffix(v, "s")
		if n, err := strconv.Atoi(v); err == nil {
			seconds = n
		}
	}
	if state == "" {
		return "", "", "", 0, false
	}
	return state, model, session, seconds, true
}

// displayName returns the sidebar label for this run.
// A generic "task" label becomes the first useful line of prompt.txt, and
// a session-linked revision uses the original label with a revision suffix.
func (r *Run) displayName() string {
	if r.RevisionLabel != "" {
		return r.RevisionLabel
	}
	return r.baseDisplayName()
}

// baseDisplayName is the label that does not depend on sibling runs.
func (r *Run) baseDisplayName() string {
	if r.Name != "task" {
		return r.Name
	}
	p := filepath.Join(r.Dir, "prompt.txt")
	st, err := os.Stat(p)
	if err != nil || (r.promptMod.Equal(st.ModTime()) && r.promptText != "") {
		if r.promptText != "" {
			return r.promptText
		}
		if err != nil {
			return r.Name
		}
	}
	b, err := os.ReadFile(p)
	if err != nil {
		return r.Name
	}
	label := parsePromptTaskLabel(string(b))
	if label == "" {
		return r.Name
	}
	r.promptMod = st.ModTime()
	r.promptText = label
	return label
}

// parsePromptTaskLabel extracts the first useful line after TASK: or REVIEW FEEDBACK.
func parsePromptTaskLabel(s string) string {
	inTask := false
	for _, line := range strings.Split(s, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "TASK:") {
			inTask = true
			rest := strings.TrimSpace(strings.TrimPrefix(trimmed, "TASK:"))
			if rest != "" && !strings.HasPrefix(rest, "You are") {
				return shortOneLine(rest)
			}
			continue
		}
		if strings.HasPrefix(trimmed, "REVIEW FEEDBACK") {
			inTask = true
			continue
		}
		if inTask && trimmed != "" && !strings.HasPrefix(trimmed, "You are") {
			return shortOneLine(trimmed)
		}
	}
	return ""
}

// Scanner tracks runs across rescans and keeps tail state for each run.
type Scanner struct {
	Dir  string
	runs map[string]*Run
}

// NewScanner creates a scanner for one runs directory.
func NewScanner(dir string) *Scanner {
	return &Scanner{Dir: dir, runs: map[string]*Run{}}
}

// load reads metadata for one run directory.
// prev, when non-nil, supplies the previously tailed state.
func (s *Scanner) load(dir string, prev *Run) *Run {
	dirName := filepath.Base(dir)
	r := prev
	if r == nil {
		r = &Run{Dir: dir, DirName: dirName, ToolHist: map[string]int{}}
	}
	meta := loadMeta(dir)
	res := loadResult(dir)
	repState, repModel, repSession, repSeconds, repOK := parseReportLine(filepath.Join(dir, "report.md"))

	if n, t, p, ok := parseDirName(dirName); ok {
		r.Name = n
		r.Started = t
		if r.PID == 0 {
			r.PID = p
		}
	}

	// pid file is authoritative while the child is still alive.
	r.Running = false
	if b, err := os.ReadFile(filepath.Join(dir, "pid")); err == nil {
		if n, err := strconv.Atoi(strings.TrimSpace(string(b))); err == nil && n > 0 {
			r.PID = n
			r.Running = pidAlive(n)
		}
	}

	// meta.json takes precedence over directory fallbacks.
	if meta != nil {
		if meta.Name != "" {
			r.Name = meta.Name
		}
		if t := parseTimeValue(meta.Started); !t.IsZero() {
			r.Started = t
		}
		r.Cwd = meta.Cwd
		if meta.IdleLimit > 0 {
			r.IdleLimit = meta.IdleLimit
		}
		if meta.HardLimit > 0 {
			r.HardLimit = meta.HardLimit
		}
		r.Model = meta.Model
		r.Session = meta.Session
		r.Parent = meta.Parent
		r.Depth = meta.Depth
	}
	if r.IdleLimit == 0 {
		r.IdleLimit = 300
	}
	if r.HardLimit == 0 {
		r.HardLimit = 2400
	}

	// result.json takes precedence over report.md.
	if res != nil {
		if res.Model != "" {
			r.Model = res.Model
		}
		if res.Session != "" {
			r.Session = res.Session
		}
		if res.Seconds > 0 {
			r.Seconds = res.Seconds
		}
	}
	if repOK {
		if r.Model == "" {
			r.Model = repModel
		}
		if r.Session == "" || r.Session == "none" {
			r.Session = repSession
		}
		if r.Seconds == 0 {
			r.Seconds = repSeconds
		}
	}

	if r.Started.IsZero() {
		if st, err := os.Stat(dir); err == nil {
			r.Started = st.ModTime()
		}
	}
	// prefer result.json, then report.md, then STATUS: in the events.
	// A run with none of those ended without a wrapper report.
	switch {
	case r.Running:
		r.State = "running"
		r.StateKnown = false
	case res != nil && res.State != "":
		r.State = strings.ToLower(res.State)
		r.StateKnown = true
	case repOK:
		r.State = strings.ToLower(repState)
		r.StateKnown = true
	case r.EventStatus != "":
		r.State = r.EventStatus
		r.StateKnown = false
	case fileExists(filepath.Join(dir, "final.txt")):
		r.State = "done"
		r.StateKnown = true
	default:
		r.State = "ended"
		r.StateKnown = false
	}
	return r
}

// fileExists reports whether a file path exists.
func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// Scan refreshes the run list, preserving per-run tail state.
func (s *Scanner) Scan() []*Run {
	entries, err := os.ReadDir(s.Dir)
	if err != nil {
		return nil
	}
	seen := map[string]bool{}
	var out []*Run
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		dir := filepath.Join(s.Dir, e.Name())
		r := s.load(dir, s.runs[e.Name()])
		s.runs[e.Name()] = r
		seen[e.Name()] = true
		out = append(out, r)
	}
	for k := range s.runs {
		if !seen[k] {
			delete(s.runs, k)
		}
	}
	revisionLabels(out)
	return out
}

// revisionLabels suffixes later runs sharing one session with a base label.
func revisionLabels(runs []*Run) {
	groups := map[string][]*Run{}
	for _, r := range runs {
		r.RevisionLabel = ""
		if r.Session == "" || r.Session == "none" {
			continue
		}
		groups[r.Session] = append(groups[r.Session], r)
	}
	for _, group := range groups {
		if len(group) < 2 {
			continue
		}
		sorted := append([]*Run(nil), group...)
		sort.Slice(sorted, func(i, j int) bool {
			if !sorted[i].Started.Equal(sorted[j].Started) {
				return sorted[i].Started.Before(sorted[j].Started)
			}
			return sorted[i].DirName < sorted[j].DirName
		})
		base := sorted[0].baseDisplayName()
		for i, r := range sorted[1:] {
			if r.Name == "task" {
				r.RevisionLabel = base + " ↻" + strconv.Itoa(i+2)
			}
		}
	}
}

// Runs returns every tracked run.
func (s *Scanner) Runs() []*Run {
	out := make([]*Run, 0, len(s.runs))
	for _, r := range s.runs {
		out = append(out, r)
	}
	return out
}
