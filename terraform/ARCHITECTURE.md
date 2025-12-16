# Looply Architecture Documentation

## System Overview

Looply is a **cloud-native, event-driven video streaming platform** built on Google Cloud Platform (GCP). The architecture emphasizes **scalability**, **high availability**, and **cost-efficiency** through serverless components and intelligent traffic distribution.

## Component Interactions

### 1. **User Entry Point**
- Users access the platform via **global static IP**
- Traffic routed through **Google Cloud Load Balancer**
- SSL/TLS encryption enforced
- Automatic HTTP → HTTPS redirect

### 2. **Traffic Distribution**

#### API Requests → Cloud Run Services
```
User Request
    ↓
Global LB (HTTPS)
    ↓
URL Map Router
    ├─ /api/* → Cloud Run (stream processor, analytics, user mgmt)
    ├─ /health → Health check
    └─ /videos/* → Cloud Storage CDN
```

#### Video Content → Cloud CDN
```
Video Request
    ↓
Cloud CDN (Caching Layer)
    ├─ Cache Hit → Return cached content (fast)
    └─ Cache Miss → Fetch from GCS bucket → Cache → Return
```

### 3. **Compute Layer - Cloud Run (Multi-Region)**

#### Primary Region (us-central1)
- **Stream Processor**: Handles real-time video stream data
  - Receives stream quality metrics
  - Publishes to Pub/Sub for event distribution
  - Auto-scales 0-100 instances
  
- **Video Analytics**: Analyzes stream performance
  - Consumes stream quality events
  - Writes aggregated metrics to BigQuery
  - Updates user analytics
  
- **User Management**: Manages user profiles
  - CRUD operations via REST API
  - Stores user data in Firestore
  - Publishes user events to Pub/Sub

#### Secondary Region (europe-west1)
- **Stream Processor**: Read replica for DR
  - Subscribes to same Pub/Sub topics
  - Provides geographic redundancy
  - Enables failover capability

### 4. **Event-Driven Architecture - Cloud Pub/Sub**

#### Topic: `events` (Main Event Bus)
```
Stream Events:
├─ Play event (user_id, stream_id, timestamp)
├─ Pause event (user_id, stream_id, timestamp)
├─ Stop event (user_id, stream_id, duration_watched)
├─ Quality change (bitrate, latency, new_resolution)
└─ User action (follow, favorite, comment)

Push Subscriptions:
├─ events-sub-primary → Cloud Run (us-central1)
└─ events-sub-secondary → Cloud Run (europe-west1)
```

#### Topic: `video_processing`
```
Processing Tasks:
├─ Encode video (source_file, target_formats)
├─ Generate thumbnails (video_id, timestamps)
├─ Create transcripts (video_id, language)
└─ Upload to CDN (video_id, bucket_path)

Dead-Letter Queue:
└─ video_processing_dlq (failed messages after 5 retries)
```

#### Topic: `user_events`
```
User Actions:
├─ User login (user_id, timestamp, ip_address)
├─ User registration (user_id, email, region)
├─ Follow/Unfollow (user_id, target_user_id)
└─ Profile update (user_id, updated_fields)
```

#### Topic: `stream_quality`
```
Quality Metrics:
├─ Bitrate (current_bitrate_kbps, timestamp)
├─ Latency (latency_ms, region)
├─ Buffer duration (duration_ms, device_type)
└─ Packet loss (loss_percentage, network_type)
```

### 5. **Data Layer**

