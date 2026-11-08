package main

import (
	"os"
	"path/filepath"
	"strconv"
	"testing"
)

func TestParseDirName(t *testing.T) {
	t.Parallel()
	cases := []struct {
		in   string
		name string
		pid  int
		ok   bool
		hour int
		min  int
		sec  int
	}{
		{"task-20261108-192100-2037738", "task", 2037738, true, 19, 21, 0},
		{"w1-214-20261108-191329-1935984", "w1-214", 1935984, true, 19, 13, 29},
		{"keb82-linear-20261108-192155-2051311", "keb82-linear", 2051311, true, 19, 21, 55},
		{"a-b-c-d-20200101-000001-1", "a-b-c-d", 1, true, 0, 0, 1},
		{"no-date-here", "", 0, false, 0, 0, 0},
		{"task-20261301-120000-5", "", 0, false, 0, 0, 0},
		{"task-20261108-192100", "", 0, false, 0, 0, 0},
		{"", "", 0, false, 0, 0, 0},
	}
	for _, c := range cases {
		name, started, pid, ok := parseDirName(c.in)
		if ok != c.ok {
			t.Errorf("parseDirName(%q): ok=%v want %v", c.in, ok, c.ok)
			continue
		}
		if !ok {
			continue
		}
		if name != c.name {
			t.Errorf("parseDirName(%q): name=%q want %q", c.in, name, c.name)
		}
		if pid != c.pid {
			t.Errorf("parseDirName(%q): pid=%d want %d", c.in, pid, c.pid)
		}
		if started.Hour() != c.hour || started.Minute() != c.min || started.Second() != c.sec {
			t.Errorf("parseDirName(%q): got %v, want %02d:%02d:%02d", c.in, started, c.hour, c.min, c.sec)
		}
	}
}

