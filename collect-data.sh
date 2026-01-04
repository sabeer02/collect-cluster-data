#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="k8s_cluster_backup_${TIMESTAMP}"

# Create output directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    mkdir -p "${OUTPUT_DIR}"/{cluster-info,namespaces,helm,events,resources,secrets,configs,images}
    
    for ns in "${NAMESPACES[@]}"; do
        mkdir -p "${OUTPUT_DIR}/namespaces/${ns}"/{pods,services,deployments,statefulsets,daemonsets,configmaps,secrets,pvcs,logs}
    done
}

# Collect cluster-wide information
collect_cluster_info() {
    log_info "Collecting cluster information..."
    
    kubectl cluster-info > "${OUTPUT_DIR}/cluster-info/cluster-info.txt" 2>&1 || true
    kubectl version > "${OUTPUT_DIR}/cluster-info/version.txt" 2>&1 || true
    kubectl get nodes -o wide > "${OUTPUT_DIR}/cluster-info/nodes.txt" 2>&1 || true
    kubectl get nodes -o yaml > "${OUTPUT_DIR}/cluster-info/nodes.yaml" 2>&1 || true
    kubectl top nodes > "${OUTPUT_DIR}/cluster-info/nodes-usage.txt" 2>&1 || true
    kubectl get componentstatuses > "${OUTPUT_DIR}/cluster-info/component-status.txt" 2>&1 || true
    kubectl api-resources > "${OUTPUT_DIR}/cluster-info/api-resources.txt" 2>&1 || true
    kubectl get apiservices > "${OUTPUT_DIR}/cluster-info/api-services.txt" 2>&1 || true
}

# Collect events (alarms)
collect_events() {
    log_info "Collecting events/alarms..."
    
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' > "${OUTPUT_DIR}/events/all-events.txt" 2>&1 || true
    kubectl get events --all-namespaces -o yaml > "${OUTPUT_DIR}/events/all-events.yaml" 2>&1 || true
    
    kubectl get events --all-namespaces --field-selector type=Warning > "${OUTPUT_DIR}/events/warning-events.txt" 2>&1 || true
    
    for ns in "${NAMESPACES[@]}"; do
        kubectl get events -n "$ns" --sort-by='.lastTimestamp' > "${OUTPUT_DIR}/events/events-${ns}.txt" 2>&1 || true
    done
}

# Collect all resources
collect_resources() {
    log_info "Collecting all resources..."
    
    # Get all resources across all namespaces
    kubectl get all --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-resources.txt" 2>&1 || true
    
    # Specific resource types
    kubectl get pods --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-pods.txt" 2>&1 || true
    kubectl get services --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-services.txt" 2>&1 || true
    kubectl get deployments --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-deployments.txt" 2>&1 || true
    kubectl get statefulsets --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-statefulsets.txt" 2>&1 || true
    kubectl get daemonsets --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-daemonsets.txt" 2>&1 || true
    kubectl get jobs --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-jobs.txt" 2>&1 || true
    kubectl get cronjobs --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-cronjobs.txt" 2>&1 || true
    kubectl get ingresses --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-ingresses.txt" 2>&1 || true
    kubectl get networkpolicies --all-namespaces -o wide > "${OUTPUT_DIR}/resources/all-networkpolicies.txt" 2>&1 || true
    
    # Storage resources
    kubectl get pv -o wide > "${OUTPUT_DIR}/resources/persistent-volumes.txt" 2>&1 || true
    kubectl get pv -o yaml > "${OUTPUT_DIR}/resources/persistent-volumes.yaml" 2>&1 || true
    kubectl get pvc --all-namespaces -o wide > "${OUTPUT_DIR}/resources/persistent-volume-claims.txt" 2>&1 || true
    kubectl get storageclasses -o wide > "${OUTPUT_DIR}/resources/storage-classes.txt" 2>&1 || true
    
    # RBAC resources
    kubectl get clusterroles -o yaml > "${OUTPUT_DIR}/resources/cluster-roles.yaml" 2>&1 || true
    kubectl get clusterrolebindings -o yaml > "${OUTPUT_DIR}/resources/cluster-role-bindings.yaml" 2>&1 || true
    kubectl get serviceaccounts --all-namespaces -o yaml > "${OUTPUT_DIR}/resources/service-accounts.yaml" 2>&1 || true
    
    # Resource quotas and limits
    kubectl get resourcequotas --all-namespaces -o yaml > "${OUTPUT_DIR}/resources/resource-quotas.yaml" 2>&1 || true
    kubectl get limitranges --all-namespaces -o yaml > "${OUTPUT_DIR}/resources/limit-ranges.yaml" 2>&1 || true
    
    # Top resources (usage)
    kubectl top pods --all-namespaces > "${OUTPUT_DIR}/resources/pods-usage.txt" 2>&1 || true
}

