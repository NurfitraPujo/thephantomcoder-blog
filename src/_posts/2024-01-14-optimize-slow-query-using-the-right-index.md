---
layout: post
title: "Optimize Slow Query Part 1 - Using the right index"
date: 2024-01-14 07:00:00 +0700
categories: updates
published: true
tags: ['database', 'postgresql', 'sql']
description: |
  Database indexes are easy and low hanging fruit for optimizing database performance. By adding the right index you can drastically improve your application queries performance. Unfortunately in many cases index are not used effectively causing many slow queries. So how can we optimize a slow query by building the right index?
---

In current digital era, data are one of the most important assets of a company, there are even a saying "Data is the new oil". To manage company data usually DBMS is used such as PostgreSQL, MySQL, SQLServer, etc abstracted by applications. Now that we are already agree that databases are important parts for most applications, that means if any issue happened on databases are very critical right? right?. I have seen organizations got cancelled by their customers (aka churned) because issue on their databases, scary.

One of the most common issue in databases are slow query. Slow query may seem trivial at the first glance, but if ignored for long it will lead to many different critical database issues such as: cancelled queries, cpu usage spike, memory hog, connection pool is full and worse are database down because combination of these different issues. But how can slow query cause these issues? Let's save the deep div for later, now we will focus on one of the low hanging fruits to optimize slow queries. That is, effective database indexes.

## Know thy Index!

There are many kinds of index across dbms and even for the same kind of index may have different implementations and quirks. In this article we will discuss briefly about two of the most commonly used index types: B-Tree and Hash.

### B-Tree Index

Like its name suggest B-Tree index is structured like balanced tree where the leaf nodes are the indexed value and each of them contains reference to the actual table row. While implementations may differs from each dbms, but B-Tree indexes generally will be used when the query is involving one of these comparison operators `<   <=   =   >=   >`, `BETWEEN`, `IN`, `IS NULL`, and `IS NOT NULL`. B-Tree also able to be used for `LIKE` operators but there are caveats, the index will only be used when the pattern defined is on the beginning of the text like `LIKE 'title%'` and not `LIKE '%not used'`. But if you need for proper text searching it is better using Fulltext index instead.

Because how the index is structured, B-Tree is best suited for range comparison like date range, numerical range, etc. Because B-Tree would impose sorting order for each data inserted and its traversal requires to use greater than or equal to (>=) operator [(read here)](https://use-the-index-luke.com/sql/anatomy/the-tree), values that are unique and can't be sorted (like UUID, email, etc.) won't be ideally optimized by B-Tree. For these kind of values it is better to use Hash index instead.

While very versatile there are several concern need to be considered when using B-Tree index. In large tables the time needed to find the specified data will increased because searches must descent throught the tree until the qualified leaf nodes found. These operations if done in high volume will stress the database CPU and IOPS. There are also concern about whether the indexed column have heavy workload for `UPDATE`, because updating the index every time the column value is update is very costly on B-Tree index.

The wide range of capabilities provided by B-Tree make it all purpose index types. When in doubt how the columns will be queried it is better to use B-Tree first then change later according the evaluated needs.

For more info about B-Tree index, you can read them in each dbms documentation page:

1. [PostgreSQL B-Tree index](https://www.postgresql.org/docs/current/btree-implementation.html#BTREE-IMPLEMENTATION)
2. [MySQL B-Tree index](https://dev.mysql.com/doc/refman/8.0/en/index-btree-hash.html)
3. [usetheindexluke](https://use-the-index-luke.com/sql/anatomy/the-tree)

### Hash Index

Hash Index is simpler, its structure is just a hash thus its very fast when used to retrieve row when query is involving equality ( `=` ) comparison. While it is very fast, Hash index only support query that are `=` operator, so if your query is using range equality comparison your dbms wont use hash index. Hash index are most suitable for unique or nearly unique data like UUID, emails (if your app constraint it), etc.

There are several reasons that make index Hash index is better than B-Tree for specific cases. Hash index is better thant B-Tree in `SELECT` and `UPDATE` heavy workloads because the cost of retrieving and updating data in Hash index is lower than B-Tree index, especially in large table. Because of its simple structure Hash index size is much smaller compared to B-Tree index. If your query resulting in single-record lookups Hash index is best suited for it. [This](https://evgeniydemin.medium.com/postgresql-indexes-hash-vs-b-tree-84b4f6aa6d61) are very interesting article comparing B-Tree index and Hash index which shown that Hash index performs better for specific scenarios. Do read it if you are interested on reading more.

However, there are several concerns needed to be considered before using Hash index. Hash index only support single column index, there are no way to use multiple column index unlike in B-Tree. Hash indexes also don’t have the ability to enforce uniqueness constraints, so we can't use `CREATE UNIQUE INDEX` when creating Hash index which may seem unintuitive in some scenarios. LASTLY if you are using older version of your dbms (< 10 for postgres) you better not using Hash index and just use B-Tree instead because there are many issue and efficiency issues related to Hash index in those versions.

For more info about Hash index, you can read them in each dbms documentation page:

1. [PostgreSQL Hash index](https://www.postgresql.org/docs/current/hash-intro.html)
2. [MySQL Hash index](https://dev.mysql.com/doc/refman/8.0/en/index-btree-hash.html)

## Conclusion

TWL (Today **We** Learned) learned about B-Tree and Hash index. While it is still challenging to build the right index for our tables, at least now we know where each of the index type is shine and when they need to be used with concerns. 

We will explore more about building the right index for slow queries in the next article, hopefully it is not delayed for too long. Thanks for reading throught, I hope this article can provide you insights. If you have any feedback regarding my article or my writings you can email me at `fitrapujo@gmail.com`. I will really appreciate any constructive feedback!
