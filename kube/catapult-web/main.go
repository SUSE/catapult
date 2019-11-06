package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os/exec"
	"os"
	"strings"
	"html/template"
)

func main() {
	http.HandleFunc("/", ClusterToTTy)
	fmt.Println(http.ListenAndServe(":8080", nil))
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

func ListClusters() []string {
	out, err := exec.Command(`docker`, `ps`,`-f`, `name=catapult-wtty`,`--format={{.Names}}`).Output()

	if err != nil {
		return []string{}	}

	clusters:=strings.Split(strings.TrimSpace(string(out)),"\n")

	for i, c:= range clusters {
		clusters[i]=strings.Replace(c,"catapult-wtty-","",1)
	}

	return clusters
}
func ClusterToTTy(w http.ResponseWriter, r *http.Request) {
	var host string
	data := strings.Split(r.Host, ":")
	host = data[0]

	clusterName := r.URL.Path[1:]
	if clusterName == "" {
		Render(w,    ClusterData{ApiURL: os.Getenv("EKCP_HOST"),
			Clusters: ListClusters(),
			Host: r.Host} )
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


// Templating
const Index = `

<!doctype html>
<html lang="en">
  <head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">

    <title>Catapult web</title>
  </head>
  <body>
  <div class="container">
	<div class="jumbotron">
	<h1 class="display-4">Welcome to Catapult web!</h1>
	<p class="lead">Here you can find web ttys for clusters deployed in {{.ApiURL}}</p>
	<hr class="my-4">
	<p>It uses catapult terminal module to bring your cluster to the browser.</p>
	<a class="btn btn-primary btn-lg" href="http://{{.ApiURL}}/ui" role="button" target='_blank'>EKCP Dashboard</a>
	</div>

    <!-- Optional JavaScript -->
    <!-- jQuery first, then Popper.js, then Bootstrap JS -->
    <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>
	<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>
	
	{{ $baseurl := .Host }}

	<br>
	<h2>Available clusters</h2> <br>

	<div class="list-group list-group-flush">
	{{range .Clusters}}
		<a href='http://{{$baseurl}}/{{.}}' target='_blank' class="list-group-item list-group-item-action">{{.}}</a>
	{{end}}
	</div>
  </div>
  </body>
</html>
`

type ClusterData struct {
	ApiURL string
	Clusters []string
	Host string
}

func Render(w http.ResponseWriter, data ClusterData)  {
    t := template.New("main page")
	t, _ = t.Parse(Index)		
    t.Execute(w, data)
}