# Collect namespace-specific data
collect_namespace_data() {
    log_info "Collecting namespace-specific data..."
    
    for ns in "${NAMESPACES[@]}"; do
        log_info "Processing namespace: $ns"
        
        # Pods
        kubectl get pods -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/pods/pods.yaml" 2>&1 || true
        kubectl get pods -n "$ns" -o wide > "${OUTPUT_DIR}/namespaces/${ns}/pods/pods.txt" 2>&1 || true
        
        # Pod descriptions
        for pod in $(kubectl get pods -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
            kubectl describe pod "$pod" -n "$ns" > "${OUTPUT_DIR}/namespaces/${ns}/pods/${pod}-describe.txt" 2>&1 || true
        done
        
        # Services
        kubectl get services -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/services/services.yaml" 2>&1 || true
        
        # Deployments
        kubectl get deployments -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/deployments/deployments.yaml" 2>&1 || true
        
        # StatefulSets
        kubectl get statefulsets -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/statefulsets/statefulsets.yaml" 2>&1 || true
        
        # DaemonSets
        kubectl get daemonsets -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/daemonsets/daemonsets.yaml" 2>&1 || true
        
        # ConfigMaps
        kubectl get configmaps -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/configmaps/configmaps.yaml" 2>&1 || true
        
        # PVCs
        kubectl get pvc -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/pvcs/pvcs.yaml" 2>&1 || true
    done
}

# Collect secrets (be careful with this!)
collect_secrets() {
    log_warn "Collecting secrets (SENSITIVE DATA)..."
    
    for ns in "${NAMESPACES[@]}"; do
        kubectl get secrets -n "$ns" -o yaml > "${OUTPUT_DIR}/namespaces/${ns}/secrets/secrets.yaml" 2>&1 || true
        
        # Also collect in encrypted format if needed
        kubectl get secrets -n "$ns" > "${OUTPUT_DIR}/namespaces/${ns}/secrets/secrets-list.txt" 2>&1 || true
    done
}

# Collect Helm charts
collect_helm_charts() {
    log_info "Collecting Helm charts..."
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_warn "Helm not found, skipping Helm collection"
        return
    fi
    
    # List all releases
    helm list --all-namespaces > "${OUTPUT_DIR}/helm/releases.txt" 2>&1 || true
    helm list --all-namespaces -o yaml > "${OUTPUT_DIR}/helm/releases.yaml" 2>&1 || true
    
    # Get details for each release
    for ns in "${NAMESPACES[@]}"; do
        releases=$(helm list -n "$ns" -q 2>/dev/null || true)
        if [ -n "$releases" ]; then
            mkdir -p "${OUTPUT_DIR}/helm/${ns}"
            for release in $releases; do
                log_info "Collecting Helm release: $release in namespace $ns"
                helm get all "$release" -n "$ns" > "${OUTPUT_DIR}/helm/${ns}/${release}-all.yaml" 2>&1 || true
                helm get values "$release" -n "$ns" > "${OUTPUT_DIR}/helm/${ns}/${release}-values.yaml" 2>&1 || true
                helm get manifest "$release" -n "$ns" > "${OUTPUT_DIR}/helm/${ns}/${release}-manifest.yaml" 2>&1 || true
                helm get notes "$release" -n "$ns" > "${OUTPUT_DIR}/helm/${ns}/${release}-notes.txt" 2>&1 || true
                helm history "$release" -n "$ns" > "${OUTPUT_DIR}/helm/${ns}/${release}-history.txt" 2>&1 || true
            done
        fi
    done
}

# Collect Docker images used
collect_docker_images() {
    log_info "Collecting Docker images information..."
    
    # Get all images from pods
    kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}' > "${OUTPUT_DIR}/images/pod-images.txt" 2>&1 || true
    
    # Get unique images
    kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u > "${OUTPUT_DIR}/images/unique-images.txt" 2>&1 || true
    
    # Get images with their pull policies
    kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{range .spec.containers[*]}{.image}{" ("}{.imagePullPolicy}{")"}{"\t"}{end}{"\n"}{end}' > "${OUTPUT_DIR}/images/images-with-policy.txt" 2>&1 || true
    
    # Get init container images
    kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.initContainers[*].image}{"\n"}{end}' | grep -v "^[[:space:]]*$" > "${OUTPUT_DIR}/images/init-container-images.txt" 2>&1 || true
}

# Collect pod logs
collect_pod_logs() {
    log_info "Collecting pod logs..."
    
    for ns in "${NAMESPACES[@]}"; do
        pods=$(kubectl get pods -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
        
        for pod in $pods; do
            log_info "Collecting logs for pod: $pod in namespace: $ns"
            
            # Current logs
            kubectl logs "$pod" -n "$ns" --timestamps --all-containers=true > "${OUTPUT_DIR}/namespaces/${ns}/logs/${pod}-current.log" 2>&1 || true
            
            # Previous logs (if pod restarted)
            kubectl logs "$pod" -n "$ns" --previous --timestamps --all-containers=true > "${OUTPUT_DIR}/namespaces/${ns}/logs/${pod}-previous.log" 2>&1 || true
            
            # For multi-container pods, get individual container logs
            containers=$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null || true)
            if [ -n "$containers" ]; then
                for container in $containers; do
                    kubectl logs "$pod" -n "$ns" -c "$container" --timestamps > "${OUTPUT_DIR}/namespaces/${ns}/logs/${pod}-${container}.log" 2>&1 || true
                    kubectl logs "$pod" -n "$ns" -c "$container" --previous --timestamps > "${OUTPUT_DIR}/namespaces/${ns}/logs/${pod}-${container}-previous.log" 2>&1 || true
                done
            fi
        done
    done
}