func TestParseReportLine(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	write := func(name, body string) string {
		p := filepath.Join(dir, name)
		if err := os.WriteFile(p, []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
		return p
	}
	cases := []struct {
		name    string
		body    string
		state   string
		model   string
		session string
		seconds int
		ok      bool
	}{
		{"done", "OC RUN x\nstate=done model=opencode-go/crouton-alpha-free time=42s session=ses_x\n---\n", "done", "opencode-go/crouton-alpha-free", "ses_x", 42, true},
		{"failed", "OC RUN x\nstate=failed model=m time=781s session=ses_y\n", "failed", "m", "ses_y", 781, true},
		{"hung", "OC RUN x\nstate=hung model=m time=52s session=none\n", "hung", "m", "none", 52, true},
		{"slow", "OC RUN x\nstate=slow model=m time=300s session=ses_s\n", "slow", "m", "ses_s", 300, true},
		{"usage", "OC RUN x\nstate=usage-limit model=m time=0s session=ses_z\n", "usage-limit", "m", "ses_z", 0, true},
		{"missing state", "OC RUN x\nnope model=m time=1s session=s\n", "", "", "", 0, false},
		{"one line", "OC RUN x\n", "", "", "", 0, false},
	}
	for _, c := range cases {
		p := write("report.md", c.body)
		state, model, session, seconds, ok := parseReportLine(p)
		if ok != c.ok {
			t.Errorf("%s: ok=%v want %v", c.name, ok, c.ok)
			continue
		}
		if !ok {
			continue
		}
		if state != c.state || model != c.model || session != c.session || seconds != c.seconds {
			t.Errorf("%s: got %q %q %q %d, want %q %q %q %d",
				c.name, state, model, session, seconds, c.state, c.model, c.session, c.seconds)
		}
	}
	if _, _, _, _, ok := parseReportLine(filepath.Join(dir, "no-such.md")); ok {
		t.Error("missing file: ok=true, want false")
	}
}

func writeFile(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestMetaResultPrecedence(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	runDir := filepath.Join(dir, "task-20261108-120000-42")
	writeFile(t, filepath.Join(runDir, "meta.json"),
		`{"run":"task-20261108-120000-42","name":"meta-name","cwd":"/work","model":"meta-model","session":"ses_meta","idle_limit":99,"hard_limit":1111,"started":1730000000}`)
	writeFile(t, filepath.Join(runDir, "result.json"),
		`{"state":"failed","model":"result-model","session":"ses_result","seconds":77,"exit":1}`)
	writeFile(t, filepath.Join(runDir, "report.md"),
		"OC RUN task-20261108-120000-42\nstate=done model=report-model time=999s session=ses_report\n---\n")

	sc := NewScanner(dir)
	runs := sc.Scan()
	if len(runs) != 1 {
		t.Fatalf("got %d runs, want 1", len(runs))
	}
	r := runs[0]
	if r.Name != "meta-name" {
		t.Errorf("Name=%q want meta-name", r.Name)
	}
	if r.State != "failed" {
		t.Errorf("State=%q want failed (result.json wins over report.md)", r.State)
	}
	if r.Model != "result-model" {
		t.Errorf("Model=%q want result-model", r.Model)
	}
	if r.Session != "ses_result" {
		t.Errorf("Session=%q want ses_result", r.Session)
	}
	if r.Cwd != "/work" {
		t.Errorf("Cwd=%q want /work", r.Cwd)
	}
	if r.IdleLimit != 99 || r.HardLimit != 1111 {
		t.Errorf("limits=%d/%d want 99/1111", r.IdleLimit, r.HardLimit)
	}
	if r.Seconds != 77 {
		t.Errorf("Seconds=%d want 77", r.Seconds)
	}
	if r.Started.Unix() != 1730000000 {
		t.Errorf("Started=%v want epoch 1730000000", r.Started)
	}
}

func TestReportFallback(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "myrun-20261108-120000-42", "report.md"),
		"OC RUN myrun\nstate=blocked model=rep-model time=5s session=ses_r\n---\n")
	sc := NewScanner(dir)
	runs := sc.Scan()
	if len(runs) != 1 {
		t.Fatalf("got %d runs, want 1", len(runs))
	}
	r := runs[0]
	if r.Name != "myrun" {
		t.Errorf("Name=%q want myrun", r.Name)
	}
	if r.State != "blocked" {
		t.Errorf("State=%q want blocked", r.State)
	}
	if r.Model != "rep-model" || r.Session != "ses_r" || r.Seconds != 5 {
		t.Errorf("got model=%q session=%q seconds=%d", r.Model, r.Session, r.Seconds)
	}
	if r.Started.Hour() != 12 {
		t.Errorf("Started=%v want 12:00 from dir name", r.Started)
	}
	if r.IdleLimit != 300 {
		t.Errorf("IdleLimit=%d want default 300", r.IdleLimit)
	}
}

func TestRunningDetection(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	alive := filepath.Join(dir, "live-20261108-120000-1")
	dead := filepath.Join(dir, "gone-20261108-120000-2")
	writeFile(t, filepath.Join(alive, "pid"), strconv.Itoa(os.Getpid())+"\n")
	writeFile(t, filepath.Join(dead, "pid"), "2147483647\n")
	sc := NewScanner(dir)
	for _, r := range sc.Scan() {
		switch r.DirName {
		case "live-20261108-120000-1":
			if !r.Running {
				t.Error("self pid should be running")
			}
			if r.State != "running" {
				t.Errorf("State=%q want running", r.State)
			}
		case "gone-20261108-120000-2":
			if r.Running {
				t.Error("max pid should not be running")
			}
		}
	}
}

func TestElapsed(t *testing.T) {
	t.Parallel()
	cases := []struct {
		sec  int
		want string
	}{
		{0, "0s"}, {45, "45s"}, {60, "1m00s"}, {192, "3m12s"}, {3600, "1h0m"}, {3661, "1h1m"},
	}
	for _, c := range cases {
		if got := fmtDur(c.sec); got != c.want {
			t.Errorf("fmtDur(%d)=%q want %q", c.sec, got, c.want)
		}
	}
}