#### Firestore (Real-time NoSQL Database)
**Collections & Documents**:
```
/users/{user_id}
  ├─ username: string
  ├─ email: string
  ├─ created_at: timestamp
  ├─ profile_picture_url: string
  └─ preferences: {
      quality: "1080p"|"720p"|"480p"|"auto",
      language: string,
      notifications_enabled: boolean
    }

/streams/{stream_id}
  ├─ title: string
  ├─ description: string
  ├─ creator_id: string (ref to /users)
  ├─ created_at: timestamp
  ├─ video_url: string
  ├─ duration_seconds: integer
  ├─ view_count: integer
  └─ metadata: {
      resolution: "1080p"|"720p"|"480p",
      bitrate: integer,
      codec: "h264"|"h265"
    }

/sessions/{session_id}
  ├─ user_id: string (ref to /users)
  ├─ stream_id: string (ref to /streams)
  ├─ started_at: timestamp
  ├─ ended_at: timestamp
  ├─ watch_duration_seconds: integer
  ├─ device: string
  └─ ip_address: string

/comments/{comment_id}
  ├─ stream_id: string (ref to /streams)
  ├─ user_id: string (ref to /users)
  ├─ text: string
  ├─ created_at: timestamp
  └─ likes: integer
```

**Features**:
- Real-time synchronization with Cloud Run services
- Multi-region replication for disaster recovery
- Automatic backups
- Point-in-time recovery enabled

#### BigQuery (Analytics Data Warehouse)
**Dataset**: `looply_analytics`

**Table: stream_events** (Real-time event log)
```sql
CREATE TABLE stream_events (
  event_id STRING,              -- Unique event ID
  event_timestamp TIMESTAMP,     -- When event occurred
  user_id STRING,                -- User identifier
  stream_id STRING,              -- Stream identifier
  event_type STRING,             -- play, pause, stop, quality_change
  region STRING,                 -- Geographic region
  device_type STRING,            -- web, mobile, desktop
  bitrate INT64                  -- Stream bitrate (kbps)
)
PARTITION BY TIMESTAMP_TRUNC(event_timestamp, DAY)
```

**Table: user_analytics** (User metrics & aggregates)
```sql
CREATE TABLE user_analytics (
  user_id STRING,                -- User identifier
  total_watch_time INT64,        -- Seconds
  streams_watched INT64,         -- Count
  last_active TIMESTAMP,         -- Last activity
  preferred_quality STRING,      -- Preferred resolution
  average_bitrate FLOAT64        -- Average bitrate (kbps)
)
```

**Table: stream_quality** (Quality metrics)
```sql
CREATE TABLE stream_quality (
  quality_id STRING,             -- Unique ID
  timestamp TIMESTAMP,           -- Measurement time
  stream_id STRING,              -- Stream ID
  user_id STRING,                -- User ID
  region STRING,                 -- Region
  bitrate INT64,                 -- Current bitrate (kbps)
  latency_ms INT64,              -- Latency (ms)
  buffer_duration_ms INT64,      -- Buffer duration (ms)
  packet_loss_percent FLOAT64    -- Packet loss %
)
PARTITION BY TIMESTAMP_TRUNC(timestamp, DAY)
```

**Analytics Queries**:
```sql
-- Top streams by view count
SELECT stream_id, COUNT(*) as views
FROM stream_events
WHERE event_type = 'play'
GROUP BY stream_id
ORDER BY views DESC;

-- Average watch time per user
SELECT user_id, AVG(watch_duration_seconds) as avg_watch_time
FROM stream_events
GROUP BY user_id;

-- Quality issues by region
SELECT region, AVG(latency_ms) as avg_latency, AVG(packet_loss_percent) as avg_loss
FROM stream_quality
WHERE timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY region;
```

### 6. **Storage Layer - Cloud Storage**

#### Videos Bucket (`looply-videos-{project_id}`)
```
Structure:
/videos/
  ├─ {stream_id}/
  │   ├─ original.mp4          (1080p, high bitrate)
  │   ├─ adaptive-720p.mp4     (720p variant)
  │   ├─ adaptive-480p.mp4     (480p variant)
  │   ├─ adaptive-360p.mp4     (360p variant)
  │   └─ subtitles/
  │       ├─ en.vtt
  │       ├─ es.vtt
  │       └─ fr.vtt
  └─ {stream_id}/
      └─ thumbnails/
          ├─ thumb_00_00.jpg
          ├─ thumb_00_10.jpg
          └─ thumb_00_20.jpg

Configuration:
├─ Versioning: Enabled (keep 5 latest versions)
├─ CDN: Enabled
├─ CORS: Allowed (*domain)
└─ Lifecycle:
    ├─ Delete old versions (keep 5)
    └─ Archive to Coldline after 1 year
```

