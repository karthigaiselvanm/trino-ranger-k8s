# Trino + Apache Ranger on Kubernetes

This project provides a Helm-based deployment of [Trino](https://trino.io/) integrated with [Apache Ranger](https://ranger.apache.org/) for centralized authorization, running on Kubernetes.

## 🔧 Features

- Trino coordinator deployed as a StatefulSet
- Apache Ranger integration for access control and auditing
- Solr-based audit logging
- MySQL-backed Ranger policy store
- Optional TPCH connector
- All configuration via Helm values

## 📌 Prerequisites

Before deploying, ensure you’ve built a custom Docker image of Apache Ranger with the required backend services like MySQL and Solr included.  
Follow this detailed guide:  
➡️ [Building Apache Ranger from Source and Creating Custom Docker Image](https://www.k2ddna.com/2025/08/building-apache-ranger-from-source.html)

## 📦 Repository Structure


```
.
├── ranger
│   ├── Chart.yaml
│   ├── files
│   │   ├── managed-schema.xml
│   │   └── solrconfig.xml
│   ├── templates
│   │   ├── mysql-configmap.yaml
│   │   ├── mysql-deployement.yaml
│   │   ├── mysql-service.yaml
│   │   ├── ranger-admin-deployment.yaml
│   │   ├── ranger-admin-service.yaml
│   │   ├── solr-configmap.yaml
│   │   ├── solr-deployment.yaml
│   │   └── solr-service.yaml
│   └── values.yaml
├── ranger-docker
│   ├── Dockerfile
│   ├── install.properties
│   └── ranger-entrypoint.sh
└── trino
    ├── Chart.yaml
    ├── templates
    │   ├── catalog-configmap.yaml
    │   ├── configmap.yaml
    │   ├── service.yaml
    │   └── StatefulSets.yaml
    └── values.yaml
```


---

## 🚀 Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/karthigaiselvanm/trino-ranger-k8s.git
cd trino-ranger-k8s
```

### 2. Install dependencies
Make sure you have the following:

* Kubernetes cluster (e.g., Minikube, kind, or EKS)
* Helm 3.x
* kubectl configured for your cluster

### 3. Deploy Ranger components

```bash
helm install ranger ./ranger --namespace ranger --create-namespace
```
![ranger-helm-install](/src/images/ranger-helm-install.png)

This sets up:

* Ranger Admin (ranger-admin)
* Ranger DB (ranger-mysql)
* Ranger Audit Logs (ranger-solr)

Wait until all pods are running:

```bash
kubectl get pods -n ranger
```

![ranger-pods](/src/images/ranger-pods.png)

Once all the three pods are in RUNNING status, you can verify the Ranger Admin Server pod logs as below

![ranger-admin-logs](/src/images/ranger-admin-server-logs.png)

You can also login to Apache Ranger Admin UI at *http://<ranger-admin-ip>:6080* . For example, I have port forwarded hence it is *http://localhost:6080*. The username and password are being set in the *install.properties*. Make sure, you made necessary changes if you are deploying it in a production environment.

![ranger-admin-ui](/src/images/ranger-admin-ui.png)

### 4. Deploy Trino with Helm
```bash
helm install trino ./trino --namespace ranger
```

![trino-helm-install](/src/images/trino-helm-install.png)

There will be a new pod *trino-coordinator-0* will spun up. In this development setup, I have set only one Trino Coordinator which will also work up as a Worker but feel free to make changes to the helm charts to include number of replicas for Trino workers.

![trino-pod](/src/images/trino-pod.png)

Once the pod is in RUNNING status, you will see the logs of the pod ending as shown below

![trino-pod-log](/src/images/trino-pod-log.png)

## 🔑 Ranger Access Control

Trino is configured to use Ranger only for access control. The following files are included in the deployment:

* access-control.properties
* ranger-trino-security.xml
* ranger-trino-audit.xml

Use the Ranger Admin UI (http://< ranger-admin-ip >:6080) to define Trino policies.

📁 Example Policy Types
* queryid → ExecuteQuery
* catalog, schema, table → select, update, etc.
* trinouser → impersonate

## 🔍 Audit Logging
Audit logs are sent to Ranger Solr.

Ensure this property is set in ranger-trino-audit.xml:
```xml
<property>
  <name>xasecure.audit.solr.solr_url</name>
  <value>http://ranger-solr:8983/solr/ranger_audits</value>
</property>
```

## 🧪 TPCH Connector (Optional)
To enable the TPCH connector, update your values.yaml:
```yaml
catalogs:
  tpch.properties: |
    connector.name=tpch
```

Trino will automatically pick up /etc/trino/catalog/tpch.properties.

Use the Ranger Admin UI (http://<ranger-admin-ip>:6080) to define Trino policies. Until you create a service for Trino, the integration is not complete.

Login to Apache Ranger Admin UI, under Service Manager click *+* for Trino as shown below

![ranger-service](/src/images/ranger-service.png)

In the next page, make sure you are giving the same service name as what is mentioned in the Trino's *Values.yaml* under *rangerServiceName* as shown below

![trino-service](/src/images/trino-service.png)

Once you have added the service for Trino in Ranger Admin UI, you will see the *trino-coodinator-0* will show the logs as below

![trino-coord](/src/images/trino-coord-logs.png)

You can test the integration, by querying the trino catalog by creating a connection in any of the DB querying tools such DBeaver/Beekeeper Studio. I am using DBeaver Community Edition.

![dbeaver-connect](/src/images/dbeaver-connection.png)

I am using *admin* as the user which is also used while creating the Trino Service in Ranger Admin UI which will be by default having all privileges

As you can see, I was able to access the test catalog *tpch* I have added in my helm chart as well as the system catalog.

![admin-access](/src/images/admin-access.png)

You can also check the audit events being captured in the Solr server we have setup as below. To access the audit events, navigate to *Audits* from the side bar and click *Access*

![audit-events](/src/images/audit-events.png)

Now lets edit, the username in the added connection with a different username, in our case *trinouser* then we will see the below error message because Ranger is blocking the mentioned user as it is not having *impersonate* access.

![trino-user-block](/src/images/trino-user-block.png)

The same will also reflect in the audit events page as shown below
![trinouser-audit-block](/src/images/trino-block-audit.png)

Lets fix the access by adding required access policies, Apache Ranger gives more fine-grained access control.

📁 Example Policy Types
* queryid → ExecuteQuery
* catalog, schema, table → select, update, etc.
* trinouser → impersonate

Since we are not using Ranger UserSync as it is a development environment, you can create an internal user for *trinouser* in the Ranger Admin UI and add *impersonate* access policy as well as required access policies for the required catalogs. Pleaser refer [Apache Ranger Policy Model](https://ranger.apache.org/blogs/policy_model.html) for more details on different access policies including the row level filer & column level masking.

![trino-access-policies](/src/images/trino-access-policies.png)

Once the policies are updated to give required access to the *trinouser*, you will be able to access the specific catalog which has been granted access.

![trino-access](/src/images/admin-access.png)

Same will also reflect in the Audit events as shown below

![trino-allow-audit](/src/images/trino-allow-audit.png)

## 📘 License
Apache 2.0 License

## ✍️ Blog Post
Detailed explanation soon at [k2ddna.com](https://www.k2ddna.com/2025/08/trino-apache-ranger-on-kubernetes.html)

## 🙌 Acknowledgements
* [Trino](https://trino.io/)
* [Apache Ranger](https://ranger.apache.org/)
* [Helm](https://helm.sh/)
* [Integrating Trino and Apache Ranger](https://medium.com/data-science/integrating-trino-and-apache-ranger-b808f6b96ad8)
* [Deploying Trino with Apache Ranger and Superset on Kubernetes](https://qnguyen3496.medium.com/deploying-trino-with-apache-ranger-and-superset-on-kubernetes-b85d834e5987)
