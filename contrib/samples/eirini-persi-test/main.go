package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path"
)

type Volume struct {
	Dir string `json:"container_dir"`
}

type Persi struct {
	VolumeMounts []Volume `json:"volume_mounts"`
}

var Created bool

func main() {
	fmt.Println("Starting eirini persi app")
	Created = false
	http.HandleFunc("/", handler)

	Services := os.Getenv("VCAP_SERVICES") // Get JSON from Env
	var Persi map[string][]Persi           // This is our structure
	err := json.Unmarshal([]byte(Services), &Persi)
	if err != nil {
		panic(err)
	}
	PersiDir := Persi["eirini-persi"][0].VolumeMounts[0].Dir
	PersiTestFile := path.Join(PersiDir, "persitest")
	if !fileExists(PersiTestFile) {
		fmt.Println("Creating persistence file in ", PersiTestFile)
		d1 := []byte("persitest\n")
		err := ioutil.WriteFile(PersiTestFile, d1, os.ModePerm)
		if err != nil {
			panic(err)
		}
		Created = true
	} else {
		fmt.Println("Persistence file already exists")
	}

	http.ListenAndServe(":"+os.Getenv("PORT"), nil)
}

func fileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}
func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Serving request", r)
	if Created {

		fmt.Fprintf(w, "1")
		return
	}

	fmt.Fprintf(w, "0")
}
