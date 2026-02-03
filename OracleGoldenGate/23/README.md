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
| `OPATCH_ZIP` | No | OPatch ZIP to replace the bundled OPatch |
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
• `OPATCH_ZIP` is optional  
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

## Licensing and Disclaimer

Oracle GoldenGate is a licensed Oracle product.

This repository provides build automation only.  
You are responsible for complying with Oracle licensing and support policies.

This is **not an official Oracle repository**. 
Oficial repo is here: https://github.com/oracle/docker-images/tree/main/OracleGoldenGate/23#build-an-oracle-goldengate-container-image

---

## Summary

This repository extends the official Oracle GoldenGate container build by:

• Enabling RU and one-off patch application  
• Preserving Oracle’s runtime-only container model  
• Producing smaller, cleaner production images  
• Keeping builds explicit, reproducible, and transparent  

If you understand why multi-stage builds matter, this repository should be straightforward to use.
