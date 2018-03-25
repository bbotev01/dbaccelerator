# DBAccelerator

How can we make an awesome MPP system built on Postgres even faster? Using PgPool of course. This project is an example of how you can speed up Redshift and Greenplum queries anywhere from 10x to 100x and even more by harnessing the caching capabilities of PgPool. You can easily deploy and test in seconds using this Docker container.  

## How to build
First clone this repo. Then execute the following steps to build your container.
```sh
cd dbaccelerator 
docker build -t dbaccelerator .
```

## How to run
There are 3 environment variables you need to provide at runtime to the docker run command. 

| Variable | Description |
| ------ | ------ |
| TARGET_HOSTNAME | This is the hostname of your Master/Leader node you would normally be connecting to |
| TARGET_PORT | The port on which your MPP cluster is running on (5439 is the default for Redshift, 5432 is the default port for Greenplum) | 
| USER | The username you use to connect |
| PASS | The password associated with the user |

#### Example:
```sh
docker run -it --rm --name redshift_acc -p 5432:5432 -e TARGET_HOSTNAME=testcluster.cuzu3peepxrr.us-east-1.redshift.amazonaws.com -e TARGET_PORT=5439 -e USER=postgres -e PASS=SuperSecret123 dbaccelerator
```
What does the above command do? It starts a container named __redshift_acc__ using the image __dbaccelerator__. We open port 5432 on the docker host and map it to pgpool's port 5432 inside the container via __-p 5432:5432__. We pass the hostname of the cluster we want to connect to by assigning the hostname to the __TARGET_HOSTNAME__ environment variable. By assigning 5439 to __TARGET_PORT__ we tell the container that we want PgPool to use that specific port to connect to our MPP cluster. We also pass the database user and password in the __USER__ and __PASS__ variables respectively.

### Redshift Example:
Start the container using the variables for the Redshift cluster
```sh
docker run -it --rm --name redshift_acc -p 5432:5432 -e TARGET_HOSTNAME=testcluster.cuzu3peepxrr.us-east-1.redshift.amazonaws.com -e TARGET_PORT=5439 -e USER=postgres -e PASS=SuperSecret123 dbaccelerator
```
Now we just need to connect with __psql__ to the container we deployed. In my case it's running on __localhost__. We'll also turn timing to see the difference in execution query times.
```sh
$ psql -h localhost -p 5432 -U postgres -d test 
Password for user postgres: 
psql (10.3, server 8.0.2)
Type "help" for help.

test=# select version();
                                                         version                                                          
--------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 8.0.2 on i686-pc-linux-gnu, compiled by GCC gcc (GCC) 3.4.2 20041017 (Red Hat 3.4.2-6.fc3), Redshift 1.0.1885
(1 row)

test=# \timing
Timing is on.
test=# select count(*) from fact join dim on (fact.id = dim.id);
  count   
----------
 33554432
(1 row)

Time: 11706.863 ms (00:11.707)
test=# select count(*) from fact join dim on (fact.id = dim.id);
  count   
----------
 33554432
(1 row)

Time: 3.718 ms
test=# 

```

The first run of the query took over 11 seconds. The second run hit the cache and returned in a little over 3ms. That's a performance gain of __3000x__. As if MPP systems were not fast enough already...  

When a query hits the result cache, you'll see the following message in the PgPool log indicating that the query was pulled from the cache and didn't have to run on the database again.
```
2018-03-25 17:25:01 DEBUG: pid 12: pool_fetch_from_memory_cache: a query result found in the query cache, select count(*) from fact join dim on (fact.id = dim.id);
2018-03-25 17:25:01 DEBUG: pid 12: pool_set_skip_reading_from_backends: done
```
### Greenplum Example:
Start the container using the variables for the Greenplum cluster
```sh
docker run -it --rm --name greenplum_acc -p 5433:5432 -e TARGET_HOSTNAME=192.168.1.14 -e TARGET_PORT=5432 -e USER=gpadmin -e PASS=greenplum dbaccelerator
```
Since I had Greenplum running locally in a container exposed on port 5432 on the host, I had to use a different port i.e. 5433 for the PgPool container. 
```
$ psql -h localhost -d test -U gpadmin -p 5433
Password for user gpadmin: 
psql (10.3, server 8.3.23)
Type "help" for help.

test=# select version();
                                                                                      version                                                                                       
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 8.3.23 (Greenplum Database 5.5.0 build dev) on x86_64-pc-linux-gnu, compiled by GCC gcc (GCC) 6.3.1 20170216 (Red Hat 6.3.1-3), 64-bit compiled on Mar 25 2018 18:12:17
(1 row)

test=# \timing
Timing is on.
test=# select count(*) from fact join dim on (fact.id = dim.id);
  count   
----------
 33554432
(1 row)

Time: 24953.976 ms (00:24.954)
test=# select count(*) from fact join dim on (fact.id = dim.id);
  count   
----------
 33554432
(1 row)

Time: 4.212 ms
test=# 
```
These results are from running on my local machine. One again we see that the first time we run the query it takes a while, over 24 seconds. The second time we run the query we get the result from cache and it comes back in 4ms. That's almost 6000x faster. Not bad.

## Conclusion
In general the slower the hardware and the longer the queries take the more benefit can be realized by using the caching capabilities of PgPool. The container can also be extended to work with Postgres-XL.
