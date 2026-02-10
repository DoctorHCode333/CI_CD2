#!/usr/bin/env python3
"""
List all Genesys Cloud flows in the environment to verify flow names and permissions
"""
import os
import sys

try:
    import PureCloudPlatformClientV2
    from PureCloudPlatformClientV2.rest import ApiException
except ImportError:
    print("ERROR: PureCloudPlatformClientV2 not installed!")
    print("Install with: pip install PureCloudPlatformClientV2")
    sys.exit(1)

def main():
    # Check credentials
    client_id = os.environ.get('GENESYSCLOUD_OAUTHCLIENT_ID')
    client_secret = os.environ.get('GENESYSCLOUD_OAUTHCLIENT_SECRET')
    region = os.environ.get('GENESYSCLOUD_REGION', 'us-west-2')  # Default to DEV environment
    
    if not client_id or not client_secret:
        print("ERROR: Missing credentials!")
        print("Set GENESYSCLOUD_OAUTHCLIENT_ID and GENESYSCLOUD_OAUTHCLIENT_SECRET")
        print("\nFor DEV environment (where HarshTestFlow exists):")
        print("  export GENESYSCLOUD_REGION=us-west-2")
        print("  export GENESYSCLOUD_API_REGION=https://api.usw2.pure.cloud")
        sys.exit(1)
    
    print(f"=== Connecting to Genesys Cloud ({region}) ===\n")
    
    try:
        # Configure SDK
        region_host = getattr(PureCloudPlatformClientV2.PureCloudRegionHosts, region.replace('-', '_'))
        PureCloudPlatformClientV2.configuration.host = region_host.get_api_host()
        
        # Authenticate
        api_client = PureCloudPlatformClientV2.api_client.ApiClient().get_client_credentials_token(
            client_id,
            client_secret
        )
        
        print(f"✓ Authentication successful!\n")
        
        # List flows
        architect_api = PureCloudPlatformClientV2.ArchitectApi(api_client)
        
        print("=== Fetching all flows ===")
        flows = architect_api.get_flows(page_size=100, page_number=1)
        
        print(f"Total flows found: {flows.total}\n")
        
        if flows.total == 0:
            print("WARNING: No flows found! This could indicate a permission issue.")
            print("Ensure your OAuth client has 'architect' and 'architect:readonly' scopes.\n")
            return
        
        # Search for specific patterns
        print("=== Flows containing 'CI_CD', 'Test', 'BFSI', or 'Harsh' ===")
        matching_flows = []
        for flow in flows.entities:
            name_lower = flow.name.lower()
            if any(term in name_lower for term in ['ci_cd', 'test', 'bfsi', 'harsh']):
                matching_flows.append(flow)
                print(f"  ✓ Name: '{flow.name}'")
                print(f"    Type: {flow.type}")
                print(f"    ID: {flow.id}")
                print(f"    Published: {flow.published if hasattr(flow, 'published') else 'N/A'}")
                print()
        
        if not matching_flows:
            print("  No matching flows found.\n")
        
        # Show all flows
        print("=== All Flows in Environment ===")
        for i, flow in enumerate(flows.entities, 1):
            status = "📗 Published" if (hasattr(flow, 'published') and flow.published) else "📕 Draft"
            print(f"{i:3}. {status} | {flow.type:15} | {flow.name}")
        
        # Check for additional pages
        if flows.page_count and flows.page_count > 1:
            print(f"\n(Showing page 1 of {flows.page_count})")
        
        # Verify specific flow
        print("\n=== Verifying Flow: 'HarshTestFlow' ===")
        found = False
        for flow in flows.entities:
            if flow.name == "HarshTestFlow":
                found = True
                print(f"✓ FOUND: '{flow.name}'")
                print(f"  Type: {flow.type}")
                print(f"  ID: {flow.id}")
                published_status = flow.published if hasattr(flow, 'published') else False
                print(f"  Published: {published_status}")
                print(f"\n  → Use in export: genesyscloud_flow::{flow.name}")
                break
        
        if not found:
            print("✗ Flow 'HarshTestFlow' NOT FOUND!")
            print("\nPossible reasons:")
            print("  1. Flow doesn't exist in this environment")
            print("  2. Flow has a different name (check list above)")
            print("  3. OAuth client lacks permission to view this flow")
            print("\nSuggested actions:")
            print("  - Create a flow named 'HarshTestFlow' in Genesys Cloud")
            print("  - Or update export config to use an existing flow name from the list above")
        
    except ApiException as e:
        print(f"\n✗ API ERROR!")
        print(f"Status: {e.status}")
        print(f"Reason: {e.reason}")
        print(f"Body: {e.body}")
        
        if e.status == 401:
            print("\n→ Authentication failed. Check your OAuth credentials.")
        elif e.status == 403:
            print("\n→ Permission denied. Ensure OAuth client has these scopes:")
            print("   - architect")
            print("   - architect:readonly")
        
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ ERROR: {type(e).__name__}")
        print(f"{e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
