package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

func main() {
	http.HandleFunc("/", ClusterToTTy)
	http.HandleFunc("/create", PostHandler)

	fmt.Println(http.ListenAndServe(":8080", nil))
}

// PostHandler converts post request body to string
func PostHandler(w http.ResponseWriter, r *http.Request) {
	var host string
	data := strings.Split(r.Host, ":")
	host = data[0]
	if r.Method == "POST" {
		r.ParseForm()

		body := r.FormValue("json")
		// body, err := ioutil.ReadAll(r.Body)
		// if err != nil {
		// 	http.Error(w, "Error reading request body",
		// 		http.StatusInternalServerError)
		// }
		// fmt.Println(string(body))
		clusterName, _, err := Catapult(body, "scf-deploy", "module-extra-terminal")
		if err != nil {
			http.Error(w, "Error:"+err.Error(), http.StatusInternalServerError)
		}

		port, err := WttyPort(w, `catapult-deployment-wtty-`+clusterName+``)
		if err != nil {
			http.Error(w, "Error:"+err.Error(), http.StatusInternalServerError)
		}
		http.Redirect(w, r, "http://"+host+":"+port, http.StatusSeeOther)

	} else {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
	}
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

type CatapultConfig struct {
	Backend string `json:"BACKEND"`
	Name    string `json:"CLUSTER_NAME"`
}

func Catapult(config string, args ...string) (string, int, error) {
	//  docker run --name catapult-deployment-wtty-$i -d --rm -p 70$port:8080 -e EKCP_HOST=$EKCP_HOST -e CLUSTER_NAME=$i "$TTY_IMAGE"
	file, err := ioutil.TempFile(os.TempDir(), "catapult-web-")
	if err != nil {
		return "", 0, err
	}
	//defer os.Remove(file.Name())
	text := []byte(config)
	if _, err = file.Write(text); err != nil {
		return "", 0, err
	}

	var cataConfig CatapultConfig
	err = json.Unmarshal(text, &cataConfig)
	if err != nil {
		return "", 0, err
	}

	deployments := ListDeployments()
	portNumber := 61000 + len(deployments) + 1

	realArgs := []string{"run",
		"--name", "catapult-deployment-wtty-" + cataConfig.Name,
		"-d", "-ti", "--rm",
		"--entrypoint", "/usr/bin/ttyd",
		"-p", strconv.Itoa(portNumber) + ":8080",
		"-v", file.Name() + ":/catapult/default.config", // Dind - this requires the same tmpdir mounted from the host (sadly)
		"-e", "CONFIG=/catapult/default.config",
		"-e", "BACKEND=" + cataConfig.Backend,
		"-e", "FORCE_DELETE=true",
		"-w", "/catapult",
		os.Getenv("TTY_IMAGE"), "-o", "-p", "8080", "/bin/zsh", "-c"}

	cataCmd := []string{"/usr/bin/make"}
	for _, a := range args {
		cataCmd = append(cataCmd, a)
	}
	cataCmd = append(cataCmd, "; read -n 1")

	realArgs = append(realArgs, strings.Join(cataCmd, " "))

	fmt.Println("Launching", "docker")
	fmt.Println(realArgs)

	cmd := exec.Command("docker", realArgs...)
	out, err := cmd.CombinedOutput()
	fmt.Println(string(out))
	if err != nil {
		return "", 0, err
	}
	return cataConfig.Name, portNumber, nil
}

func ListDeployments() []string {
	out, err := exec.Command(`docker`, `ps`, `-f`, `name=catapult-deployment-wtty`, `--format={{.Names}}`).Output()
	if err != nil {
		return []string{}
	}
	if strings.TrimSpace(string(out)) == "" {
		return []string{}
	}
	clusters := strings.Split(strings.TrimSpace(string(out)), "\n")

	for i, c := range clusters {
		clusters[i] = strings.Replace(c, "catapult-deployment-wtty-", "", 1)
	}

	return clusters
}

func ListClusters() []string {
	out, err := exec.Command(`docker`, `ps`, `-f`, `name=catapult-wtty`, `--format={{.Names}}`).Output()
	if err != nil {
		return []string{}
	}

	if strings.TrimSpace(string(out)) == "" {
		return []string{}
	}

	clusters := strings.Split(strings.TrimSpace(string(out)), "\n")

	for i, c := range clusters {
		clusters[i] = strings.Replace(c, "catapult-wtty-", "", 1)
	}

	return clusters
}

func WttyPort(w http.ResponseWriter, containerName string) (string, error) {
	out, err := exec.Command(`docker`, `inspect`, containerName).Output()
	if err != nil {
		return "", err
	}
	Host := []Data{}
	err = json.Unmarshal(out, &Host)
	if err != nil {
		return "", err
	}
	return string(Host[0].NetworkSettings.Ports["8080/tcp"][0].HostPort), nil
}

func ClusterToTTy(w http.ResponseWriter, r *http.Request) {
	var host string
	data := strings.Split(r.Host, ":")
	host = data[0]

	clusterName := r.URL.Path[1:]
	if clusterName == "" {
		Render(w, ClusterData{ApiURL: os.Getenv("EKCP_HOST"),
			Clusters:    ListClusters(),
			Deployments: ListDeployments(),
			Host:        r.Host})
		return
	}
	var port string
	var err error
	if strings.Contains(r.URL.Path, "/deployment/") {
		clusterName := strings.Replace(r.URL.Path, "/deployment/", "", 1)
		if clusterName == "" {
			Render(w, ClusterData{ApiURL: os.Getenv("EKCP_HOST"),
				Clusters:    ListClusters(),
				Deployments: ListDeployments(),
				Host:        r.Host})
			return
		}
		port, err = WttyPort(w, `catapult-deployment-wtty-`+clusterName+``)
		if err != nil {
			fmt.Println(err)
		}
		http.Redirect(w, r, "http://"+host+":"+port, http.StatusSeeOther)
		return
	}
	port, err = WttyPort(w, `catapult-wtty-`+clusterName+``)
	if err != nil {
		fmt.Println(err)

	}
	http.Redirect(w, r, "http://"+host+":"+port, http.StatusSeeOther)
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
		<meta http-equiv="refresh" content="30">
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

	<hr>



	<div id="accordion">
		<div class="card">
			<div class="card-header" id="headingOne">
				<h5 class="mb-0">
					<button class="btn btn-link" data-toggle="collapse" data-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
						Deploy a new cluster with SCF
					</button>
				</h5>
			</div>

			<div id="collapseOne" class="collapse" aria-labelledby="headingOne" data-parent="#accordion">
				<div class="card-body">
			<div class="alert alert-warning" role="alert">
				<b>Note</b>: Deployments with the web console are unique for each session. <br>
				That means you cannot share the deployment link with somebody. 
			  The session is automatically terminated when you close the tab or press enter at the end of the process.
			</div>
				<form action="/create" method="post" class="px-4 py-3" >
					<div class="form-group ">
						<h5 class="card-title">Create a new deployment</h5>
						<p class="card-text"><label for="json">Paste your Catapult JSON config here and hit "Deploy"</label><br>
						For example, to deploy latest SCF you can just use:
						<pre><code>
{
 "CLUSTER_NAME": "test",
 "BACKEND": "ekcp",
 "EKCP_HOST": "{{.ApiURL}}"
}
						</code></pre>
						</p>
							<textarea class="form-control" id="json" name="json" rows="3"></textarea>
							<button type="submit" class="btn btn-primary mb-2">Deploy</button>
					</div>
				</form>
			</div>
		</div>
	</div>

	<hr>
	{{if not .Deployments}}
	{{else}}
	<h2>Running deployments</h2> <br>
	<div class="list-group list-group-flush">
	{{range .Deployments}}
		<a href='http://{{$baseurl}}/deployment/{{.}}' target='_blank' class="list-group-item list-group-item-action">{{.}}</a>
	{{end}}
	</div>
	{{end}}

	{{if not .Clusters}}
	{{else}}
	<hr>
	<h2>Running Clusters</h2> <br>
	<div class="list-group list-group-flush">
	{{range .Clusters}}
		<a href='http://{{$baseurl}}/{{.}}' target='_blank' class="list-group-item list-group-item-action">{{.}}</a>
	{{end}}
	</div>
	{{end}}

	</div>
	
  </body>
</html>
`

type ClusterData struct {
	ApiURL      string
	Clusters    []string
	Deployments []string
	Host        string
}

func Render(w http.ResponseWriter, data ClusterData) {
	t := template.New("main page")
	t, _ = t.Parse(Index)
	t.Execute(w, data)
}