**CDN Caching Policy**:
- **Client TTL**: 1 hour (user-side cache)
- **Default TTL**: 1 hour (edge server cache)
- **Max TTL**: 24 hours (maximum cache time)
- **Negative Cache**: 404 responses cached 2 minutes

#### Analytics Bucket (`looply-analytics-{project_id}`)
```
Structure:
/daily/
  ├─ 2024-12-15/
  │   ├─ stream_events.parquet
  │   ├─ user_analytics.parquet
  │   └─ quality_metrics.parquet
  └─ 2024-12-16/
      ├─ stream_events.parquet
      └─ ...

Lifecycle: Delete after 90 days
```

#### Logs Bucket (`looply-logs-{project_id}`)
```
Structure:
/logs/
  ├─ cloud-run/
  │   ├─ stream-processor/
  │   │   ├─ 2024-12-15/
  │   │   └─ 2024-12-16/
  │   └─ video-analytics/
  │       └─ ...
  └─ cloud-logging/
      └─ ...

Lifecycle: Delete after 90 days (configurable)
```

#### Backup Bucket (`looply-backup-{project_id}`) [Multi-region]
```
Configuration:
├─ Location: US (multi-region)
├─ Versioning: Enabled
└─ Lifecycle:
    ├─ Nearline after 30 days
    └─ Coldline after 90 days
```

### 7. **Networking Architecture**

#### VPC Structure
```
VPC: looply-vpc (GLOBAL routing)
├─ Primary Region Subnets (us-central1)
│   ├─ Main Subnet: 10.0.0.0/20
│   │   └─ IP Range: 10.0.0.1 - 10.0.15.254
│   │   └─ Reserved for Cloud Run
│   └─ Proxy Subnet: 10.0.16.0/24
│       └─ For proxy services
│
└─ Secondary Region Subnets (europe-west1)
    ├─ Main Subnet: 10.1.0.0/20
    │   └─ IP Range: 10.1.0.1 - 10.1.15.254
    │   └─ Reserved for Cloud Run
    └─ Proxy Subnet: 10.1.16.0/24
        └─ For proxy services
```

#### Cloud NAT (Outbound Traffic)
```
Primary NAT (us-central1):
└─ Provides outbound IPv4 for private services
   ├─ Allows Cloud Run to call external APIs
   ├─ Hides internal IP addresses
   └─ Auto-scales based on traffic

Secondary NAT (europe-west1):
└─ Redundant NAT for secondary region
```

#### Firewall Rules
```
1. allow-internal
   └─ Protocol: TCP, UDP, ICMP
   └─ Ports: All (0-65535)
   └─ Source: Internal subnets
   └─ Purpose: Inter-service communication

2. allow-https
   └─ Protocol: TCP
   └─ Port: 443
   └─ Source: 0.0.0.0/0
   └─ Purpose: Global HTTPS access

3. allow-http
   └─ Protocol: TCP
   └─ Port: 80
   └─ Source: 0.0.0.0/0
   └─ Purpose: HTTP (redirected to HTTPS)

4. allow-health-checks
   └─ Protocol: TCP
   └─ Source: Google Cloud health check IPs
   └─ Purpose: Load balancer health checks
```

### 8. **Service Account Permissions Matrix**

