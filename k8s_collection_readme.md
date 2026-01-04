# Kubernetes Cluster Data Collection Script

## Overview

This bash script performs comprehensive data collection from a Kubernetes cluster for diagnostics, auditing, and troubleshooting purposes. It gathers cluster information, configurations, resource usage, logs, and other critical data in an organized directory structure.

## Features

### Collected Data

- **Cluster Information**: Nodes, Kubernetes version, cluster components, and configuration details
- **Events and Alarms**: Events and alerts across all namespaces for monitoring and troubleshooting
- **Kubernetes Resources**: Comprehensive inventory of pods, deployments, services, statefulsets, daemonsets, jobs, etc.
- **Resource Usage Statistics**: CPU, memory, and storage consumption metrics
- **Helm Charts and Releases**: All installed Helm releases and chart information
- **Docker Images Inventory**: Container images in use across the cluster
- **Pod Logs**: Current and previous pod logs for debugging
- **ConfigMaps and Secrets**: Configuration data and secrets (handled securely)
- **Storage Resources**: Persistent volumes, persistent volume claims, and storage classes
- **Custom Commands**: User-defined commands for specific requirements

## Prerequisites

- **kubectl**: Kubernetes command-line tool configured to access your cluster
- **bash**: Bash shell (v4.0 or higher)
- **Standard utilities**: `tar`, `gzip`, `du`, `mkdir`, `grep`, `awk`
- **Optional**: `helm` (if collecting Helm chart data)

## Usage

### Basic Execution

```bash
./k8s-data-collection.sh
```

### With Custom Namespace (Prompt)

The script will prompt you to enter a namespace. Press Enter to use the default namespace:

```
Enter namespace (default: default): 
```

### With Custom Namespace (Argument)

```bash
./k8s-data-collection.sh production
```

## Directory Structure

The script creates the following output directory structure:

```
k8s-cluster-data-<timestamp>/
├── cluster-info/
│   ├── nodes.txt
│   ├── version.txt
│   └── components.txt
├── events/
│   └── all-events.txt
├── resources/
│   ├── pods.txt
│   ├── deployments.txt
│   ├── services.txt
│   ├── statefulsets.txt
│   └── [other-resources].txt
├── namespace-data/
│   ├── namespace-1/
│   └── namespace-2/
├── secrets/
│   └── [encrypted-data].txt
├── helm-releases/
│   └── releases.txt
├── docker-images/
│   └── images-inventory.txt
├── pod-logs/
│   ├── namespace-1/
│   │   ├── pod-name/
│   │   │   ├── current.log
│   │   │   └── previous.log
│   │   └── [other-pods]/
│   └── namespace-2/
├── configmaps/
│   └── configmaps.txt
├── storage/
│   ├── persistent-volumes.txt
│   ├── persistent-volume-claims.txt
│   └── storage-classes.txt
├── custom-logs/
│   └── [user-defined-files]
└── summary.txt
```

## Configuration Options

### Output Compression

The script automatically creates a compressed tar.gz file of the collected data:

```bash
compress_backup
```

To disable compression, comment out this line:

```bash
# compress_backup
```

### Directory Cleanup

By default, the script removes the original directory after creating the tar.gz file:

```bash
rm -rf ${OUTPUT_DIR}
```

To keep the original directory, comment out this line:

```bash
# rm -rf ${OUTPUT_DIR}
```

To keep only the tar file without the directory, leave this line active.

## Custom Commands

You can add your own data collection commands in the designated custom section. The script provides a `custom-logs` directory for storing custom command outputs.

### Example Custom Commands

```bash
###########################################################################
# ADD YOUR CUSTOM COLLECTION COMMANDS BELOW THIS LINE
###########################################################################

# Collect Python version
python3 --version > "${OUTPUT_DIR}"/custom-logs/py-version.txt 2>/dev/null || true

# Collect custom metrics
kubectl top nodes > "${OUTPUT_DIR}"/custom-logs/node-metrics.txt 2>/dev/null || true

# Collect application-specific data
kubectl get custom-resource-name -A > "${OUTPUT_DIR}"/custom-logs/custom-resources.txt 2>/dev/null || true

# Run a custom diagnostic script
/path/to/custom-diagnostic.sh > "${OUTPUT_DIR}"/custom-logs/custom-diagnostic.txt 2>/dev/null || true

###########################################################################
```

## Main Functions

| Function | Purpose |
|----------|---------|
| `create_directory_structure()` | Creates the organized output directory layout |
| `collect_cluster_info()` | Gathers cluster information, nodes, and version details |
| `collect_events()` | Collects events and alarms across namespaces |
| `collect_resources()` | Gathers all Kubernetes resource definitions |
| `collect_namespace_data()` | Collects namespace-specific information |
| `collect_secrets()` | Handles ConfigMaps and secrets collection |
| `collect_helm_charts()` | Collects Helm release information |
| `collect_docker_images()` | Inventories Docker images in use |
| `collect_pod_logs()` | Gathers current and previous pod logs |
| `collect_configmaps()` | Collects ConfigMap data |
| `create_summary()` | Generates a summary report with total data size |
| `compress_backup()` | Creates a compressed tar.gz archive |

## Output Files

- **Directory Format**: `k8s-cluster-data-YYYYMMDD-HHMMSS/`
- **Compressed Format**: `k8s-cluster-data-YYYYMMDD-HHMMSS.tar.gz`
- **Summary File**: Contains overview and total data size

## Important Notes

### Security Considerations

- Secrets may contain sensitive information—handle with care
- Store the collected data in a secure location
- Consider encrypting the tar.gz file if storing sensitive cluster data
- Limit access to the collected data to authorized personnel only

### Performance Impact

- Large clusters with many pods may take significant time to collect logs
- Consider running during maintenance windows for large-scale data collection
- The script processes namespaces sequentially; parallel execution is available for optimization

### Log Limits

- Pod logs are collected with reasonable size limits to prevent excessive data collection
- Very chatty applications may generate large log files
- Previous logs are only collected if available

## Troubleshooting

### Permission Denied Errors

Ensure your kubectl configuration has appropriate cluster access:

```bash
kubectl auth can-i get pods --all-namespaces
```

### Out of Disk Space

Monitor available disk space before running the script:

```bash
df -h
```

### Missing kubectl

Install kubectl or add it to your PATH:

```bash
which kubectl
```

## Examples

### Basic Collection with Default Namespace

```bash
./k8s-data-collection.sh
# When prompted, press Enter to use 'default' namespace
```

### Collection for Production Namespace

```bash
./k8s-data-collection.sh production
```

### Collection with Custom Extensions

Edit the custom commands section and add your requirements, then run:

```bash
./k8s-data-collection.sh
```

### Archive Only (Keep Compressed File, Remove Directory)

```bash
# Run script as normal—it will compress and remove the directory by default
./k8s-data-collection.sh
```

### Keep Both Archive and Directory

Comment out the `rm -rf ${OUTPUT_DIR}` line, then run:

```bash
./k8s-data-collection.sh
```

## Support and Contributions

For issues, enhancements, or custom requirements:

1. Review the custom commands section for extensibility
2. Check kubectl documentation for resource-specific queries
3. Modify functions as needed for your cluster setup

---

**Script Version**: 1.0  
**Last Updated**: 2026  
**Maintainer**: DevOps/Platform Team