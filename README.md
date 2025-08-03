# Trino + Apache Ranger on Kubernetes

This project provides a Helm-based deployment of [Trino](https://trino.io/) integrated with [Apache Ranger](https://ranger.apache.org/) for centralized authorization, running on Kubernetes.

## 🔧 Features

- Trino coordinator deployed as a StatefulSet
- Apache Ranger integration for access control and auditing
- Solr-based audit logging
- MySQL-backed Ranger policy store
- Optional TPCH connector
- All configuration via Helm values

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

This sets up:

* Ranger Admin (ranger-admin)
* Ranger DB (ranger-mysql)
* Ranger Audit Logs (ranger-solr)

Wait until all pods are running:

```bash
kubectl get pods -n ranger
```

### 4. Deploy Trino with Helm
```bash
helm install trino ./trino --namespace ranger
```

## 🔑 Ranger Access Control

Trino is configured to use Ranger only for access control. The following files are included in the deployment:

* access-control.properties
* ranger-trino-security.xml
* ranger-trino-audit.xml

Use the Ranger Admin UI (http://<ranger-admin-ip>:6080) to define Trino policies.

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

## 📘 License
Apache 2.0 License

## ✍️ Blog Post
Detailed explanation coming soon at [k2ddna.com](https://www.k2ddna.com/)

## 🙌 Acknowledgements
* [Trino](https://trino.io/)
* [Apache Ranger](https://ranger.apache.org/)
* [Helm](https://helm.sh/)
* [Integrating Trino and Apache Ranger](https://medium.com/data-science/integrating-trino-and-apache-ranger-b808f6b96ad8)
* [Deploying Trino with Apache Ranger and Superset on Kubernetes](https://qnguyen3496.medium.com/deploying-trino-with-apache-ranger-and-superset-on-kubernetes-b85d834e5987)
