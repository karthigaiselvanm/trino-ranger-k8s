## Building Apache Ranger from source

As of this document (Aug 03, 2025), Apache Ranger still doesn't provide tar ball file to deploy so we need to build it ourselves. This guide will help do exactly the same,

Prerequisites:

* Java 8
* Maven

### 1. Check out the code from GIT repository

```bash
git clone https://gitbox.apache.org/repos/asf/ranger.git
cd ranger
```

Alternatively, you can checkout the code from github:

```bash
git clone https://github.com/apache/ranger
cd ranger
```

### 2. Ensure you have set JAVA_HOME and execute the following maven commands

```bash
export JAVA_HOME=%jdk 7 Home%
mvn -Pall clean 
mvn -Pall -DskipTests=false clean compile package install # if you want to skip tests, set -DskipTests=true
```

If the build is successful, you will see the below BUILD SUCCESS message

![ranger-admin-tar](../src/images/ranger-admin-tar.png)

### 3. Apache Ranger Admin tar ball and other plugins

Once the build is success, all the required tar balls can be found under *target/* directory

![ranger-tar-balls](../src/images/ranger-tar-balls.png)

There are two server side components:
### 1. 🛡️ Apache Ranger Admin
Purpose: UI-based central security policy administration

✅ What it does:⚙️ Optional but Recommended
Ranger Admin is mandatory to manage policies.

Ranger UserSync is optional but recommended for production deployments using LDAP or Active Directory.
Policy Management: Provides a web UI and REST APIs for administrators to define fine-grained access control policies for various data sources (like Hive, Trino, HDFS, Kafka, etc.).

Audit Logs: Stores and displays audit trails (who accessed what, when, and whether it was allowed or denied).

Plugins Communication: Pushes policies to Ranger plugins running within data source services (like Trino or Hive).

Database Backing: Stores all policies and metadata in a backend database (like MySQL/PostgreSQL).

🔗 Example:
You log into the Ranger Admin UI at http://<ranger-host>:608⚙️ Optional but Recommended
Ranger Admin is mandatory to manage policies.

Ranger UserSync is optional but recommended for production deployments using LDAP or Active Directory.0 and define:

A policy allowing user alice to run SELECT queries on the sales schema in Trino.

### 2. 👥 Apache Ranger UserSync
Purpose: Keeps Ranger Admin in sync with your organization’s identity system

✅ What it does:
Fetches users and groups from external identity providers like:

LDAP/Active Directory

Unix local user system

Syncs identities into the Ranger Admin database so you can build access control policies based on real users and groups.

Runs as a background daemon process.

🔗 Why it matters:
Without UserSync, you would have to manually create users and groups in Ranger Admin — not scalable or secure.

🔄 How They Work Together

```text
+---------------------+        REST/API        +-----------------------+
| External LDAP/AD    |----------------------->| Ranger UserSync       |
|                     |                        | (syncs users/groups)  |
+---------------------+                        +-----------------------+
                                                       |
                                                       v
                                                +--------------+
                                                | Ranger Admin |
                                                |  UI + DB     |
                                                +--------------+
                                                       |
                                       pushes policies  |
                                                       v
                                            +------------------+
                                            | Ranger Plugin     |
                                            | (Trino, Hive etc) |
                                            +------------------+

```

⚙️ Optional but Recommended
* Ranger Admin is mandatory to manage policies.
* Ranger UserSync is optional but recommended for production deployments using LDAP or Active Directory.

### 4. Creating docker image that integrates Apache Ranger with its required backend services *MySQL* as policy db and *Solr* as audit store.

 Lets unarchive the compiled *ranger-<version>-admin.tar.gz* package from *target/* directory to *ranger-docker/ranger-packages* using the below command

 ```bash
tar -xvzf ranger/target/ranger-3.0.0-SNAPSHOT-admin.tar.gz -C trino-ranger-k8s/ranger-docker/ranger-packages/
```

Once it is successfully unarchived the folder directory of *ranger-docker/* will look as below
```text
.
├── Dockerfile
├── install.properties
├── ranger-entrypoint.sh
├── ranger-packages
│   └── ranger-3.0.0-SNAPSHOT-admin
└── README.md
```

Lets dive into each file in details:

### 1. Dockerfile
Defines how the Apache Ranger Admin container is built.
It:

* Uses Ubuntu 20.04 as base
* Installs Java 11 and dependencies
* Copies the pre-built Ranger Admin distribution and MySQL connector
* Prepares for automated setup using install.properties and entrypoint script

### 2. install.properties
Configuration file used by Ranger’s setup.sh installer.
It contains:

* Database settings (e.g., MySQL host, username, password)
* Solr audit log endpoint
* Ranger service name and repository name
* Paths to JDBC drivers and Java home
* Optional settings like skipping UNIX group sync

### 3. ranger-entrypoint.sh
Startup script used inside the container.
It:

* Waits briefly for MySQL to become ready
* Runs Ranger's setup.sh to initialize the DB and configs
* Starts the Ranger Admin service
* Keeps the container running by tailing logs or sleeping indefinitely

### 4. ranger-packages/
Directory where the built Ranger Admin tarball is extracted (e.g., ranger-3.0.0-SNAPSHOT-admin/).
This folder is copied into the container by the Dockerfile.

![ranger-docker-struct](/src/images/ranger-docker-struct.png)

Execute the below command to create a docker image named *apache-ranger-admin:3.0.0* which then can be registered in ECR or in hub.docker.com

```bash
docker build -t apache-ranger-admin:3.0.0 .
```

![docker-ranger](/src/images/docker-ranger.png)