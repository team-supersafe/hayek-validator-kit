---
description: How to build Solana CLI for Localnet
---

# Build CLI for Localnet

For [Localnet](solana-localnet.md), which is focused on development and operator workloads, we want to **avoid** having to BUILD FROM SOURCE every time we spin up a new docker container, since the build process itself is very resource intensive and slows down the development REPL. For this reason, all Localnet deployments are done from pre-compiled binaries.&#x20;

Anza publishes new releases of Agave at [https://github.com/anza-xyz/agave/releases](https://github.com/anza-xyz/agave/releases). However, they **don't** publish pre-built binaries for Apple Silicon running virtualized hosts, which is not an uncommon setup for developer workstations.

To accomodate these developers and operators, we pre-compile binaries for Apple Silicon and store them in an accessible place so Docker and Ansible can use them in their Localnet.

## Storage Setup

We'll use an AWS S3 bucket and IAM user for storing the Solana CLI binaries.&#x20;

### Create S3 Bucket

Go to your AWS account and create an S3 bucket. We named ours `solv-store` . We'll use this bucket to upload and download our binaries.&#x20;

### IAM Credentials Setup

To securely create AWS credentials for uploading files to your S3 bucket, do need to setup a policy, a user, credentials and link them together, like this:&#x20;

1.  Create an IAM Policy with Least Privilege Define a policy that grants access only to the specific S3 bucket and the required actions. The policy shown below allows uploading (PutObject) and downloading (GetObject) files to/from the bucket, which is what we need:

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:GetObject"
          ],
          "Resource": "arn:aws:s3:::solv-store/*"
        }
      ]
    }
    ```
2.  To create an IAM User, run the following command from your workstation:

    ```bash
    aws iam create-user \
      --user-name solv-s3-uploader \
      --region us-east-1 \
      --profile supersafe-root
    ```
3.  Attach the IAM Policy to the IAM User&#x20;

    ```bash
    aws iam put-user-policy \
      --user-name solv-s3-uploader \
      --policy-name SolVS3UploadPolicy \
      --policy-document file://./solv-s3-upload-policy.json \
      --region us-east-1 \
      --profile supersafe-root
    ```
4.  Generate access keys for the IAM user. These will be used to authenticate uploads.

    ```bash
    aws iam create-access-key \
      --user-name solv-s3-uploader \
      --region us-east-1 \
      --profile supersafe-root
    ```

    **NOTE**: Save the AccessKeyId and SecretAccessKey securely. We recommend using a well established password manager like 1Password or Keeper for this.
5.  Set the credentials as environment variables in your local workstation&#x20;

    ```bash
    export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXX
    export AWS_ACCESS_KEY_SECRET=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    export AWS_REGION=us-east-1
    ```

## Build & Upload

Finally, we have setup a script named `run-build-in-container.sh` that:

1. Downloads the source for the Solana CLI for a specific `version`
2. Builds the source in the container
3. Compresses the built binaries
4. Uploads the compressed binaries to the bucket we created earlier

To run this script, make sure your [Localnet is running](solana-localnet.md#running-localnet) and you are [connected to your Ansible Control](ansible-control.md#connect-to-ac), then...

### Using 1Password

If you are user 1Password as your password manager, you have the great security option of installing the 1Password CLI to manage access to your credentials. This is the recommended way to store and access credentials, and the guide to install the CLI is [HERE](https://developer.1password.com/docs/cli/get-started/).

```bash
# Navigate to the script dir
cd solana-local-cluster/build-solana-cli


# Set credentials for script
export SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID="op://Solana Validator/Hayek Validator Solana Local Cluster/SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID"
export SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY="op://Solana Validator/Hayek Validator Solana Local Cluster/SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY"

# Run script with the 1Password CLI op run command
op run -- ./run-build-in-container.sh 2.1.21
```

### Not Using 1Password

If you are NOT using 1Password because you are using another password manager... okay:&#x20;

```bash
# Navigate to the script dir
cd solana-local-cluster/build-solana-cli

# Set credentials for script
export SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID="<COPY_FROM_1PASSWORD>"
export SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY="<COPY_FROM_1PASSWORD>"

# Run script
./run-build-in-container.sh 2.1.21
```

### Download URL

After a the scrip runs, the new build will be uploaded to the S3 bucket and available to download at this address and accessible to you. For example, the build binaries for Agave 2.1.21 live here:

* [https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download/v2.1.21/solana-release-aarch64-unknown-linux-gnu.tar.gz](https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download/v2.1.21/solana-release-aarch64-unknown-linux-gnu.tar.gz).&#x20;

If the binaries for this version already exist in the S3 bucket, the script will exit without changes.

Note that the binaries are not downloaded into any particular Localnet node. Instead, they are ready to be downloaded and installed into any node we want in the cluster without needing to build-from-source every time.

## Extras

### Compress / Decompress

See [https://www.cyberciti.biz/faq/ubuntu-howto-compress-files-using-tar/](https://www.cyberciti.biz/faq/ubuntu-howto-compress-files-using-tar/)

```bash
# Extract from archive, Verbose, use gZip, archive Filename
tar -xvzf "v${SOLANA_RELEASE}.tar.gz"

# Compress new archive, Verbose, use gZip, Preserve permissions, archive Filename, 
# -Change to directory dir, . archive everything in the current directory
tar -cvzpf 2.1.17.tar.gz \
  -C .local/share/solana/install/releases/2.1.17/ \
  .

# Compress new archive, Verbose, j: use bzip2, Preserve permissions, archive Filename, 
# -Change to directory dir, . archive everything in the current directory
tar -cvjpf v2.1.17_aarch64-unknown-linux-gnu.tar.bz2 \
  -C .local/share/solana/install/releases/2.1.17/ \
  .
```
