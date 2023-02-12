# Notes


## Kubeconfig


```
export KUBECONFIG=/etc/kubernetes/admin.conf
```
or
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Networking

### CNI
This is actually a fairly complicated topic - one which I do not have much of an opinion or preference regarding at this point.  I am going to invest time in to Weaveworks as it is one of the supported options for [AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/alternate-cni-plugins.html)  

[WeaveWorks - Installing on EKS](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#-installing-on-eks)
