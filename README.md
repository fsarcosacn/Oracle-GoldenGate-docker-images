# Oracle GoldenGate 23 Docker Images (Extended Build with RU & One-Off Patches)

This repository provides Docker / Podman build files for **Oracle GoldenGate 23 Microservices Architecture**, based on the official Oracle container images, with **additional build-time capabilities**:

• Build an image from a specific **GoldenGate RU installer**  
• Optionally **replace the bundled OPatch**  
• Apply **one or more one-off patches** at build time  
• Produce a **small runtime-only image** using a **multi-stage build**

The final runtime image closely matches Oracle’s official GoldenGate images in layout and behavior, while allowing patching **during the image build** instead of at runtime.

---

## Supported Platforms

• Oracle Linux 8 / 9 
• Docker or Podman  
• OCI or Docker image format  

---

## Image Design Overview

The Dockerfile uses a **multi-stage build** to clearly separate **patching** from **runtime**.

### Stage 1 – Builder (temporary)

The builder stage performs all patching-related work:

• Installs GoldenGate using the provided RU installer  
• Optionally replaces the bundled OPatch  
• Applies one or more one-off patches using OPatch  
• Creates inventory and rollback metadata (required by OPatch)  
• Removes installer, OPatch, JDK, inventory, and rollback artifacts after patching  

This stage is **not published** and exists only during the build.

---

### Stage 2 – Runtime (final image)

The runtime stage:

• Starts from a clean `oraclelinux:8` base image  
• Copies only the final GoldenGate runtime files  
• Recreates the non-root `ogg` runtime user  
• Exposes GoldenGate Microservices endpoints  
• Produces a **small, runtime-only container image**

This matches Oracle’s official container lifecycle model:  
**patch by rebuilding the image, not by patching in place**.

---

## What the Final Image Contains

Included:

✔ GoldenGate runtime binaries  
✔ Microservices scripts and libraries  
✔ NGINX configuration  
✔ Non-root `ogg` runtime user  

Excluded:

✘ OPatch  
✘ `.patch_storage`  
✘ Oracle inventory  
✘ JDK  
✘ Installer artifacts  

---

## Repository Layout

```
OracleGoldenGate/23/
├── Dockerfile
├── install-prerequisites.sh
├── install-deployment.sh
├── install-patches.sh
├── apply-oneoff-opatch.sh
├── bin/
│   ├── deployment-main.sh
│   └── healthcheck
├── nginx/
│   └── nginx.conf
├── installers/
│   ├── OGGRU/
│   │   └── <GoldenGate RU installer zip>
│   ├── OPatch/
│   │   └── <optional OPatch zip>
│   └── OneOffPatches/
│       └── <one or more one-off patch zip files>
```

---

## Build Arguments

| Argument | Required | Description |
|--------|----------|-------------|
| `INSTALLER` | Yes | GoldenGate RU installer ZIP |
| `OPATCH_ZIP` | Conditional | OPatch ZIP to replace the bundled OPatch. **Required when `ONEOFF_PATCHES` is provided.** |
| `ONEOFF_PATCHES` | No | One or more one-off patch ZIP files |

---

## Build Command

The build command is **identical** whether or not patches are used.

Example:

```bash
podman build \
  -t ogg:23.8-runtime \
  --build-arg INSTALLER=installers/OGGRU/p37777817_23802504OGGRU_Linux-x86-64.zip \
  --build-arg OPATCH_ZIP=installers/OPatch/p6880880_230000_Linux-x86-64.zip \
  --build-arg ONEOFF_PATCHES=installers/OneOffPatches/p38859789_23802504OGGRU_Linux-x86-64.zip \
  .
```

Notes:

• `INSTALLER` is mandatory
• `OPATCH_ZIP` is optional when building with the RU only, but **required** when one-off patches are provided
• `ONEOFF_PATCHES` may point to a single ZIP or multiple ZIPs
• If optional arguments are not provided, the build completes using only the RU installer

---

## Runtime Configuration

The final image defines the following environment variables:

```
OGG_HOME=/u01/ogg
OGG_DEPLOYMENT_HOME=/u02
OGG_TEMPORARY_FILES=/u03
OGG_DEPLOYMENT_SCRIPTS=/u01/ogg/scripts
```

Exposed ports:

• `80` – HTTP  
• `443` – HTTPS  

Declared volumes:

• `/u02` – GoldenGate deployment data  
• `/u03` – Temporary files  

---

## Image Size Expectations

Typical results:

| Image Type | Size |
|----------|------|
Builder stage (temporary) | ~4.0-5.0 GB |
Final runtime image | ~2.0–3.0 GB |

The builder image is **not intended to be kept**.

---

## Cleaning Up Intermediate Images

After a successful build, you may see an untagged image:

```
<none> <none> <image-id>
```

This is the **builder stage** and can be safely removed:

```bash
podman image prune
```

---

## Patching Model and Supportability

• All patching is performed **at build time**  
• The runtime image does **not** contain OPatch  
• Rollback metadata is intentionally removed  
• Future patches require rebuilding the image  

This aligns with Oracle’s recommended container lifecycle.

---

## Upstream Reference

This repository is based on the official Oracle GoldenGate Docker images:

[https://github.com/oracle/docker-images/tree/main/OracleGoldenGate/23](https://github.com/oracle/docker-images/tree/main/OracleGoldenGate/23)

It extends the official build with additional patching capabilities and structural improvements, while preserving the same runtime layout and behaviour.

---

## Community Disclaimer

This repository is a **personal, community contribution** and is **not an official Oracle release or an officially supported method**.

It is shared openly in the hope that others find it useful.

- Use of this repository is entirely **at your own risk**
- No warranties, guarantees, or support commitments are made of any kind
- Issues and suggestions are welcome via GitHub Issues and will be considered on a **best-effort basis**
- This is a side project — response times and fixes cannot be guaranteed

Pull requests are welcome.

---

## Licensing and Usage Notes

All scripts, Dockerfiles, and build automation files provided in this repository are released under the **Universal Permissive License (UPL), Version 1.0**, unless otherwise noted.

This repository **does not contain Oracle GoldenGate binaries**.

To build or run Oracle GoldenGate, whether inside or outside a container, you must:

- Download the Oracle GoldenGate software separately from Oracle
- Accept the applicable Oracle Technology Network (OTN) license
- Ensure you comply with Oracle licensing and support policies

Oracle GoldenGate is a proprietary Oracle product.  
Use of this repository does **not** grant any rights to Oracle software.

This project is **not affiliated with, endorsed by, or supported by Oracle**.

---

## Summary

This repository extends the official Oracle GoldenGate container build by:

• Enabling RU and one-off patch application  
• Preserving Oracle’s runtime-only container model  
• Producing smaller, cleaner production images  
• Keeping builds explicit, reproducible, and transparent  

If you understand why multi-stage builds matter, this repository should be straightforward to use.
