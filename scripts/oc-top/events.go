package main

import (
	"bufio"
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// Entry is one parsed Activity timeline row.
type Entry struct {
	Time      time.Time
	Kind      string // tool, text, finish, error
	Tool      string
	Title     string
	Summary   string
	Status    string
	Text      string
	TokensIn  int
	TokensOut int
	Cost      float64
	Message   string
}

const maxTimeline = 2000

type rawEvent struct {
	Type      string          `json:"type"`
	Timestamp int64           `json:"timestamp"`
	Part      json.RawMessage `json:"part"`
	Error     json.RawMessage `json:"error"`
}

type rawPart struct {
	Tool   string  `json:"tool"`
	Text   string  `json:"text"`
	Cost   float64 `json:"cost"`
	Tokens struct {
		Input  int `json:"input"`
		Output int `json:"output"`
	} `json:"tokens"`
	State struct {
		Status string         `json:"status"`
		Title  string         `json:"title"`
		Input  map[string]any `json:"input"`
	} `json:"state"`
}

type rawError struct {
	Message string `json:"message"`
}

// summaryKeys are tried in order when building the short input text.
var summaryKeys = []string{"command", "path", "file", "pattern", "query"}

// summaryInput returns the one-line summary of a tool call.
func summaryInput(tool string, input map[string]any) string {
	_ = tool
	for _, k := range summaryKeys {
		if v, ok := input[k]; ok {
			if s, ok := v.(string); ok && strings.TrimSpace(s) != "" {
				return shortOneLine(s)
			}
		}
	}
	return ""
}

// shortOneLine flattens whitespace to one line and caps the length.
func shortOneLine(s string) string {
	s = strings.Join(strings.Fields(s), " ")
	if len([]rune(s)) > 80 {
		runes := []rune(s)
		s = string(runes[:77]) + "…"
	}
	return s
}

// parseLine turns one events.jsonl line into an entry.
// ok is false for lines that carry no timeline row.
func parseLine(line string) (Entry, bool) {
	raw := rawEvent{}
	if err := json.Unmarshal([]byte(line), &raw); err != nil {
		return Entry{}, false
	}
	e := Entry{}
	if raw.Timestamp > 0 {
		e.Time = time.UnixMilli(raw.Timestamp)
	}
	switch raw.Type {
	case "tool_use":
		p := rawPart{}
		if err := json.Unmarshal(raw.Part, &p); err != nil {
			return Entry{}, false
		}
		e.Kind = "tool"
		e.Tool = p.Tool
		e.Title = p.State.Title
		if e.Title == "" {
			e.Title = p.Tool
		}
		e.Status = p.State.Status
		e.Summary = summaryInput(p.Tool, p.State.Input)
		return e, true
	case "text":
		p := rawPart{}
		if err := json.Unmarshal(raw.Part, &p); err != nil {
			return Entry{}, false
		}
		if strings.TrimSpace(p.Text) == "" {
			return Entry{}, false
		}
		e.Kind = "text"
		e.Text = p.Text
		return e, true
	case "step_finish":
		p := rawPart{}
		if err := json.Unmarshal(raw.Part, &p); err != nil {
			return Entry{}, false
		}
		e.Kind = "finish"
		e.TokensIn = p.Tokens.Input
		e.TokensOut = p.Tokens.Output
		e.Cost = p.Cost
		return e, true
	case "error":
		er := rawError{}
		_ = json.Unmarshal(raw.Error, &er)
		e.Kind = "error"
		e.Message = er.Message
		if e.Message == "" {
			e.Message = "unknown error"
		}
		return e, true
	}
	return Entry{}, false
}

// statusFromText returns the last STATUS: value in a text event, if any.
func statusFromText(text string) string {
	matches := regexp.MustCompile(`(?i)STATUS:\s*([A-Za-z][A-Za-z0-9_-]*)`).FindAllStringSubmatch(text, -1)
	if len(matches) == 0 {
		return ""
	}
	return strings.ToLower(matches[len(matches)-1][1])
}

// tail appends newly written events to the timeline.
// It resumes from the last offset and resets when the file shrinks.
func tail(r *Run) bool {
	path := filepath.Join(r.Dir, "events.jsonl")
	st, err := os.Stat(path)
	if err != nil {
		return false
	}
	if st.Size() < r.Offset {
		r.Offset = 0
		r.Timeline = nil
		r.ToolHist = map[string]int{}
		r.ToolCount = 0
		r.LastTool = ""
		r.Cost = 0
		r.EventStatus = ""
		r.Version++
	}
	if st.Size() == r.Offset {
		return false
	}
	f, err := os.Open(path)
	if err != nil {
		return false
	}
	defer f.Close()
	if _, err := f.Seek(r.Offset, 0); err != nil {
		return false
	}
	rd := bufio.NewReader(f)
	data, err := rd.ReadBytes(0)
	_ = err
	// Only complete lines are consumed, so a trailing partial line stays unread.
	last := -1
	for i, b := range data {
		if b == '\n' {
			last = i
		}
	}
	if last < 0 {
		return false
	}
	keep := data[:last+1]
	r.Offset += int64(len(keep))
	added := false
	for _, line := range strings.Split(string(keep), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		e, ok := parseLine(line)
		if !ok {
			continue
		}
		r.Timeline = append(r.Timeline, e)
		added = true
		if e.Kind == "text" {
			if status := statusFromText(e.Text); status != "" {
				r.EventStatus = status
				if !r.Running && !r.StateKnown {
					r.State = status
				}
			}
		}
		if e.Kind == "tool" {
			r.ToolCount++
			r.LastTool = e.Tool
			r.ToolHist[e.Tool]++
		}
		if e.Kind == "finish" {
			r.Cost += e.Cost
		}
	}
	if len(r.Timeline) > maxTimeline {
		r.Timeline = append([]Entry(nil), r.Timeline[len(r.Timeline)-maxTimeline:]...)
	}
	if added {
		r.Version++
	}
	return added
}
