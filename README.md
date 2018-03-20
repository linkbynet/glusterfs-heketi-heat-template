# GlusterFS + Heketi openstack heat template

This repository contains a Heat template for 4 nova instances :

- 3 glusterfs instances
- 1 heketi instance

## Stack installation

### Configuration

The configuration template is [glusterfs_parameters.yaml]

Here is some informations for some parameters :

- domain_name: dns suffix for all nova instance name

- gluster_cidr: glusterfs internal cidr, used by heketi for the management of glusterfs instances

- external_network: the external networks which provides floating IP

- brick_volume_size: size in Gb of each brick. The gluster will be a replica of three bricks of this size, which will made this size as the total volume size.

- use_existing_subnet_for_fixed_subnet: When set to true, you need to define existing_fixed_network_id and existing_fixed_subnet_id. This allow to put the glusterfs storage interface on an Openshift-on-openstack external subnet.

- allowed_gluster_ssh_prefixes: list of allowed cidr to glusterfs instances ssh via floating IP
- allowed_heketi_ssh_prefixes: idem for heketi instance
- allowed_heketi_api_prefixes: idem for heketi api

- heketi_user_password and heketi_admin_password : user and admin account password for heketi API

- allowed_gluster_clients_security_groups: list of allowed security groups to access the glusterfs service. For example with openshift-on-openstack it should be master_security_group and node_security_group ids

- gluster_server_group_policies: set to [] if you need to disable anti-affinity during tests

### Stack create

To create the stack :

```
openstack stack create \
  -t glusterfs.yaml \
  -e glusterfs_parameters.yaml \
  --timeout 120 \
  my_stack_name
```

Check the stack create events :
```
openstack stack event list my_stack_name --nested-depth 10 --follow
```


## Usage on openshift-on-openstack

First, create the storageclass on Openshift :

heketi-storageclass.yaml :
```
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: heketi-glusterfs
  metadata:
    annotations:
      storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://10.0.1.21:8080"
  restuser: "user"
  restuserkey: "My Secret"
```

```
oc create -f heketi-storageclass.yaml
storageclass "heketi-glusterfs" created
```

To test it, create a PersistentVolumeClaim :

heketi-glusterfs-pvc.yaml :
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: gluster-dyn-pvc
spec:
 accessModes:
  - ReadWriteMany
 resources:
   requests:
        storage: 1Gi
 storageClassName: heketi-glusterfs
```

```
oc create -f heketi-glusterfs-pvc.yaml
persistentvolumeclaim "gluster-dyn-pvc" created
```

Check after a few seconds, it should be Bound :
```
oc get pvc/gluster-dyn-pvc
NAME              STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS       AGE
gluster-dyn-pvc   Bound     pvc-d408e666-2c22-11e8-8bf0-fa163ed07dbb   1Gi        RWX           heketi-glusterfs   11s
```

Then create a test Pod :

pvc-test-pod.yaml
```
kind: Pod
apiVersion: v1
metadata:
  name: pvc-test-pod
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: mypv
  volumes:
    - name: mypv
      persistentVolumeClaim:
        claimName: gluster-dyn-pvc
```

```
oc create -f pvc-test-pod.yaml
pod "pvc-test-pod" created
```

```
oc describe pods/pvc-test-pod
...
Normal          SuccessfulMountVolume   MountVolume.SetUp succeeded for volume "pvc-2e2b7de6-2929-11e8-83cf-fa163e4773e4"
```

Check the volume in the pod :

```
oc rsh pvc-test-pod df -h /var/www/html
Filesystem                                      Size  Used Avail Use% Mounted on
10.0.1.10:vol_a8103f592747e664474e06a76e8aa043 1016M   33M  983M   4% /var/www/html
```

Clean test pod and PVC :
```
oc delete pods/pvc-test-pod 
oc delete pvc/gluster-dyn-pvc
```
