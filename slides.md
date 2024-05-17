---
author: "denis shatokhin"
date: ""
paging: "slide[%d]"
theme: ./slides-style.json
---

# Implementing Your Own Controller with Gateway API

```plain


 ██████╗  █████╗ ████████╗███████╗██╗    ██╗ █████╗ ██╗   ██╗
██╔════╝ ██╔══██╗╚══██╔══╝██╔════╝██║    ██║██╔══██╗╚██╗ ██╔╝
██║  ███╗███████║   ██║   █████╗  ██║ █╗ ██║███████║ ╚████╔╝
██║   ██║██╔══██║   ██║   ██╔══╝  ██║███╗██║██╔══██║  ╚██╔╝
╚██████╔╝██║  ██║   ██║   ███████╗╚███╔███╔╝██║  ██║   ██║
 ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝

                     █████╗ ██████╗ ██╗
                    ██╔══██╗██╔══██╗██║
                    ███████║██████╔╝██║
                    ██╔══██║██╔═══╝ ██║
                    ██║  ██║██║     ██║
                    ╚═╝  ╚═╝╚═╝     ╚═╝
```

---

# Denis Shatokhin

- Devops Engineer (System Administrator)
- Work at Relex Solutions
- Live in Helsinki for 1.5 years

---

# The scope of the presentation

- Differences between Ingress and Gateway APIs
  - Current state of both APIs
- Homemade 'gateway-controller'
  - How it works
  - Envoy
  - PKL
- Demo
- Links
- Questions

---

# Disclaimer

- this is not a `production ready` solution
- built for the sake of learning things

---

# Differences between Ingress and Gateway APIs

|                        | Ingress          | Gateway                                         |
| ---------------------- | ---------------- | ----------------------------------------------- |
| Protocol support       | HTTP/HTTPS       | L4/L7 support                                   |
| Traffic management     | Limited          | Built-in advanced support                       |
| Portability            | Vendor specifics | Common standard                                 |
| Resource objects       | `ingress`        | `gatewayClass`, `gateway`, `httpRoute` and more |
| Routing rules          | Path/host-based  | Path/host/header-based                          |
| Extending capabilities | Annotations      | Part of specification                           |

---

# Current state of both APIs

Ingress API (https://kubernetes.io/docs/concepts/services-networking/ingress):

> Ingress is frozen. New features are being added to the Gateway API.

Gateway API (https://gateway-api.sigs.k8s.io):

> This project represents the next generation of Kubernetes Ingress,
> Load Balancing, and Service Mesh APIs

The signal is clear – start moving to Gateway API now to migrate smoothly in the future

---

# Homemade 'gateway-controller'

Why not to build the custom controller and see how it works?

The first attempt was `bashgress` - ingress-controller written with `bash` and `jq`:

- https://gitlab.com/dshatokhin/bashgress

Main idea was to implement bare minimum functionality
without even building container images,
bash-codebase mounted to pod via `configmap`.

The configuration for proxy stored in `configmap` as well.

---

# How it works

The main component manually deployed to cluster is `bagapi-provisioner`:

- uses `kubectl` to get all `gateway` objects in cluster in `json` format
- uses `pkl` to parse `gateway.json` file and outputs `k8s` manifests for `controller` and `envoy`

The `controller` automaticaly deployed for every `gateway` object in cluster:

- uses `kubectl` to get all `HTTProute` objects in cluster in `json` format
- uses `pkl` to parse `httproutes.json` file and outputs `configmap` which `envoy` reading
- `envoy` reads mounted files contained in `configmap` and file-based xDS applies the changes

Also, the `service` with `type: Loadbalancer` created for every `gateway` object.

---

# Envoy

Build by LYFT, `v1.0.0` relesead back in 2016. From the official documentation:

> Envoy is an L7 proxy and communication bus designed for large modern service oriented architectures.
> The project was born out of the belief that:
> _The network should be transparent to applications._
> _When network and application problems do occur it_
> _should be easy to determine the source of the problem._

- L3/L4 - TCP/UDP, HTTP, TLS, custom protocols like `postgres`, `redis` etc
- HTTP L7 - buffering, rate limiting, routing/forwarding
- HTTP/1.1, HTTP/2, HTTP/3 support
- service discovery and dynamic configuration (xDS)
- really good observability
- could be extended via LUA or WASM
- written in `C++`

---

# Apple PKL

Build by Apple and open-sourced earlier this year:

`pronounced Pickle`

> Pkl — is an embeddable configuration language which provides rich support
> for data templating and validation. It can be used from the command line,
> integrated in a build pipeline, or embedded in a program. Pkl scales
> from small to large, simple to complex, ad-hoc to repetitive configuration tasks.

- turing complete
- written in `java`
- LSP support on the corner
- no Apple ID required to download and use it

---

# Demo

```plain


██████╗ ███████╗███╗   ███╗ ██████╗
██╔══██╗██╔════╝████╗ ████║██╔═══██╗
██║  ██║█████╗  ██╔████╔██║██║   ██║
██║  ██║██╔══╝  ██║╚██╔╝██║██║   ██║
██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝
╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝
```

---

# People who I want to thanks

- Maryam - for encouraging me to talk
- Kim - for giving me a day off to finish the presentation

---

# Links

- This repo (including slides)
  > https://gitlab.com/dshatokhin/bagapi
- Envoy
  > https://www.envoyproxy.io
- Apple PKL
  > https://pkl-lang.org
- Envoy-gateway - envoy-based gateway-controller
  > https://gateway.envoyproxy.io
- List of gateway-controllers for Kubernetes
  > https://gateway-api.sigs.k8s.io/implementations

---

# Questions

```plain


 █████╗ ███╗   ██╗██╗   ██╗    ██████╗ ██████╗ ██████╗
██╔══██╗████╗  ██║╚██╗ ██╔╝    ╚════██╗╚════██╗╚════██╗
███████║██╔██╗ ██║ ╚████╔╝       ▄███╔╝  ▄███╔╝  ▄███╔╝
██╔══██║██║╚██╗██║  ╚██╔╝        ▀▀══╝   ▀▀══╝   ▀▀══╝
██║  ██║██║ ╚████║   ██║         ██╗     ██╗     ██╗
╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝         ╚═╝     ╚═╝     ╚═╝

```
