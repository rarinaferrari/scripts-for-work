package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "1С:ПРЕДПРИЯТИЕ %s\n", r.URL.Path)
    })

    fmt.Println("Сервер запущен на порту 8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