# Collect ConfigMaps
collect_configmaps() {
    log_info "Collecting ConfigMaps..."
    
    kubectl get configmaps --all-namespaces -o yaml > "${OUTPUT_DIR}/configs/all-configmaps.yaml" 2>&1 || true
}

# Main collection summary
create_summary() {
    log_info "Creating collection summary..."
    
    cat > "${OUTPUT_DIR}/COLLECTION_SUMMARY.txt" << EOF
Kubernetes Cluster Data Collection Summary
==========================================
Collection Date: $(date)
Cluster: $(kubectl config current-context)
Output Directory: ${OUTPUT_DIR}

Collected Data:
- Cluster information (nodes, version, components)
- Events and alarms across all namespaces
- All Kubernetes resources (pods, deployments, services, etc.)
- Resource usage statistics
- Helm charts and releases
- Docker images inventory
- Pod logs (current and previous)
- ConfigMaps and Secrets
- RBAC configurations
- Storage resources (PV, PVC, StorageClasses)
- Network policies and ingresses

Total Size: $(du -sh "${OUTPUT_DIR}" | cut -f1)

Next Steps:
- Add custom log collection commands at the end of this script
- Add database dump commands at the end of this script
EOF
}

# Compress the backup
compress_backup() {
    log_info "Compressing backup..."
    tar -czf "${OUTPUT_DIR}.tar.gz" "${OUTPUT_DIR}"
    log_info "Compressed backup created: ${OUTPUT_DIR}.tar.gz"
    log_info "Original directory size: $(du -sh "${OUTPUT_DIR}" | cut -f1)"
    log_info "Compressed size: $(du -sh "${OUTPUT_DIR}.tar.gz" | cut -f1)"
}

###############################################################################
# Main execution
###############################################################################

main() {
    echo "=========================================="
    echo "Kubernetes Cluster Data Collection Script"
    echo "=========================================="
    echo ""
    
    # Check kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        exit 1
    fi
    
    log_info "Current context: $(kubectl config current-context)"
    log_info "Output directory: ${OUTPUT_DIR}"
    echo ""
    
    read -p "Enter namespace (default: default): " TARGET_NAMESPACES
    TARGET_NAMESPACES=${TARGET_NAMESPACES:-default}
    read -ra NAMESPACES <<< "$TARGET_NAMESPACES"
    log_info "Collecting data from specified namespaces: ${NAMESPACES[*]}"
    
    create_directory_structure
    collect_cluster_info
    collect_events
    collect_resources
    collect_namespace_data
    collect_secrets
    collect_helm_charts
    collect_docker_images
    collect_pod_logs
    collect_configmaps
    create_summary
    
    ###########################################################################
    # ADD YOUR CUSTOM COLLECTION COMMANDS BELOW THIS LINE
    ###########################################################################
    
    log_info "=========================================="
    log_info "ADD YOUR CUSTOM COMMANDS BELOW:"
    log_info "=========================================="

    mkdir -p "${OUTPUT_DIR}"/custom-logs
    ###########################################################################
    python3 --version > "${OUTPUT_DIR}"/custom-logs/py-version.txt 2>/dev/null || true
    java --version > "${OUTPUT_DIR}"/custom-logs/java-version.txt 2>/dev/null || true
    kubectl version > "${OUTPUT_DIR}"/custom-logs/kubectl-version.txt 2>/dev/null || true
    helm version > "${OUTPUT_DIR}"/custom-logs/helm-version.txt 2>/dev/null || true
    git version > "${OUTPUT_DIR}"/custom-logs/git-version.txt 2>/dev/null || true
    who -b > "${OUTPUT_DIR}"/custom-logs/last-reboot.txt 2>/dev/null || true
    whoami > "${OUTPUT_DIR}"/custom-logs/user.txt 2>/dev/null || true
    df -h > "${OUTPUT_DIR}"/custom-logs/resource-usage.txt 2>/dev/null || true
    ###########################################################################
    # END CUSTOM COMMANDS SECTION
    ###########################################################################
    
    #Comment this line, if you dont want to create tar file
    compress_backup
    #Comment this line, if you want to create only tar file
    rm -rf ${OUTPUT_DIR}
    
    echo ""
    log_info "=========================================="
    log_info "Collection completed successfully!"
    log_info "=========================================="
    log_info "Backup location: ${OUTPUT_DIR}.tar.gz"
    log_info "Summary: ${OUTPUT_DIR}/COLLECTION_SUMMARY.txt"
}

# Run main function
main "$@"