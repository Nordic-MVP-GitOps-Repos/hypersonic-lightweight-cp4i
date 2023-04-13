package azure.nonprod.mq

# Validate that the storage class is managed-premium
deny[msg] {
    input.kind = "QueueManager"
    not input.spec.queueManager.storage.queueManager.class = "managed-premium"
    msg = "Storageclass should be managed-premium"
}

# Validate that the license is correct 
deny[msg] {
    input.kind = "QueueManager"
    not input.spec.license.license = "L-RJON-CD3JKX"
    msg = "License should be L-RJON-CD3JKX"
}