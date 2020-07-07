package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
)

func main() {
	http.HandleFunc("/", SAMLServer)
	log.Printf("Starting HTTP server at 127.0.0.1:35001")
	http.ListenAndServe("127.0.0.1:35001", nil)
}

func SAMLServer(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "POST":
		if err := r.ParseForm(); err != nil {
			fmt.Fprintf(w, "ParseForm() err: %v", err)
			return
		}
		SAMLResponse := r.FormValue("SAMLResponse")
		if len(SAMLResponse) == 0 {
			log.Printf("SAMLResponse field is empty or not exists")
			return
		}
		ioutil.WriteFile("saml-response.txt", []byte(url.QueryEscape(SAMLResponse)), 0600)
		fmt.Fprintf(w, "Got SAMLResponse field, it is now safe to close this window\n")
		log.Printf("Got SAMLResponse field and saved it to the saml-response.txt file")
		return
	default:
		fmt.Fprintf(w, "Error: POST method expected, %s recieved", r.Method)
	}
}
