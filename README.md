# Complexity vs Size vs Security

> Container size is not a vanity metric. It is an indicator of container quality.

The terms *slim*, *minify* and *optimize* are used interchangeably to describe
the act of reducing the size of a container image 🤏

## Why should I slim container images?

  * Only ship into production what your app requires.
  * Slim container images are faster to deploy (lower size) and faster to start (fewer files).
  * Slim container images can be less expensive to store and transfer.
  * Slim containers reduce your attack surface.
    * [What We Discovered Analyzing the Top 100 Public Container Images](https://www.slim.ai/blog/container-report-2021.html) shows an increasing trend of dev/test/qa/infra tooling being left in production containers.
    * Leaving shells, interpreters, tools and utilities in your container images can be used against your infrastructure to disrupt operations if a container is compromised.

## Objectives

We'll be *using science* 🧑‍🔬 to determine the best approach to containerize an app,
with a focus on:

- Developer momentum ⚡
- Low complexity 👶
- Optimized size 🤏
- Reduced attack surface 🔒
  - This is more than vulnerability count

We'll be using:

- [Slim.AI Docker Desktop Extension](https://hub.docker.com/r/slimdotai/dd-ext)
- [DockerSlim](https://github.com/docker-slim/docker-slim)
- [Syft](https://github.com/anchore/syft)
- [Trivy](https://github.com/aquasecurity/trivy)

## Container construction

Here's a very simple Python/Flask app 🐍 that implements an even simpler RESTful
API. The app is just for illustrative purposes, it's function is unimportant. As
it happens, the app is the same one we used when we last appeared on Cloud
Native Live presenting [Building, Analyzing, Optimizing, and Securing Containerized Apps](https://www.youtube.com/watch?v=FI0v-L0WWN0).

- [`app.py`](app/app.py)

The app has been containerized using several different base images:

- [python:3.9-slim-bullseye](Dockerfile.python) (129MB)
- [python:3.9-alpine3.15](Dockerfile.alpine) (58MB)
- [ubuntu:20.04](Dockerfile.focal) (73MB) - *No Python included*
- [ubuntu:22.04](Dockerfile.jammy) (78MB) - *No Python included*
- [gcr.io/distroless/python3](Dockerfile.distroless) (54MB) *Multi-stage build*

On Ubuntu 22.04 release day we used the [Slim.AI Developer Platform](https://slim.ai)
to analyze why 22.04 is 5MB larger than 20.04. That video is available here 📺

 - [SlimDevOpsLive 40 - Ubuntu containers 22.04 vs 20.04: What you need to know! 🔍](https://www.youtube.com/watch?v=ppla5mnrSNI)

## Dockerfile complexity

Here's a review of each of the Dockerfiles, which follow best practice (mostly)
and are a simple as possible for ease of maintenance.

- **python**
  - Simple `Dockerfile`
  - Adheres to best practice
- **alpine**
  - The simplest `Dockerfile`
  - No `USER`.
    - It is possible with extra steps.
- **focal/jammy**
  - Simple `Dockerfile` if you're familiar with Ubuntu.
    - Some `apt` knowledge required.
  - Adheres to best practice.
- **focal-norec/jammy-norec**
  - Simple `Dockerfile` if you're familiar with Ubuntu.
    - More `apt` knowledge required to create a smaller image.
  - Adheres to best practice.
- **distroless**
  - Somewhat complex [multi-stage `Dockerfile`](https://docs.docker.com/develop/develop-images/multistage-build/)
  - Requires knowledge of Python to create the production container
  - No `USER`.
    - It is possible with extra steps

## Container Size & Summary

Containers are built like so:

```bash
docker build -f Dockerfile.python -t app:python .
```

And can be run like this:

```bash
docker run -it --rm -p 8008:8008 app:python
```

The [Slim.AI Docker Desktop Extension](https://hub.docker.com/r/slimdotai/dd-ext)
can:

- Get summary information
- Explore container images, layer construction and file contents
- Compare (diff) container images
- ...and more

| Base         | Tag         | Size (fat) |
| ------------ | ----------- | ---------- |
| Debian 11    | python      | 139MB      |
| Ubuntu 20.04 | focal       | 411MB      |
| Ubuntu 22.04 | jammy       | 435MB      |
| Ubuntu 20.04 | focal-norec | 120MB      |
| Ubuntu 22.04 | jammy-norec | 136MB      |
| **Alpine 3.15**  | alpine      | 62MB       |
| Distroless   | distroless  | 71MB       |

- Alpine is a clear winner when we consider image size alone.
  - Great for Go and Rust.
  - Python can result in slower builds and introduce runtime bugs.
    - Read <https://pythonspeed.com/articles/alpine-docker-python/> for all the details.
- By using [Slim.AI Docker Desktop Extension](https://hub.docker.com/r/slimdotai/dd-ext)
  it is possible to **determine that the Distroless container image is based on
  Debian 11 and Python 3.9**, this is important to know when working with
  Distroless for a couple of reasons I'll highlight later.
- Good use of `apt` can significantly reduce Ubuntu image sizes, even when
  compared to the Official Python slim image built with Debian.

## Packages Analysis

```bash
syft --file syft-python.txt app:python
```

`syft` reports that 11 Python packages are installed in each of the container
images. Which is expected, as `pip` should be deterministic.

| Base         | Tag         | Size (fat) | Distro Packages | Python Packages |
| ------------ | ----------- | ---------- | --------------- | --------------- |
| Debian 11    | python      | 139MB      | 105             | 11              |
| Ubuntu 20.04 | focal       | 411MB      | 205             | 11              |
| Ubuntu 22.04 | jammy       | 435MB      | 232             | 11              |
| Ubuntu 20.04 | focal-norec | 120MB      | 115             | 11              |
| Ubuntu 22.04 | jammy-norec | 136MB      | 122             | 11              |
| Alpine 3.15  | alpine      | 61.5MB     | 36              | 11              |
| **Distroless**   | distroless  | 71.4MB     | 34              | 11              |

Distroless was previously identified as being based on Debian 11. If fewer
packages correlate to fewer vulnerabilities we should expect to see a better
security profile of Distroless when compared to the `python:3.9-slim-bullseye`
and perhaps also the Ubuntu based images.

Let's find out.

## Vulnerability Analysis

```bash
trivy image app:python
```

`trivy` reports there are no known vulnerabilities in the Python packages
installed via `pip`. Therefore the vulnerabilities highlighted below are from
the `.deb` or `.apk` packages provided by the *"distro*".

| Base         | Tag         | Size (fat) | Vulnerabilities | Critical | High | Medium | Low |
| ------------ | ----------- | ---------- | --------------- | -------- | ---- | ------ | --- |
| Debian 11    | python      | 139MB      | 85              | 2        | 15 ! | 2      | 66  |
| Ubuntu 20.04 | focal       | 411MB      | 140             | 0        | 1    | 56     | 83  |
| Ubuntu 22.04 | jammy       | 435MB      | 104             | 0        | 0    | 38     | 66  |
| Ubuntu 20.04 | focal-norec | 120MB      | 28              | 0        | 0    | 7      | 21  |
| Ubuntu 22.04 | jammy-norec | 136MB      | 22              | 0        | 0    | 7      | 15  |
| **Alpine 3.15**  | alpine      | 61.5MB     | 0               | 0        | 0    | 0      | 0   |
| Distroless   | distroless  | 71.4MB     | 46              | 3 !      | 7    | 4      | 32  |

Oh!

There is no denying the Alpine results are excellent.

Distroless has among the worst vulnerability assessment of the containers tested,
with 3 critical vulnerabilities compared to just 2 critical vulnerabilities in
`python:3.9-slim-bullseye` (which is also built from Debian 11) based container
with ~3 times the package count. But the `python:3.9-slim-bullseye` had 15 High
vulnerabilities versus 7 in Distroless.

All the Ubuntu based containers, even the *"full fat"* ones, have good results
with 0 critical vulnerabilities and [upon further investigation that High vulnerability (CVE-2022-1015)
for the Ubuntu 20.04 based image was a false positive](https://ubuntu.com/security/notices/USN-5390-1),
something that and [`grype`](https://github.com/anchore/grype) and
[`snyk`](https://snyk.io/lp/docker-security-snyk/) both confirmed.

When using `--no-recommends` the Ubuntu based containers have 0 Critical or High
vulnerabilities, and significantly outperforms the Debian 11 based containers.
Why is this? Ubuntu is derived from Debian, right?

Ubuntu is a commercially backed Linux distro with a full time security team that
have [SLAs to mitigate vulnerabilities for their customers](https://ubuntu.com/legal/ubuntu-advantage-service-description)
which includes mitigating all Critical and High vulnerabilities for the
supported lifetime of the distro.

Debian is a community project, and while many of the contributors (including
myself) do fix security issues in Debian, it is simply can not provide the same
level of commitment to security as the commercially backed Linux distro vendors
such as Canonical, RedHat and SUSE do.

- What if I could have the low complexity of maintaining Ubuntu based containers
and the security profile of Alpine?
- What if I can make containers smaller than Alpine?

Let's try that.

## Optimization & Minification

```bash
docker-slim build --tag app:python-slim app:python
```

| Base         | Tag         | Size (fat) | Size (slim) | Reduction |
| ------------ | ----------- | ---------- | ----------- | --------- |
| Debian 11    | python      | 139MB      | 23MB        | 5.95X     |
| Ubuntu 20.04 | focal       | 411MB      | 24MB        | 17.4X     |
| Ubuntu 22.04 | jammy       | 435MB      | 26MB        | 17.0X     |
| Ubuntu 20.04 | focal-norec | 120MB      | 24MB        | 5.06X     |
| Ubuntu 22.04 | jammy-norec | 136MB      | 26MB        | 5.35X     |
| Alpine 3.15  | alpine      | 62MB       | 20MB        | 3.13X     |
| Distroless   | distroless  | 71MB       | 23MB        | 3.05X     |

In many cases there significant size reductions to had when using [Slim.AI](https://slim.ai)
or [DockerSlim](https://github.com/docker-slim/docker-slim).

Did slimming the container images remove vulnerabilities?

### MEDIUM vulnerabilities

Let's look at the `jammy-norec-slim` image, which we've already confirmed is
free of CRITICAL and HIGH vulnerabilities.

```
┌───────────────────────┬────────────────┬──────────┬───────────────────────┬──────────────────────────┬──────────────────────────────────────────────────────────────┐
│        Library        │ Vulnerability  │ Severity │   Installed Version   │          Notes           │                            Title                             │
├───────────────────────┼────────────────┼──────────┼───────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────┤
│ e2fsprogs             │ CVE-2022-1304  │ MEDIUM   │ 1.46.5-2ubuntu1       │ Search: e2f*             │ e2fsprogs: out-of-bounds read/write via crafted filesystem   │
│                       │                │          │                       │                          │ https://avd.aquasec.com/nvd/cve-2022-1304                    │
├───────────────────────┤                │          │                       ├──────────────────────────┤                                                              │
│ libcom-err2           │                │          │                       │ Search: libcom*          │                                                              │
│                       │                │          │                       │                          │                                                              │
├───────────────────────┤                │          │                       ├──────────────────────────┤                                                              │
│ libext2fs2            │                │          │                       │ Search: libext*          │                                                              │
│                       │                │          │                       │                          │                                                              │
├───────────────────────┼────────────────┼──────────┼───────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────┤
│ libsqlite3-0          │ CVE-2020-9794  │ MEDIUM   │ 3.37.2-2              │ Search: libsql*          │ An out-of-bounds read was addressed with improved bounds     │
│                       │                │          │                       │                          │ checking. This issue is...                                   │
│                       │                │          │                       │ Also removes 2x LOW      │ https://avd.aquasec.com/nvd/cve-2020-9794                    │
├───────────────────────┼────────────────┼──────────┼───────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────┤
│ libss2                │ CVE-2022-1304  │ MEDIUM   │ 1.46.5-2ubuntu1       │ Search: libss*           │ e2fsprogs: out-of-bounds read/write via crafted filesystem   │
│                       │                │          │                       │                          │ https://avd.aquasec.com/nvd/cve-2022-1304                    │
├───────────────────────┼────────────────┼──────────┼───────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────┤
│ logsave               │ CVE-2022-1304  │ MEDIUM   │ 1.46.5-2ubuntu1       │ Search: log*             │ e2fsprogs: out-of-bounds read/write via crafted filesystem   │
│                       │                │          │                       │                          │ https://avd.aquasec.com/nvd/cve-2022-1304                    │
├───────────────────────┼────────────────┼──────────┼───────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────┤
│ perl-base             │ CVE-2020-16156 │ MEDIUM   │ 5.34.0-3ubuntu1       │ Search: *perl*           │ perl-CPAN: Bypass of verification of signatures in CHECKSUMS │
│                       │                │          │                       │                          │ files                                                        │
│                       │                │          │                       │                          │ https://avd.aquasec.com/nvd/cve-2020-16156                   │
└───────────────────────┴────────────────┴──────────┴───────────────────────┴──────────────────────────┴──────────────────────────────────────────────────────────────┘
```

All the MEDIUM risk vulnerabilities are indeed removed by [Slim.AI](https://slim.ai)
or [DockerSlim](https://github.com/docker-slim/docker-slim) when optimizing the
container image.

## LOW vulnerabilities

The app uses Python, and there are indeed some LOW risk vulnerabilities related
to Python. We'll use the

```
┌───────────────────────┬────────────────┬──────────┬───────────────────────┬──────────────────────────┬──────────────────────────────────────────────────────────────┐
│        Library        │ Vulnerability  │ Severity │   Installed Version   │          Notes           │                            Title                             │
├───────────────────────┼────────────────┼──────────┼───────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────┤
│ libpython3.10-minimal │ CVE-2015-20107 │ LOW      │ 3.10.4-3              │ Search: *mailcap*        │ python(mailcap): findmatch() function does not sanitise the  │
│                       │                │          │                       │                          │ second argument                                              │
│                       │                │          │                       │                          │ https://avd.aquasec.com/nvd/cve-2015-20107                   │
├───────────────────────┤                │          │                       ├──────────────────────────┤                                                              │
│ libpython3.10-stdlib  │                │          │                       │ Search: *mailcap*        │                                                              │
│                       │                │          │                       │                          │                                                              │
│                       │                │          │                       │                          │                                                              │
├───────────────────────┼────────────────┼──────────┼───────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────────────┤
│ python3.10            │ CVE-2015-20107 │ LOW      │ 3.10.4-3              │ Search: *mailcap*        │ python(mailcap): findmatch() function does not sanitise the  │
│                       │                │          │                       │                          │ second argument                                              │
│                       │                │          │                       │                          │ https://avd.aquasec.com/nvd/cve-2015-20107                   │
├───────────────────────┤                │          │                       ├──────────────────────────┤                                                              │
│ python3.10-minimal    │                │          │                       │ Search: *mailcap*        │                                                              │
│                       │                │          │                       │                          │                                                              │
│                       │                │          │                       │                          │                                                              │
└───────────────────────┴────────────────┴──────────┴───────────────────────┴──────────────────────────┴──────────────────────────────────────────────────────────────┘
```

In fact all the remaining LOW risk vulnerabilities
(CVE-2016-2781, CVE-2021-43618, CVE-2019-20838, CVE-2017-11164, CVE-2013-4235, CVE-2019-9923)
were also completely removed by optimizing the container with [Slim.AI](https://slim.ai)
or [DockerSlim](https://github.com/docker-slim/docker-slim).

It was trivial to verify this using the [Slim.AI Docker Desktop Extension](https://hub.docker.com/r/slimdotai/dd-ext)
in just a couple of minutes.

So yes! We can have our cake and eat it too 🍰

**NOTE!** It is also worth noting that the HIGH risk vulnerability CVE-2021-3999
that exists in `glibc` remains in both the `python:3.9-slim-bullseye` and
Distroless containers. Unlike Ubuntu where it has already been mitigated and
Alpine where is never existed by virtue of Alpine using `musl`.

# Conclusions

Firstly, I am not suggesting that you should never use Alpine or Distroless. If
you're working with Go or Rust then they are both good choices, particularly
`gcr.io/distroless/static-debian11`

To recap:

- Slimming container images is a vital process in the software supply chain story.
  - Reduce attack surface.
  - Deployment momentum.
  - Start up performance.
  - No changes to your existing container build processes.
- Vulnerability scanners can produce false positives.
  - Trivial to inspect container images to verify if vulnerable components are present
- Alpine is small and secure.
  - Low complexity `Dockerfile`
  - High complexity considerations with regards to language ecosystems and performance/compatibility impact.
- Debian != Ubuntu with regards to security profile.

## Outcome

I work in a team familiar with Ubuntu. Therefore, we can trade the slight
increase in `Dockerfile` complexity and gain:

 - A `Dockerfile` that adheres to best practice.
 - DevX of using a familiar and well documented platform (Ubuntu).
 - No runtime/build performance or compatibility considerations that create friction.
 - A container image free of CRITICAL and HIGH risk vulnerabilities.

By adding [Slim.AI](https://slim.ai) or [DockerSlim](https://github.com/docker-slim/docker-slim)
into the CI/CD pipeline we also gain:

 - A container image entirely free of known vulnerabilities.
 - A container image 3x smaller than an Apline image
   - Or just 6MB larger than a slimmed Apline image.
 - Faster container deployment velocity.
 - Faster container start up performance.
 - And perhaps for a CNCF Live in the future... 😉
   - Automatically generated AppArmor and seccomp profiles 🔒

Caring about container image size demonstrates that you care about the quality
of the containers you deploy into production. Introducing slimming into your
container production workflow can considerably reduce image complexity and
attack surface while maintaining development velocity and adhering to best
practice.
