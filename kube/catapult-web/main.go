package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os/exec"
	"strings"
)

func main() {
	http.HandleFunc("/", ClusterToTTy)
	http.ListenAndServe(":8080", nil)
}

type Hosts struct {
	HostPort string `json:"HostPort"`
}
type NetworkSettings struct {
	Ports map[string][]Hosts `json:"Ports"`
}

type Data struct {
	NetworkSettings `json:"NetworkSettings"`
}

func ClusterToTTy(w http.ResponseWriter, r *http.Request) {
	var host string
	data := strings.Split(r.Host, ":")
	host = data[0]

	clusterName := r.URL.Path[1:]
	if clusterName == "" {
		return
	}
	out, err := exec.Command(`docker`, `inspect`, `catapult-wtty-`+clusterName+``).Output()
	if err != nil {
		fmt.Fprintf(w, "Error, %s! %s", err.Error(), out)
	}
	Host := []Data{}
	err = json.Unmarshal(out, &Host)
	if err != nil {
		fmt.Fprintf(w, "Error, %s! %s", err.Error(), out)
	}
	http.Redirect(w, r, "http://"+host+":"+string(Host[0].NetworkSettings.Ports["8080/tcp"][0].HostPort), http.StatusSeeOther)
}