| Service | Cloud Run | Pub/Sub | Firestore | BigQuery | Storage | Logs |
|---------|-----------|---------|-----------|----------|---------|------|
| **Cloud Run SA** | Execute | Publish/Subscribe | Read/Write | Read/Write | Read/Write | Write |
| **Pub/Sub SA** | - | Publish/Edit | - | - | - | Write |
| **Firestore SA** | - | - | Admin | - | - | Write |
| **BigQuery SA** | - | - | - | Admin | - | Write |
| **Storage SA** | - | - | - | - | Admin | Write |
| **Cloud Scheduler SA** | Invoke | - | - | - | - | - |
| **Artifact Registry SA** | - | - | - | - | - | - |

## Request Flow Example: User Watches Video

```
1. User clicks video link
   ↓
2. Request hits Global Load Balancer
   ↓
3. LB routes to Cloud CDN
   ↓
4. Cache HIT? 
   ├─ YES → Return cached video (fast, free egress)
   └─ NO → Fetch from GCS → Cache → Return
   ↓
5. Cloud Run stream processor receives metrics
   ↓
6. Publish to "events" topic: play_started
   ├─ stream_id: "stream_abc123"
   ├─ user_id: "user_xyz789"
   ├─ timestamp: "2024-12-16T10:30:00Z"
   └─ quality: "1080p"
   ↓
7. Push subscription invokes Cloud Run
   ├─ Primary region (us-central1)
   └─ Secondary region (europe-west1)
   ↓
8. Cloud Run updates metrics
   ├─ Firestore: User session data
   ├─ BigQuery: stream_events table (async)
   └─ Pub/Sub: Publish to "stream_quality" topic
   ↓
9. Video Analytics Cloud Run processes events
   ├─ Aggregates quality metrics
   ├─ Updates BigQuery user_analytics
   └─ Detects quality issues (high latency, packet loss)
   ↓
10. Video continues streaming
    ├─ Periodic quality reports via stream_quality topic
    ├─ Cloud Run adjusts bitrate if needed
    └─ Metrics collected for analytics
    ↓
11. User pauses video (30 minutes in)
    ├─ Publish event: pause_event
    ├─ Watch duration: 1800 seconds
    └─ Update Firestore session data
    ↓
12. Cloud Logging captures all operations
    ├─ Cloud Run logs
    ├─ Pub/Sub metrics
    └─ Request/response times
    ↓
13. Cloud Scheduler daily job (2 AM UTC)
    ├─ Triggers analytics aggregation
    ├─ Generates daily reports
    └─ Archives logs to backup bucket
```

## Disaster Recovery Strategy

### Multi-Region Failover
```
Primary Region Failure → Secondary Region Takeover

Firestore:
├─ Multi-region enabled
├─ Automatic replication
└─ Point-in-time recovery available

Cloud Run:
├─ Secondary region has full service copy
├─ Load balancer detects primary failure
└─ Routes traffic to secondary

Pub/Sub:
├─ Global topic (no failover needed)
└─ Both regions subscribe same topics

Cloud Storage:
├─ GCS is globally distributed
└─ Backup bucket (multi-region) for recovery
```

### Backup & Recovery
```
Daily Backups (Cloud Scheduler):
├─ 2 AM UTC: Trigger backup job
├─ Exports:
│   ├─ Firestore → Cloud Storage
│   ├─ BigQuery tables → Cloud Storage
│   └─ Application state → Backup bucket
└─ Retention: 30-90 days (configurable)

Recovery Procedure:
1. Detect outage
2. Verify secondary region health
3. Update DNS/LB configuration
4. If needed, restore from backup bucket
5. Validate data consistency
6. Resume operations
```

## Performance Characteristics

### Latency
```
User → LB: <10ms (global Anycast)
LB → Cloud Run: ~50-100ms (us-central1)
Cloud Run → Firestore: ~10-20ms
Cloud Run → BigQuery: ~100-200ms (async)
CDN Edge → Client: ~1-50ms (depends on location)
```

