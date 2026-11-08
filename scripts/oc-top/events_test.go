package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func toolLine(tool, status string, input string) string {
	return fmt.Sprintf(`{"type":"tool_use","timestamp":1794158473532,"sessionID":"ses_a","part":{"partID":"p1","tool":%q,"state":{"status":%q,"title":%q,"input":%s}}}`,
		tool, status, tool, input)
}

func TestTailIncremental(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	p := filepath.Join(dir, "events.jsonl")
	writeFile(t, p, toolLine("read", "completed", `{"path":"/a/b.go"}`)+"\n")
	r := &Run{Dir: dir, ToolHist: map[string]int{}}
	if !tail(r) {
		t.Fatal("first tail: added=false, want true")
	}
	if len(r.Timeline) != 1 {
		t.Fatalf("timeline=%d, want 1", len(r.Timeline))
	}
	if r.ToolCount != 1 || r.LastTool != "read" {
		t.Fatalf("count=%d last=%q, want 1/read", r.ToolCount, r.LastTool)
	}
	if tail(r) {
		t.Fatal("second tail without growth: added=true, want false")
	}
	// append two more lines, tail should only read the new ones
	f, err := os.OpenFile(p, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := f.WriteString(toolLine("shell", "completed", `{"command":"ls -la"}`) + "\n"); err != nil {
		t.Fatal(err)
	}
	if _, err := f.WriteString(toolLine("read", "completed", `{"path":"/c.go"}`) + "\n"); err != nil {
		t.Fatal(err)
	}
	f.Close()
	if !tail(r) {
		t.Fatal("third tail: added=false, want true")
	}
	if len(r.Timeline) != 3 {
		t.Fatalf("timeline=%d, want 3", len(r.Timeline))
	}
	if r.ToolCount != 3 || r.LastTool != "read" {
		t.Fatalf("count=%d last=%q, want 3/read", r.ToolCount, r.LastTool)
	}
	if r.Timeline[1].Tool != "shell" || r.Timeline[2].Tool != "read" {
		t.Fatalf("order=%q,%q, want shell,read", r.Timeline[1].Tool, r.Timeline[2].Tool)
	}
}

func TestTailTruncationReset(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	p := filepath.Join(dir, "events.jsonl")
	writeFile(t, p, toolLine("read", "completed", `{"path":"/a.go"}`)+"\n"+toolLine("edit", "completed", `{"path":"/b.go"}`)+"\n")
	r := &Run{Dir: dir, ToolHist: map[string]int{}}
	if !tail(r) {
		t.Fatal("first tail: added=false, want true")
	}
	if r.ToolCount != 2 {
		t.Fatalf("count=%d, want 2", r.ToolCount)
	}
	// the file is truncated and rewritten smaller, as on a fallback retry
	writeFile(t, p, toolLine("shell", "completed", `{"command":"go vet ./..."}`)+"\n")
	if !tail(r) {
		t.Fatal("tail after truncation: added=false, want true")
	}
	if len(r.Timeline) != 1 || r.Timeline[0].Tool != "shell" {
		t.Fatalf("timeline=%v, want one shell entry", r.Timeline)
	}
	if r.ToolCount != 1 {
		t.Fatalf("count=%d, want 1 after reset", r.ToolCount)
	}
}

func TestTailNonJSONSkipped(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	p := filepath.Join(dir, "events.jsonl")
	lines := []string{
		"this is not json",
		toolLine("read", "completed", `{"path":"/a.go"}`),
		"{\"partial\": ",
		"",
		`{"type":"step_start","timestamp":1794158473518,"part":{"type":"step-start"}}`,
		toolLine("shell", "completed", `{"command":"echo hi"}`),
	}
	writeFile(t, p, strings.Join(lines, "\n")+"\n")
	r := &Run{Dir: dir, ToolHist: map[string]int{}}
	if !tail(r) {
		t.Fatal("tail: added=false, want true")
	}
	if len(r.Timeline) != 2 {
		t.Fatalf("timeline=%d, want 2", len(r.Timeline))
	}
	if r.ToolCount != 2 {
		t.Fatalf("count=%d, want 2", r.ToolCount)
	}
	// offset must have advanced past the bad lines
	st, _ := os.Stat(p)
	if r.Offset != st.Size() {
		t.Errorf("offset=%d, want %d", r.Offset, st.Size())
	}
}

func TestSummaryInput(t *testing.T) {
	t.Parallel()
	cases := []struct {
		tool  string
		input string
		want  string
	}{
		{"shell", `{"command":"cd /x && go test ./..."}`, "cd /x && go test ./..."},
		{"read", `{"path":"/a/b.go"}`, "/a/b.go"},
		{"edit", `{"newString":"x","oldString":"y","path":"/a/b.go"}`, "/a/b.go"},
		{"write", `{"content":"hello","path":"/a/b.go"}`, "/a/b.go"},
		{"grep", `{"pattern":"TODO"}`, "TODO"},
		{"read", `{"limit":5,"offset":10,"path":"/a/b.go"}`, "/a/b.go"},
		{"skill", `{}`, ""},
		{"bash", `{"command":""}`, ""},
		{"shell", `{"command":"echo  hello   world"}`, "echo hello world"},
		{"shell", `{"command":"` + strings.Repeat("x", 100) + `"}`, strings.Repeat("x", 77) + "…"},
	}
	for _, c := range cases {
		var input map[string]any
		if err := json.Unmarshal([]byte(c.input), &input); err != nil {
			t.Fatal(err)
		}
		if got := summaryInput(c.tool, input); got != c.want {
			t.Errorf("summaryInput(%s, %s)=%q want %q", c.tool, c.input, got, c.want)
		}
	}
}

func TestStepFinishCost(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	p := filepath.Join(dir, "events.jsonl")
	line := `{"type":"step_finish","timestamp":1794158473518,"part":{"cost":0.00123,"tokens":{"input":100,"output":50}}}`
	writeFile(t, p, line+"\n"+line+"\n")
	r := &Run{Dir: dir, ToolHist: map[string]int{}}
	if !tail(r) {
		t.Fatal("tail: added=false, want true")
	}
	if len(r.Timeline) != 2 {
		t.Fatalf("timeline=%d, want 2", len(r.Timeline))
	}
	if r.Cost < 0.00245 || r.Cost > 0.00247 {
		t.Errorf("cost=%v, want ~0.00246", r.Cost)
	}
	if r.Timeline[0].TokensIn != 100 || r.Timeline[0].TokensOut != 50 {
		t.Errorf("tokens=%d/%d, want 100/50", r.Timeline[0].TokensIn, r.Timeline[0].TokensOut)
	}
}

func TestErrorAndTextEntries(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	p := filepath.Join(dir, "events.jsonl")
	lines := []string{
		`{"type":"text","timestamp":1794158473523,"part":{"type":"text","text":"hello there"}}`,
		`{"type":"error","timestamp":1794158473600,"error":{"type":"provider.internal","message":"boom"}}`,
		`{"type":"retry","timestamp":1794158473601,"error":{"message":"noisy"}}`,
	}
	writeFile(t, p, strings.Join(lines, "\n")+"\n")
	r := &Run{Dir: dir, ToolHist: map[string]int{}}
	if !tail(r) {
		t.Fatal("tail: added=false, want true")
	}
	if len(r.Timeline) != 2 {
		t.Fatalf("timeline=%d, want 2 (text+error, retry ignored)", len(r.Timeline))
	}
	if r.Timeline[0].Kind != "text" || r.Timeline[0].Text != "hello there" {
		t.Errorf("entry 0 = %+v", r.Timeline[0])
	}
	if r.Timeline[1].Kind != "error" || r.Timeline[1].Message != "boom" {
		t.Errorf("entry 1 = %+v", r.Timeline[1])
	}
}
