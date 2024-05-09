---
layout: post
title:  "How to setup database connection on go project"
date:   2023-06-07 08:00:00 +0700
categories: updates
tags: ['golang', 'database', 'singleton', 'postgresql', 'pgx']
description: |
  Go is great and popular programming language. Capable of great performance, versatile and its simple syntax make Go is the default choice for many companies.
  Most of Go project will connect to the database in their codebase. So how do we setup database connection in Go project?
---

Go is great and popular programming language. It boast many different capabilities. The language can deliver great performance (near the level of C / C++). 
It is versatile, with Go you can build diverse applications from cli app to webserver, supported by many packages. Go supports concurrency by defaults, it is built in in the language.
These capabilities, makes Go is the default language used by many companies.

Many projects written in Go requires connection to database and of course Go greatly supports them.
How do we setup database connection in Go? Lets find out.

### Prerequisites

Before we start, make sure you have the following installed in your operating system:
- Go 1.16+
- Postgre SQL

### Setup

First, we need to create a new folder named `go_database_example` and init a new go module there.
It is always advised to use your domain / git repositories URI to prefix your go module name. 
You can read it here for more info about [go module naming](https://stackoverflow.com/questions/70724050/why-we-should-use-a-url-for-the-go-module-name)

```bash
mkdir go_database_example && cd go_database_example
go mod init github.com/NurfitraPujo/go_database_example
```

Then, let's configure some files and folders for our project.

```bash
mkdir -p {db,internal}
touch main.go db/pg.go
```

### Initialize the app

For demonstration purpose we will create simple http server app (because it has many tutorials). 
We will use go built in http package for this. Below code is simple http server used as demonstration only.

```go
// main.go
package main

func main() {
    router := http.NewServeMux()
    router.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
        if req.URL.Path != "/" {
            http.NotFound(w, req)
            return
        }
        fmt.Fprintf(w, "Welcome to the home page!")
    })
    err := http.ListenAndServe(":8000", router)
    if err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}
```

Now run the app by using `go run main.go`. Then lets test our simple http server by executing curl request `curl -XGET 'localhost:8000'`.
The output shoult be `Welcome to the home page!%`.

### Initialize database connection

Now, we are into the main topic. First thing first install the go postgresql driver below.

```bash
go get github.com/jackc/pgx/v5
```

Then we initiate our database package.

```go
// db/pg.go
package db

import (
	"context"

	"github.com/jackc/pgx/v5"
)

var dbInstance *pgx.Conn

func OpenDb(ctx context.Context, dsn string) error {
	conn, err := pgx.Connect(ctx, dsn)
	
	if err != nil {
		return err
	}

	dbInstance = conn
	return nil
}

func Db() *pgx.Conn {
	return dbInstance
}
```

Now, for the explanations for the code above:
We define new variable called `dbInstance` with the type of `pgx.Conn`, this variable will be used by our application to run query to the database. But we don't want the variable be accessible by other packages as it is to prevent accidental reassignment, so we declare new function `Db()` that will return that variable instead. 

Now we define function `OpenDb()` to initialize our dbInstance variable. It takes context and dsn as arguments, context is usually used to control the execution flow of golang process which will be not discussed in this article, on the other hand dsn is connection string consisted of database driver, host, port, username, password and database name. The format of dsn is:
```
posrgresql://<user>:<password>@<host>:<port>/<dbname>?<params1=value1>..
```
we use `pgx.Connect` function to make a connection to our postgres database, it will return an instance of database connection `pgx.Conn` and error. We will return the error if there is an error during establishing connection, else we will initialize the `dbInstance` variable with the database connection.

Seems simple enough, right?? This code may seem fine at first, but it will pose some problem, because it always initiate new connection when it is called. 
Huh, whats wrong with that? You see, continuously creating new connection everytime the OpenDb instance is called will potentially make you application crashes when dealing with concurrent actions / processes that use the db instance (because it is global variable).
Supposedly process A calls `OpenDb()` and still working on operations, now our application spawn new process B which also calls `OpenDb()`, what do you think will happen? The `dbInstace` used by process A will be overridden by process B, which risk failing the entire process.
This is what you call no Thread Safety.

Okay, We know it's bad, lets fix that.
We will use go `sync.Once` to make sure that the database connection will only be established once per our application lifetime (singleton).

```go
// db/pg.go
var (
	dbInstance *pgx.Conn
	dbSync sync.Once
)

func OpenDb(ctx context.Context, dsn string) error {
	var err error
	dbSync.Do(func() {
		conn, connectErr := pgx.Connect(ctx, dsn)
		err = connectErr
		dbInstance = conn
	})
	
	if err != nil {
		return err
	}

	return nil
}
```

Using the `dbSync.Do()` we can make sure that the function provided (closure) will only be executed once across processes in our application lifetime.
We also moved the error declaration outside the closure because the parent function would not be able to read it otherwise.
Alright, that should be fine right? Not exactly. 


Remember our `dbInstance` variable will hold the database connection for our entire app? 
The bad news is, database connection has its own lifetime. When the connection lifetime is expired the connection cannot be used and our operation will fail.
Then why don't we just remove the connection lifetime? Maybe we can, but usually we use connection lifetime as a gate keeping if there an unoptimized query (eg: *unnecessary long running query*). 
If there are long running query and it raises error because connection expired then we can know the specific query and improve it. 
*Remember, silent bugs and failures is recipe of disaster*.

So, how to to prevent failures because of connection expires? Fortunately there are feature named *Connection Pooling*.
Almost every dbms has Connection Pooling feature built in. What is it? I will quote from [arctype](https://arctype.com/blog/connnection-pooling-postgres/#:~:text=comes%20into%20play.-,What%20is%20connection%20pooling%3F,active%20connection%20to%20the%20user.) since it has concise explanation.

> Connection pooling is the process of having a pool of active connections on the backend servers. 
> These can be used any time a user sends a request. 
> Instead of opening, maintaining, and closing a connection when a user sends a request, the server will assign an active connection to the user.

Now, go native package `database/sql` actually has connection pooling feature built in. But for pgx, we can use their dedicated package for it `pgxpool`.
Let's install and modify our code using it.

```bash
go get github.com/jackc/pgx/v5/pgxpool
```

There are not much code changes here, we just change our global variable type and use `pgxpool.New()` instead of `pgx.Connect`.

```go
import (
	"context"
	"sync"

	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	dbInstance *pgxpool.Pool
	dbSync     sync.Once
)

func OpenDb(ctx context.Context, dsn string) error {
	var err error
	dbSync.Do(func() {
		pool, connectErr := pgxpool.New(ctx, dsn)
		err = connectErr
		dbInstance = pool
	})

	if err != nil {
		return err
	}

	return nil
}

func Db() *pgxpool.Pool {
	return dbInstance
}
```

That's it, I think this code is good enough for now to use it in production environment.

### Assembling the pieces together

Now that we already write the database initialization logic, let's use it in our application.
First, we initialize our database connection and handle the error if not nil. After that we get the db instance, and use it to run our query.
Here, we use simple select to return hardcoded string, just to test if our database connection is functioning as expected.

```go
// main.go
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"

	"github.com/NurfitraPujo/go_database_example/db"
)

func main() {
	ctx := context.Background()
	err := db.OpenDb(ctx, "postgres://dbexample:test123@localhost:5432/db_example")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	db := db.Db()

	router := http.NewServeMux()
	router.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/" {
			http.NotFound(w, req)
			return
		}
		var result string;

		raw := db.QueryRow(ctx, "SELECT 'Welcome to the database!' as result;")

		err = raw.Scan(&result)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprint(w, err.Error())
		}

		fmt.Fprint(w, result)
	})

	err = http.ListenAndServe(":8000", router)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
```

Before we run that, we need to create our user and database first.

```bash
PGPASSWORD=<your postgres user password> psql -h localhost -p 5432 -c "CREATE USER dbexample WITH PASSWORD 'test123';" -U postgres
PGPASSWORD=<your postgres user password> psql -h localhost -p 5432 -c 'CREATE DATABASE db_example;' -U postgres
PGPASSWORD=<your postgres user password> psql -h localhost -p 5432 -c 'GRANT ALL PRIVILEGES ON DATABASE db_example TO dbexample;' -U postgres
```

Now we can run `main.go`. To test our new changes we can use the curl command again. The result should be `Welcome to the database!%`

```bash
curl -XGET 'localhost:8000'
```

### Summary

When configuring our database connection initialization we need to make sure:

1. Thread Safety. Make sure our database instance would not be changed by other processes when our app run in concurrency.
2. Manage connection pooling, if your driver has built in support for managing database pool use it. If not make sure to manage it manually on connection initialization.

Thank you for reading until the end. Because this blog still doesn't have comment features, if you have any constructive feedback for me or for this article please share it with me by [email](https://mail.google.com/mail/?to=fitrapujo@gmail.com&subject=Hey#I#have#feedback#on).