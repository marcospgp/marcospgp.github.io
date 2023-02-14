---
layout: post
title: SQLite Checklist
tag: Web 💻
---

This is a field guide on setting up and making use of SQLite in the strictest, least error-prone way possible. Examples are based on Python, which provides SQLite as part of its standard library.

## The Checklist

- [Multithreading](#multithreading): Share a connection between multiple threads by first ensuring that SQLite is in serialized mode (`sqlite3.threadsafety == 3`), then creating the connection with `check_same_thread=False`;
- [Strict tables](#strict-tables): Always declare tables as strict in order to enforce type checking and make primary keys non-nullable by default;
- [Numeric primary keys](#numeric-primary-keys) should always be declared with the type `INTEGER` verbatim to become aliases for `rowid` and avoid additional computation;
- [Max length](#max-length): Text columns should always have a max length (unless foreign keys), to avoid attacks;
- Columns should be not null unless null is necessary - this avoids missing data by mistake;
- Wrap column names in double quotes (`""`) to avoid overlap with [reserved keywords](https://www.sqlite.org/lang_keywords.html);
- [Booleans](#boolean) can be implemented with `CHECK ("BooleanColumn" IN (0, 1))`;
- [Indexes](#indexes) should be created on columns (or combinations of columns) that are frequently present in `WHERE` or `GROUP BY` clauses.

Here is a sample table that follows the checklist:

```sql
CREATE TABLE IF NOT EXISTS Users(
    "ID" INTEGER PRIMARY KEY,
    "Username" TEXT NOT NULL CHECK (length("Username") < 128),
    "IsBanned" INT NOT NULL CHECK ("IsBanned" IN (0, 1)),
    "Role" TEXT NOT NULL,

    FOREIGN KEY ("Role") REFERENCES Roles("Name")
) STRICT;
```

## SQLite

[SQLite](https://www.sqlite.org/) claims to be the most used database in the world.
In my view, it is solid and useful, and can scale far further than one will most likely ever need it to.

Being file based, one doesn't need to set up a standalone server - it can just sit alongside the rest of the app's code. This is what makes it attractive for me - it is the easiest way to get the power of SQL.

It was initially brought to my attention by [Pieter Levels](https://twitter.com/levelsio/status/1520356430800617472), who is famous for using the simplest possible tech that gets the job done.

This file based set up means SQLite is not a good idea for a containerized deployment, but I think it is perfect for a single server setup - such as renting a VPS for personal projects.

Unfortunately, SQLite has a lot of quirks. Its type system is weirdly relaxed, for example - yet the author swears by it. In this guide I outline an approach to using it in a strict and predictable way, using a Python & Flask setup as an example.

## Multithreading

The [Flask docs](https://flask.palletsprojects.com/en/2.2.x/patterns/sqlite3/) suggest opening and closing one SQLite database connection per HTTP request. This is unnecessarily inefficient - a connection should instead be kept open and shared.

As it turns out, this is indeed possible, as long as you ensure SQLite was compiled in [serialized mode](https://docs.python.org/3/library/sqlite3.html#sqlite3.threadsafety) (`sqlite3.threadsafety == 3`):

```python
import sqlite3

# Ensure SQLite is in serialized mode, which makes it safe to set
# check_same_thread=False.
# This allows us to share a global connection to the database without causing
# "Objects created in a thread can only be used in that same thread" error with
# Flask ("Flask, as a WSGI application, uses one worker to handle one
# request/response cycle").
#
# Based on https://ricardoanderegg.com/posts/python-sqlite-thread-safety/
#
# Info on threadsafety attribute:
# https://docs.python.org/3/library/sqlite3.html#sqlite3.threadsafety
#
if sqlite3.threadsafety != 3:
    raise Exception(
        "SQLite is not in serialized mode (sqlite3.threadsafety != 3). " \
        "Cannot proceed."
    )
```

So an SQLite connection will throw an error if accessed from a thread other than the one that created it, but this can be disabled by creating the connection with `check_same_thread=False` ([documented here](https://docs.python.org/3/library/sqlite3.html#sqlite3.connect)):

```python
db = sqlite3.connect(
    "db.sqlite3",
    check_same_thread=False
)
```

## Strict Tables

Tables should always be declared as [strict](https://www.sqlite.org/stricttables.html) in order to enforce type checking and make primary keys non-nullable by default.

This can be done by including the `STRICT` keyword at the end of a table declaration:

```sql
CREATE TABLE IF NOT EXISTS User(
    "Name" TEXT NOT NULL CHECK (length("Name") < 64)
) STRICT;
```

### Types

These are the available types for **strict tables** in SQLite:

- INT
- REAL
- TEXT
- BLOB
- ANY

`INTEGER` can also be used in place of `INT`.

Outside of strict mode, SQLite will attempt to do some very weird guessing for other type names.

### Numeric Primary Keys

A numeric primary key will only be made an [alias for `rowid`](https://www.sqlite.org/autoinc.html) if declared with the type `INTEGER` verbatim (who knows why!).

### Boolean

Boolean can be implemented with a `CHECK ("BooleanColumn" IN (0, 1))`.
It takes up one byte, as int size is flexible in SQLite.

## Max Length

Text columns should always have a max length, to avoid attacks where intentionally large payloads are stored by a malicious user. It is easy to forget to do this before the query hits the database.

If the column is a foreign key, this isn't necessary, as values will be limited to those already present in the targeted column (which should have its own max length, if it is of type text).

## Indexes

Indexes (or indices, if you prefer) are a complex topic. Ideally you will have specific queries in a real situation to ensure you are doing the right thing, but I still try to provide a general rule of thumb.

For each table, consider creating indexes on columns that are frequently present in `WHERE` or `GROUP BY` clauses.

The counter example is when you have a column with low cardinality (few possible values) and a very equal distribution (such as a boolean with rows being 50% true and 50% false).

Indexes are a tradeoff between faster querying speed for reading and lower speed for writing and updating, as well as increased storage space.

In my view, indexes feel very underused - the cost seems quite low for what can potentially be a large speedup. Ideally the user would be warned when an index could dramatically speed up an operation - and perhaps that is present in more advanced databases.
