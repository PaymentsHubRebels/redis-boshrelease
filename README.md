# BOSH release for Redis

One of the fastest ways to get [redis](http://redis.io) running on any infrastructure is to deploy this bosh release. It can also be deployed to Kubernetes using Quarks/`cf-operator` and a Helm chart.

* [Concourse CI](https://ci-ohio.starkandwayne.com/teams/cfcommunity/pipelines/redis-boshrelease)
* Pull requests will be automatically tested against a bosh-lite (see `testflight-pr` job)
* Discussions and CI notifications at [#redis-boshrelease channel](https://cloudfoundry.slack.com/messages/C6Q802GTC/) on https://slack.cloudfoundry.org

Deploy Redis cluster with pre-compiled releases to a BOSH director:

```plain
bosh -d redis deploy \
    <(curl -L https://raw.githubusercontent.com/cloudfoundry-community/redis-boshrelease/master/manifests/redis.yml)
```

## BOSH usage

This repository includes base manifests and operator files. They can be used for initial deployments and subsequently used for updating your deployments.

To deploy a 2-node cluster:

```plain
export BOSH_ENVIRONMENT=<alias>
export BOSH_DEPLOYMENT=redis

git clone https://github.com/cloudfoundry-community/redis-boshrelease.git
bosh deploy redis-boshrelease/manifests/redis.yml
```

If your BOSH does not have Credhub/Config Server, then remember `--vars-store` to allow generation of passwords and certificates.

```plain
bosh deploy redis-boshrelease/manifests/redis.yml --vars-store creds.yml
```

If you have any errors about `Instance group 'redis' references an unknown vm type 'default'` or similar, there is a helper script to select a `vm_type` and `network` from your Cloud Config:

```plain
bosh deploy redis-boshrelease/manifests/redis.yml -o <(./manifests/operators/pick-from-cloud-config.sh)
```

### Sentinel

**This is not a cluster_enabled redis deployment.**

Redis Sentinel provides high availability for Redis. In this bosh release, you can include the redis-sentinel job to manage failover for 2 or more Redis instances in replication mode.
In order for sentinels to function correctly the initialisation of the cluster happens from an idempotent errand called `redis-bootstrap`. `redis-bootstrap` needs to run the first time the cluster gets initialised. On subsequent calls redis-bootstrap will enforce the master based on the will of `redis-sentinels`.

**Note: Set "bind_static_ip" to true using the redis-sentinel job.**

```plain
[...]
  instances: 3
  jobs:
[...]
  - name: redis
    release: redis
  - name: redis-sentinel
    release: redis
  properties:
    bind_static_ip: true
    password: ((redis_password)
```

### Update

When new versions of `redis-boshrelease` are released the `manifests/redis.yml` file will be updated. This means you can easily `git pull` and `bosh deploy` to upgrade.

```plain
export BOSH_ENVIRONMENT=<alias>
export BOSH_DEPLOYMENT=redis
cd redis-boshrelease
git pull
cd -
bosh deploy redis-boshrelease/manifests/redis.yml
```

### Development

To create/upload/deploy local changes to this BOSH release use the `create.yml` operator:

```plain
bosh -d redis deploy manifests/redis.yml -o manifests/operators/create.yml
```

### Errands

#### redis-bootstrap

This is the primary errand for sentinel installations (and not only). It allows the cluster to be setup initially. It is idempotent and its behaviour depends on the response of the sentinels.
If sentinels have elected a master `redis-bootstrap` errand will force that master to all redis instances that have not initialised yet (bootstrapped). Subsequent calls do nothing on already setup instances.
If there are no sentinels or the master has not been elected for any reason, the bootstrap redis instance takes the role.

##### Edge scenarios
1. More than one master
- stopping all sentinels and running `redis-bootstrap` will force the installation to switch to bootstrap redis instance. That will not guarantee that it is the preferable one but it will sort the issue faster than any other way
- run `SENTINEL FAILOVER <master name>` on existing sentinel master, which will force a failover as if the master was not reachable, and without asking for agreement to other Sentinels (however a new version of the configuration will be published so that the other Sentinels will update their configurations). Then running `redis-bootstrap` errand should fix the redis instances.

#### redis-chaos

`redis-chaos` collocated with redis/redis-sentinel jobs errand, covers a number of simulated failures:

- terminated instance (death)
- misconfiguration (ruin)
- redis service crash (segfault)
- unresponsive redis service (sleep)

Parameters controlling this errand:

  death_probability: Range of 0-100 declare if instance is killable where 0 is never and >=100 is certain. Default value 10.

  ruin_probability: Range of 0-100 declare if service should be ruined where 0 is never and >=100 is certain. Default value 0.

  segfault_probability: Range of 0-100 declare if service should crash where 0 is never and >=100 is certain. Default value 20. Affects only redis instances.

  sleep_probability: Range of 0-100 declare if service should sleep for a while where 0 is never and >=100 is certain. Default value 20. Affects only redis instances.

  affected_zone: Chaos script focuses on a specific zone if this property is set with the name of the zone.

