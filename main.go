// Command demo-app is a tiny token service used in the "Signed Isn't Enough" demo.
//
// It only issues HS256 JWTs and never parses or verifies them, so the
// golang-jwt/jwt/v5 parsing vulnerability CVE-2025-30204 (GO-2025-3553) is not
// reachable. vex/openvex.json records that claim; govulncheck backs it up.
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const banner = "demo-app: legitimate build from main"

func main() {
	key := []byte(os.Getenv("SIGNING_KEY"))
	if len(key) == 0 {
		key = []byte("demo-only-signing-key")
	}

	http.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Write([]byte("ok\n"))
	})
	http.HandleFunc("/token", func(w http.ResponseWriter, r *http.Request) {
		sub := r.URL.Query().Get("sub")
		if sub == "" {
			http.Error(w, "missing sub", http.StatusBadRequest)
			return
		}
		now := time.Now()
		claims := jwt.RegisteredClaims{
			Subject:   sub,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
		}
		signed, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(key)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"token": signed})
	})

	log.Println(banner)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
