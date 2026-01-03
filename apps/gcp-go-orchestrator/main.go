package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

type Event struct {
	Source   string `json:"source"`
	Filename string `json:"filename"`
	Version  string `json:"schema_version"`
}

func health(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("ok"))
}

func process(w http.ResponseWriter, r *http.Request) {
	var evt Event
	if err := json.NewDecoder(r.Body).Decode(&evt); err != nil {
		http.Error(w, "invalid payload", http.StatusBadRequest)
		return
	}

	log.Printf("Processing file %s (schema %s)", evt.Filename, evt.Version)

	resp := map[string]string{
		"status":  "processed",
		"service": "gcp-go-orchestrator",
		"env":     os.Getenv("ENV"),
	}

	json.NewEncoder(w).Encode(resp)
}

func main() {
	http.HandleFunc("/health", health)
	http.HandleFunc("/process", process)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Fatal(http.ListenAndServe(":"+port, nil))
}
