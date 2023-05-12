package azure.nonprod.mq

# Validate that the storage class is managed-csi
deny[msg] {
    input.kind = "QueueManager"
    not input.spec.queueManager.storage.queueManager.class = "managed-csi"
    msg = "Storageclass should be managed-csi"
}

# Validate that the license is correct 
deny[msg] {
    input.kind = "QueueManager"
    not input.spec.license.license = "L-RJON-CD3JKX"
    msg = "License should be L-RJON-CD3JKX"
}