---
description: How to convert any image to WebP format
---

# Convert image to WebP

We only allow images in WebP format both for consistency and for performance optimization of the repository.&#x20;

WebP is a modern image format that offers superior lossless and lossy compression compared to traditional formats like PNG or JPEG, resulting in smaller file sizes and faster loading times.&#x20;

That means: No JPEGs, PNGs, GIFs, etc.

## Convert to WebP

There are many free tools to convert any JPEG and PNGs into WebP format. Here's one for MacOS:

```bash
# Install webp
brew install webp

# Convert PNG/JPEG to WebP
# Add quality (values 0–100). Start with zero and increase until desired quality.
cwebp -q 0 'input file name.png' -o 'output file name.webp'
```

If you are using Windows you can:

1. Re-evaluate what are you doing with your life
2. Bing how to convert whatever you have to WebP
