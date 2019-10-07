package main
import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	http.HandleFunc("/", handler)

	ticker := time.NewTicker(2 * time.Second)
	instanceGuid := os.Getenv("CF_INSTANCE_GUID") + ":" + os.Getenv("CF_INSTANCE_INDEX")

	go func() {
		for t := range ticker.C {

			fmt.Printf("[%s] Ticking %s\n", instanceGuid, t.Format("2006-01-01 15:04:05"))
		}
	}()

	http.ListenAndServe(":"+os.Getenv("PORT"), nil)
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Leave me alone, I'm ticking in logs!")
}