### Throughput
```
Cloud Run: Auto-scales 0-100+ instances
├─ Each instance: 1000 rps capability
├─ Total capacity: 100,000+ rps

Pub/Sub:
├─ Push subscriptions: 1,000 msgs/sec per subscription
├─ Multiple topics: 10,000+ msg/sec total

BigQuery:
├─ Streaming inserts: 1,000,000 rows/sec
├─ Batch loads: Unlimited (regional limits apply)

Cloud Storage:
├─ 1,000 writes/sec per bucket/second
├─ CDN: Unlimited read throughput
```

### Scalability
```
Vertical Scaling:
├─ Cloud Run: Configurable CPU (0.5-4 vCPU) & Memory (128Mi-8Gi)
└─ Each instance auto-scales based on requests

Horizontal Scaling:
├─ Cloud Run: 0-100+ concurrent instances (configurable)
├─ Pub/Sub: Automatic consumer scaling
├─ Firestore: Auto-scales reads/writes
└─ BigQuery: Compute scaling (slots)
```

## Cost Optimization

### Cloud Run Costs
```
Pay for:
├─ Invocations: $0.40 per million
├─ vCPU-seconds: $0.0000417/second (2vCPU instance)
└─ Memory-GB-seconds: $0.0000083/second (512Mi = 0.5GB)

Example monthly (100k daily users):
├─ 100,000 invocations/day × 30 days = 3M invocations = $1.20
├─ Average 100ms execution time = 0.1s × vCPU cost
└─ Estimated: $50-200/month
```

### Cloud Storage Costs
```
Standard tier:
├─ Write: $0.020 per 10,000 requests
├─ Read: $0.0004 per 10,000 requests
└─ Storage: $0.020/GB/month

Lifecycle optimization:
├─ Coldline (1 year+): $0.004/GB/month (80% savings)
└─ Archive (long-term): $0.0012/GB/month (94% savings)
```

### BigQuery Costs
```
On-Demand:
├─ Query: $6.25 per TB scanned
├─ Storage: $0.02/GB/month (first 1GB free)
└─ Streaming inserts: $1.25 per 100M rows

Example (1M daily events):
├─ 1M events × 365 days = 365M events/year
├─ ~36GB stored = $0.72/month
├─ ~100 queries/month × 10GB avg = $6.25
└─ Estimated: $50-200/month
```

## Monitoring & Observability

### Key Metrics
```
Cloud Run:
├─ Request count (by service, region)
├─ Request latency (p50, p95, p99)
├─ Error rate (4xx, 5xx)
├─ Memory usage
└─ CPU usage

Pub/Sub:
├─ Message publish rate
├─ Message delivery latency
├─ Subscription lag
├─ Dead-letter queue size
└─ Oldest unacked message age

Firestore:
├─ Document read count
├─ Document write count
├─ Latency (p99)
├─ Storage size
└─ Replication lag

BigQuery:
├─ Query execution time
├─ Bytes scanned
├─ Bytes billed
├─ Slot utilization
└─ Load job success rate
```

### Alerting
```
Critical:
├─ Cloud Run error rate > 5%
├─ Pub/Sub DLQ size > 100 messages
├─ Firestore latency p99 > 5s
└─ LB unhealthy backends > 0

Warning:
├─ Cloud Run latency p99 > 1s
├─ Pub/Sub subscription lag > 10 minutes
├─ BigQuery queries > 30s
└─ Storage bucket usage > 80% quota
```

## Security Considerations

### Network Security
- VPC isolation with private subnets
- Cloud NAT for outbound traffic
- Firewall rules restrict traffic flow
- Private service connections for GCP services
- No public IPs for Cloud Run (only via LB)

### Data Security
- Encryption at rest (default GCS encryption)
- Encryption in transit (HTTPS/TLS 1.3)
- SSL certificate for LB
- IAM-based access control
- Service account restrictions

### Audit & Compliance
- Cloud Audit Logs all API calls
- Cloud Logging captures all application logs
- Data retention policies enforced
- Firestore point-in-time recovery
- Regular backup exports

---

**Last Updated**: 2024-12-16  
**Architecture Version**: 1.0 (Cloud Run, Multi-region, Event-driven)
